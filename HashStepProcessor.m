classdef HashStepProcessor < handle
    properties
        HashStep HashStep {mustBeScalarOrEmpty}
    end
    methods
        function stepProc = HashStepProcessor(hashStep)
            stepProc.HashStep = hashStep;
        end
        function output = Process(stepProc, input)
            if ~isa(input, "U32")
                error('input');
            end
            pts = stepProc.HashStep.RowColPoints;
            numPts = size(pts, 1);
            sz = size(input.Data);
            outMargin = stepProc.HashStep.Margin;
            outRowFirst = 1 + outMargin.Top;
            outRowLast = sz(1) - outMargin.Bottom;
            outColFirst = 1 + outMargin.Left;
            outColLast = sz(2) - outMargin.Right;
            output = U32(0, sz);
            for outRow = outRowFirst:outRowLast
                h = U32Hash;
                for kp = 1:numPts
                    rowOffset = pts(kp, 1);
                    colOffset = pts(kp, 2);
                    inColFirst = outColFirst + colOffset;
                    inColLast = outColLast + colOffset;
                    h.Ingest(U32(input.Data(outRow + rowOffset, inColFirst:inColLast)));
                end
                output.Data(outRow, outColFirst:outColLast) = h.Data.Data;
            end
        end
    end
end
