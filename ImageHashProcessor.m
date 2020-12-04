classdef ImageHashProcessor < handle
    properties
        ImageInfo ImageFileInfo {mustBeScalarOrEmpty}
        Options AlgorithmOptions {mustBeScalarOrEmpty}
        OriginalColor uint8
        OriginalInt uint32
        Hashed uint32
        Mask logical
    end
    methods
        function imgProc = ImageHashProcessor(info)
            imgProc.ImageInfo = info;
        end
        function LoadImage(imgProc)
            imgProc.OriginalColor = imread(imgProc.ImageInfo.FilePath);
        end
        function ColorToInt(imgProc)
            imgProc.OriginalInt = ConvertColorToInt32(imgProc.OriginalColor);
        end
        function ComputeHash(imgProc)
            hvstring = char(imgProc.Options.HashWindowSpec);
            imgProc.Hashed = Hash2D(imgProc.OriginalInt, hvstring);
        end
        function ComputeMask(imgProc)
            frac = imgProc.Options.HashSampleFrac;
            imgProc.Mask = GetPreMask(imgProc.Hashed, frac);
            imgProc.Mask = GetUniqueMask(imgProc.Hashed, imgProc.Mask);
            minWindow = imgProc.Options.HashMinWindow;
            imgProc.Mask = GetMinMask(imgProc.Hashed, imgProc.Mask, minWindow);
        end
    end
end

function output = ConvertColorToInt32(input)
    if ~isa(input, 'uint8')
        error('input');
    end
    if ndims(input) ~= 3
        error('input');
    end
    if size(input, 3) ~= 3
        error('input');
    end
    output = ...
        uint32(input(:, :, 1)) * uint32(65536) + ...
        uint32(input(:, :, 2)) * uint32(256) + ...
        uint32(input(:, :, 3));
end

function output = Hash2D(input, hvstring)

    if ~isa(input, 'uint32')
        error('input');
    end
    if ~ismatrix(input)
        error('input');
    end
    nextH = 1;
    nextV = 1;
    marginH = 0;
    marginV = 0;
    output = input;
    for c = hvstring
        if c == 'h'
            offsets = zeros(3, 2);
            offsets(1, 2) = -nextH;
            offsets(3, 2) = nextH;
            marginH = marginH + nextH;
            margins = [marginV, marginV, marginH, marginH];
            output = HashCodeBuilder(output, offsets, margins);
            nextH = nextH * 3;
        elseif c == 'v'
            offsets = zeros(3, 2);
            offsets(1, 1) = -nextV;
            offsets(3, 1) = nextV;
            marginV = marginV + nextV;
            margins = [marginV, marginV, marginH, marginH];
            output = HashCodeBuilder(output, offsets, margins);
            nextV = nextV * 3;
        end
    end
end

function output = HashCodeBuilder(input, offsets, margins)
% Computes the output of the HashCodeBuilder 
% Refer to HashCodeBuilder.cs for details
%
%     output = HCB(input, offsets, margins)
% 
% Offsets should be an M-by-2 matrix
% Each row in offsets should contain two elements, (rowOffset, colOffset)
%
% Margins should be an 1-by-4 vector
% Margin should contain (padAbove, padBelow, padLeft, padRight)

    if ~ismatrix(offsets) || size(offsets, 2) ~= 2
        error('offsets');
    end
    if ~isvector(margins) || numel(margins) ~= 4
        error('margins');
    end
    
    if true
        output = HashCodeBuilder_memoryopt(input, offsets, margins);
    else
        output = HashCodeBuilder_legacy(input, offsets, margins);
    end
end

function output = HashCodeBuilder_legacy(input, offsets, margins)
% Original implementation, written for clarity. Operates on whole
% cropped array at once.
    [nrows, ncols] = size(input);
    padAbove = margins(1);
    padBelow = margins(2);
    padLeft = margins(3);
    padRight = margins(4);
    sliceRows = (1 + padAbove) : (nrows - padBelow);
    sliceCols = (1 + padLeft) : (ncols - padRight);

    output = zeros([nrows, ncols], 'uint32');
    for ko = 1:size(offsets, 1)
        rowOffset = offsets(ko, 1);
        colOffset = offsets(ko, 2);
        inputSlice = input(sliceRows + rowOffset, sliceCols + colOffset);
        outputSlice = output(sliceRows, sliceCols);
        outputSlice = Ingest(outputSlice, inputSlice);
        output(sliceRows, sliceCols) = outputSlice;
    end
end

function output = HashCodeBuilder_memoryopt(input, offsets, margins)
% Memory-efficient implementation. Improves cache utilization, which
% in turn greatly improves performance running on MATLAB local cluster.
    [nrows, ncols] = size(input);
    padAbove = margins(1);
    padBelow = margins(2);
    padLeft = margins(3);
    padRight = margins(4);
    sliceRows = (1 + padAbove) : (nrows - padBelow);
    sliceCols = (1 + padLeft) : (ncols - padRight);
    sliceWidth = length(sliceCols);
    numOffsets = size(offsets, 1);
    output = zeros(nrows, ncols, 'uint32');
    
    for row = sliceRows
        rowData = zeros(1, sliceWidth, 'uint32');
        for ko = 1:numOffsets
            rowOffset = offsets(ko, 1);
            colOffset = offsets(ko, 2);
            inputData = input(row + rowOffset, sliceCols + colOffset);
            rowData = Ingest(rowData, inputData);
        end
        output(row, sliceCols) = rowData;
    end
