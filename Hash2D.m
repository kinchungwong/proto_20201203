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

