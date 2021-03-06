classdef HashOptions < handle
    properties
        HashWindowSpec string {mustBeTextScalar} = "hvhvhvh"
        HashMinWindow {mustBeNumeric} = [19 55]
        HashSampleFrac {mustBeScalarOrEmpty, mustBeNumeric, mustBeInRange(HashSampleFrac, 0, 1)} = 0.1
        StackedOutput(1, 1) logical = false
    end
    methods
        function hashOpts = HashOptions()
        end
    end
end
