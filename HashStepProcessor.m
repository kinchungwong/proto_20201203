classdef HashStepProcessor < handle
    properties
        HashStep HashStep {mustBeScalarOrEmpty}
    end
    methods
        function stepProc = HashStepProcessor(hashStep)
            stepProc.HashStep = hashStep;
        end
        
        function output = Process(stepProc, input)
            if isa(input, "uint32")
                output = Internal_Process(stepProc, input);
            elseif isa(input, "U32")
                % Deprecated
                warning("Deprecated usage of U32 in HashStepProcessor.Process(stepProc, input)");
                output = U32(Internal_Process(stepProc, input.Data));
            end
        end
    end
end

function output = Internal_Process(stepProc, input)
    if ~isa(stepProc, "HashStepProcessor")
        error('stepProc');
    end
    if ~isa(input, "uint32")
        error('input');
    end
    stencils = stepProc.HashStep.RowColPoints;
    stencilCount = size(stencils, 1);
    sz = size(input);
    outMargin = stepProc.HashStep.Margin;
    outRowFirst = 1 + outMargin.Top;
    outRowLast = sz(1) - outMargin.Bottom;
    outColFirst = 1 + outMargin.Left;
    outColLast = sz(2) - outMargin.Right;
    outWidth = sz(2) - outMargin.Left - outMargin.Right;
    output = zeros(sz, "uint32");
    for outRow = outRowFirst:outRowLast
        rowData = zeros(1, outWidth, "uint32");
        for kStencil = 1:stencilCount
            rowOffset = stencils(kStencil, 1);
            colOffset = stencils(kStencil, 2);
            inColFirst = outColFirst + colOffset;
            inColLast = outColLast + colOffset;
            inputRowData = input(outRow + rowOffset, inColFirst:inColLast);
            rowData = Ingest(rowData, inputRowData);
        end
        output(outRow, outColFirst:outColLast) = rowData;
    end
end