end

function output = Ingest(output, input)
% Transforms the output by "ingesting" a single step of input.
% Ingestion consists of applying a transformation function on each 
% input element, followed by applying a mixing function taking each
% output element and corresponding input element and producing a 
% new output element that replaces the old one.

    if ~isa(input, 'uint32')
        error('input');
    end
    if ~isa(output, 'uint32')
        error('output');
    end
    if ndims(input) ~= ndims(output)
        error('ndims');
    end
    if any(size(input) ~= size(output))
        error('size');
    end
    c1 = 0xcc9e2d51u32;
    c2 = 0x1b873593u32;
    c3 = 0xe6546b64u32;
    % TransformData
    input = MulConst32(input, c1);
    input = Rotate32(input, 15);
    input = MulConst32(input, c2);
    % UpdateState
    output = bitxor(output, input);
    output = Rotate32(output, 13);
    output = MulConst32(output, 5);
    output = AddConst32(output, c3);
end

function output = MulConst32(output, value)
% Given an array of unsigned 32-bit integers and a scalar, computes 
% their multiplicative product, and retain the lower 32-bit portion
% of the result.
%
%     output = MulConst32(output, value)
% 

    if ~isa(output, 'uint32')
        error('output');
    end
    if ~isscalar(value) || ~isnumeric(value) || ~isreal(value)
        error('input');
    end
    
    output = uint32(bitand(uint64(output) * uint64(value), 0xffffffffu64));
end

function output = AddConst32(output, value)
% Given an array of unsigned 32-bit integers and a scalar, computes 
% their additive sum, and retain the lower 32-bit portion of the 
% result.
%
%     output = AddConst32(output, value)
% 

    if ~isa(output, 'uint32')
        error('output');
    end
    if ~isscalar(value) || ~isnumeric(value) || ~isreal(value)
        error('input');
    end
    
    output = uint32(bitand(uint64(output) + uint64(value), 0xffffffffu64));
end

function output = Rotate32(output, amount)
% Rotate the 32-bit integers by the amount
%
%     output = Rotate32(output, amount)
% 

    if ~isa(output, 'uint32')
        error('output');
    end
    if ~isscalar(amount) || ~isnumeric(amount) || ~isreal(amount)
        error('amount');
    end
    if amount ~= round(amount)
        error('amount');
    end
    
    amount = bitand(uint32(amount), uint32(31));
    if amount ~= 0
        output = bitor(bitshift(output, amount), bitshift(output, amount - 32));
    end
end

function mask = GetPreMask(input, frac)
% Create a mask that selects uint32 values using a simple comparison.
% mask = GetPreMask(input, frac)
%
    if ~isa(input, 'uint32')
        error('input');
    end
    if ~isnumeric(frac) || ~isreal(frac) || ~isscalar(frac)
        error('frac');
    end
    if (frac < 0) || (frac > 1)
        error('frac');
    end
    mask = logical(input < uint32(frac * double(intmax('uint32'))));
end

function mask = GetUniqueMask(input, preMask)
% Create a mask that indicates input elements containing unique uint32 values
% mask = GetUniqueMask(input, preMask)
% 
% preMask is a mask indicating which elements in the input matrix should be 
% processed. This argument is optional.

    if ~isa(input, 'uint32')
        error('input');
    end
    if ~ismatrix(input)
        error('input');
    end
    if ~exist('preMask', 'var')
        preMask = logical([]);
    elseif ~isempty(preMask)
        if any(size(preMask) ~= size(input))
            error('preMask');
        end
        if ~islogical(preMask)
            preMask = logical(preMask);
        end
    end
    
    if isempty(preMask)
        samples = sort(input(:));
    else
        samples = sort(input(preMask));
    end
    dups = samples(1:end-1) == samples(2:end);
    dupsMask = [dups; false] | [false; dups];
    samples = samples(~dupsMask);
    mask = ismember(input, samples);
end

function mask = GetMinMask(input, preMask, minWindow)
% Create a mask that identifies elements in the input matrix that are
% locally minimal-valued.
%
    if ~isa(input, 'uint32')
        error('input');
    end
    if ~ismatrix(input)
        error('input');
    end
    if any(size(input) ~= size(preMask))
        error('preMask');
    end
    if ~islogical(preMask)
        preMask = logical(preMask);
    end
    if ~isnumeric(minWindow) || numel(minWindow) ~= 2 || any(minWindow < 1)
        error('minWindow');
    end
    input(~preMask) = 0xFFFFFFFFu32;
    se = strel('rectangle', minWindow);
    eroded = imerode(input, se);
    mask = logical(input == eroded);
    mask(~preMask) = false;
end
