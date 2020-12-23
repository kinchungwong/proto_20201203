classdef AlgorithmOptions < handle
    properties
        UseParallel logical {mustBeScalarOrEmpty} = true
        HashOptions HashOptions {mustBeScalarOrEmpty}
        CMC_Options CommonMovementClassifierOptions {mustBeScalarOrEmpty}
    end
    methods
        function opts = AlgorithmOptions()
            opts.HashOptions = HashOptions();
            opts.CMC_Options = CommonMovementClassifierOptions();
        end
    end
end
