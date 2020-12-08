classdef HashSpec
    properties (SetAccess = immutable)
        % A string that encodes a combination of stencils for hash computation.
        HashString string {mustBeScalarOrEmpty}
        % Number of steps
        StepCount int32
        % The individual HashChar (stencil code) at each step
        HashChar HashChar {mustBeVector(HashChar, "allow-all-empties")}
        % The derived execution parameters at each step. 
        % The actual stencil coordinates and margins at each step 
        % are adjusted based on all previous stencils.
        Steps HashStep
        % The effective input window from combining all stencils
        RowColSize int32
        % The effective input radius from combining all stencils
        RowColRadius int32
    end
    methods
        function spec = HashSpec(hashString)
            if isstring(hashString)
                ss = hashString;
                cc = char(hashString);
            elseif ischar(hashString) && isrow(hashString)
                cc = hashString;
                ss = string(hashString);
            else
                error('hashString');
            end
            len = length(cc);
            spec.HashString = ss;
            spec.StepCount = len;
            for kStep = 1:len
                stepChar = HashChar.FromChar(cc(kStep));
                spec.HashChar(1, kStep) = stepChar;
                if kStep == 1
                    spec.Steps(1, 1) = HashStep(stepChar);
                else
                    prevStep = spec.Steps(1, kStep - 1);
                    spec.Steps(1, kStep) = HashStep(stepChar, prevStep);
                end
            end
            spec.RowColSize = spec.Steps(1, end).RowColSize;
            spec.RowColRadius = spec.Steps(1, end).RowColRadius;
        end
    end
end
