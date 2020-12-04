classdef AlgorithmOptions < handle
    properties
        UseParallel logical {mustBeScalarOrEmpty} = true
        HashWindowSpec string = "hhhhvvv"
        HashMinWindow {mustBeNumeric} = [19 55]
        HashSampleFrac {mustBeScalarOrEmpty, mustBeNumeric, mustBeInRange(HashSampleFrac, 0, 1)} = 0.1
        CommonMovementClassifier_VoteCountThreshold {mustBeScalarOrEmpty, mustBeInteger} = 2
        CommonMovementClassifier_VoteFracThreshold {mustBeScalarOrEmpty, mustBeNumeric, mustBeInRange(CommonMovementClassifier_VoteFracThreshold, 0, 1)} = 0.1
    end
    methods
        function opts = AlgorithmOptions()
        end
    end
end
