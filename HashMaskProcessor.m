classdef HashMaskProcessor < handle
    properties (SetAccess = immutable)
        HM_Options HashMaskOptions {mustBeScalarOrEmpty}
    end
    properties (SetAccess = private)
        HashedQ(:, :) uint32 = []
        HashedH(:, :) uint32 = []
        HashedV(:, :) uint32 = []
        Hashed(:, :) uint32 = []
        Mask(:, :) logical = []
    end
    properties (Dependent)
    end
    properties (Access = private)
        % Internal_HashedQ(:, :) uint32 = []
        % Internal_HashedH(:, :) uint32 = []
        % Internal_HashedV(:, :) uint32 = []
    end
    methods
        function hmp = HashMaskProcessor(hmopts)
            arguments
                hmopts(1, 1) HashMaskOptions = HashMaskOptions()
            end
            hmp.HM_Options = hmopts;
        end
        
        function Process(hmp, ihp)
            arguments
                hmp(1, 1) HashMaskProcessor
                ihp(1, 1) ImageHashProcessor
            end
            Internal_ComputeHash_All(hmp, ihp.OriginalInt);
            Internal_ComputeComposite(hmp, ihp.OriginalInt);
        end
    end
end

function Internal_ComputeHash_All(hmp, input)
    arguments
        hmp(1, 1) HashMaskProcessor
        input(:, :) uint32
    end
    hmopts = hmp.HM_Options;
    hmp.HashedQ = Internal_ComputeHash_One(input, hmopts.SpecQ);
    hmp.HashedH = Internal_ComputeHash_One(input, hmopts.SpecH);
    hmp.HashedV = Internal_ComputeHash_One(input, hmopts.SpecV);
end

function hashResult = Internal_ComputeHash_One(input, specString)
    arguments
        input(:, :) uint32
        specString(1, 1) string
    end
    hashSpec = HashSpec(specString);
    hashProc = HashSpecProcessor(hashSpec);
    hashProc.StackedOutput = false;
    hashResult = hashProc.Process(input);
end

function Internal_ComputeComposite(hmp, input)
    arguments
        hmp(1, 1) HashMaskProcessor
        input(:, :) uint32
    end
    
    %{
    hmopts = hmp.HM_Options;
    %}
    
    % Identify logical mask of non-plain areas.
    dnQ = logical(GetMask_DissimilarNeighbors(hmp.HashedQ));
    dnH = logical(GetMask_DissimilarNeighbors(hmp.HashedH));
    dnV = logical(GetMask_DissimilarNeighbors(hmp.HashedV));
    
    % Composite logical mask of non-plain areas.
    dn = logical(dnQ & dnH & dnV);
    
    % ---
    % Identify hash values observed in plain areas.
    % By definition, all such hash values are non-unique, 
    % as their occurrence count must be at least two.
    % ---
    %{
    xvQ = unique(input(~dn));
    xvH = unique(input(~dn));
    xvV = unique(input(~dn));
    %}
    
    % A Grid2D is needed for some subsequent steps.
    sz = size(input);
    g = Grid2D(sz, round(prod(sz) / 14400));
    
    % ---
    % Remove hash values from logical mask if duplicates are found 
    % within the same macro grid cell.
    %
    % This step targets duplicates that are non-touching but still within 
    % a certain distance, namely within the length of a grid cell.
    % 
    % In this step, a duplicate at (r1, c1) and (r2, c2) means that,
    % the three hash values, namely HashedQ, HashedH, HashedV 
    % taken at (r1, c1) and (r2, c2), are (... TODO (TBD) ...).
    % ---
    gcuQ = logical(GetMask_Unique_ByGridCell(hmp.HashedQ, g, 2, 2, dn));
    gcuH = logical(GetMask_Unique_ByGridCell(hmp.HashedH, g, 2, 2, dn));
    gcuV = logical(GetMask_Unique_ByGridCell(hmp.HashedV, g, 2, 2, dn));
    gcu = logical(gcuQ & gcuH & gcuV);

    % ---
    % Perform an approximately evenly-spaced sub-selection of hash values
    % on the basis that the value HashedQ at (r, c) is a local minimum 
    % within a certain size of a moving window centered at (r, c).
    % ---
    lm = GetMask_LocallyMin(hmp.HashedQ, [15, 15], dn & gcu);

    % ---
    % Create a composite hash matrix and mask matrix which take everything
    % into account. This composite result is more nuanced than the raw 
    % output from the individual output of HashSpecProcessor.
    %
    % === TODO ===
    % The goal is to create a composite hash that improves the behavior of 
    % segmenting along natural seams (e.g. paragraph dividers).
    % 
    % This goal is still being researched. The following code does not
    % fulfill this goal yet.
    % ---
    hmp.Hashed = bitxor(bitxor(hmp.HashedQ, hmp.HashedH), hmp.HashedV);

    % ---
    % ---
    hmp.Mask = lm & dn & gcu;
end
