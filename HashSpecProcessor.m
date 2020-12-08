classdef HashSpecProcessor < handle
    properties
        HashSpec HashSpec {mustBeScalarOrEmpty}
    end
    methods
        function specProc = HashSpecProcessor(hashSpec)
            specProc.HashSpec = hashSpec;
        end
        function output = Process(specProc, input)
            if ~isa(input, "U32")
                error('input');
            end
            spec = specProc.HashSpec;
            output = input;
            for k = 1:spec.StepCount
                step = spec.Steps(k);
                output = HashStepProcessor(step).Process(output);
            end
        end
    end
end
