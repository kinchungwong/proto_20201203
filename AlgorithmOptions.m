classdef AlgorithmOptions < handle
    properties
        HashWindowSpec string = "hhhhvvv"
        HashMinWindow {mustBeNumeric} = [32 32]
        HashSampleFrac {mustBeScalarOrEmpty, mustBeNumeric, mustBeInRange(HashSampleFrac, 0, 1)} = 0.1
        CommonMovementClassifier_VoteCountThreshold {mustBeScalarOrEmpty, mustBeInteger} = 2
        CommonMovementClassifier_VoteFracThreshold {mustBeScalarOrEmpty, mustBeNumeric, mustBeInRange(CommonMovementClassifier_VoteFracThreshold, 0, 1)} = 0.1
    end
    methods
        function opts = AlgorithmOptions()
        end
    end
end
