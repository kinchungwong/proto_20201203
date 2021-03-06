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
            if isempty(imgProc.Options.HM_Options)
                % Previous code 
                % ... one hash plane; 
                % ... mask logic similar to C# 2020 November project
                hvstring = char(imgProc.Options.HashOptions.HashWindowSpec);
                hashProc = HashSpecProcessor(HashSpec(hvstring));
                hashProc.StackedOutput = imgProc.Options.HashOptions.StackedOutput;
                imgProc.Hashed = hashProc.Process(imgProc.OriginalInt);
            else
                % New code (2021-01-05)
                % ... three hash planes (sQuare, Horz, Vert)
                hashProc = HashMaskProcessor(imgProc.Options.HM_Options);
                hashProc.Process(imgProc);
                imgProc.Hashed = hashProc.Hashed;
                imgProc.Mask = hashProc.Mask;
            end
        end
        function ComputeMask(imgProc)
            if isempty(imgProc.Options.HM_Options)
                % Previous code 
                frac = imgProc.Options.HashOptions.HashSampleFrac;
                imgProc.Mask = GetPreMask(imgProc.Hashed, frac);
                imgProc.Mask = GetUniqueMask(imgProc.Hashed, imgProc.Mask);
                minWindow = imgProc.Options.HashOptions.HashMinWindow;
                imgProc.Mask = GetMinMask(imgProc.Hashed, imgProc.Mask, minWindow);
            else
                % New code (2021-01-05)
                % ... nothing to do; 
                % ... mask already computed in previous step (ComputeHash)
            end
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
