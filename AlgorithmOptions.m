classdef AlgorithmOptions < handle
    properties
        UseParallel logical {mustBeScalarOrEmpty} = true
        HashWindowSpec string {mustBeTextScalar} = "hvhvhvh"
        HashMinWindow {mustBeNumeric} = [19 55]
        HashSampleFrac {mustBeScalarOrEmpty, mustBeNumeric, mustBeInRange(HashSampleFrac, 0, 1)} = 0.1
        CMC_Options CommonMovementClassifierOptions {mustBeScalarOrEmpty}
    end
    methods
        function opts = AlgorithmOptions()
            opts.CMC_Options = CommonMovementClassifierOptions();
        end
    end
end
