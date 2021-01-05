classdef AlgorithmOptions < handle
    properties
        UseParallel logical {mustBeScalarOrEmpty} = true
        HashOptions HashOptions {mustBeScalarOrEmpty}
        HM_Options HashMaskOptions {mustBeScalarOrEmpty}
        CMC_Options CommonMovementClassifierOptions {mustBeScalarOrEmpty}
    end
    methods
        function opts = AlgorithmOptions()
            opts.HashOptions = HashOptions();
            %{
            opts.HM_Options = HashMaskOptions();
            %}
            opts.CMC_Options = CommonMovementClassifierOptions();
        end
    end
end
