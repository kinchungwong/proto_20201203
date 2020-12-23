classdef HashSpecProcessor < handle
    properties
        HashSpec HashSpec {mustBeScalarOrEmpty}
        StackedOutput(1, 1) logical = true
    end
    methods
        function specProc = HashSpecProcessor(hashSpec)
            specProc.HashSpec = hashSpec;
        end
        
        function output = Process(specProc, input)
            hashSpec = specProc.HashSpec;
            stackedOutput = specProc.StackedOutput;
            if isa(input, "uint32")
                output = Internal_Process(hashSpec, input, stackedOutput);
            elseif isa(input, "U32")
                output = U32(Internal_Process(hashSpec, input.Data, stackedOutput));
            end
        end
    end
end

function outputStack = Internal_Process(hashSpec, input, stackedOutput)
    if ~isa(hashSpec, "HashSpec")
        error('hashSpec');
    end
    if ~isa(input, "uint32")
        error('input');
    end
    if ~islogical(stackedOutput) || ~isscalar(stackedOutput)
        error('stackedOutput');
    end
    [nrows, ncols] = size(input);
    stepCount = hashSpec.StepCount;
    outputStack = zeros(nrows, ncols, stepCount, 'uint32');
    for k = 1:stepCount
        step = hashSpec.Steps(k);
        input = HashStepProcessor(step).Process(input);
        outputStack(:, :, k) = input;
    end
    if ~stackedOutput
        warning("HashSpecProcessor.StackedOutput will default to true in a future commit.");
        outputStack = outputStack(:, :, end);
    end
end
