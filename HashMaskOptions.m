classdef HashMaskOptions < handle
    properties (SetAccess = immutable)
        SpecQ string {mustBeScalarOrEmpty}
        SpecH string {mustBeScalarOrEmpty}
        SpecV string {mustBeScalarOrEmpty}
    end
    properties (Dependent)
    end
    properties (Access = private)
    end
    methods
        function hmopts = HashMaskOptions(specQ, specH, specV)
            arguments
                % specQ: a square-shaped hash window
                specQ(1, 1) string = "HVHV"
                % specH: a horizontal hash window
                specH(1, 1) string = strcat(specQ, "H")
                % specV: a vertical hash window
                specV(1, 1) string = strcat(specQ, "V")
            end
            hmopts.SpecQ = specQ;
            hmopts.SpecH = specH;
            hmopts.SpecV = specV;
        end
    end
end
