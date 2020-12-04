classdef CommonMovementClassifierOptions
    properties
        VoteCountThreshold {mustBeScalarOrEmpty, mustBeInteger} = 2
        VoteFracThreshold {mustBeScalarOrEmpty, mustBeNumeric, mustBeInRange(VoteFracThreshold, 0, 1)} = 0.1
    end
    methods
        function cmco = CommonMovementClassifierOptions()
        end
    end
end
