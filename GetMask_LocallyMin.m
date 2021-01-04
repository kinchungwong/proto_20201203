function output = GetMask_LocallyMin(input, minWindow, mask, excludedValues)
% Create a mask that identifies elements in the input matrix that are
% locally minimal-valued.
%
    arguments
        input(:, :) uint32
        minWindow(1, 2) {mustBeInteger, mustBePositive} = [3, 3]
        mask(:, :) logical = []
        excludedValues(1, :) uint32 = []
    end
    
    % Validate the mask size. It may be empty or may match the input size.
    % Other sizes are invalid.
    sz = size(input);
    hasMask = isequal(size(mask), sz);
    noMask = isempty(mask);
    if ~hasMask && ~noMask
        error('mask');
    end
    
    % If excludedValues is specified, bake this into the specified mask.
    hasExcludedValues = ~isempty(excludedValues);
    if hasExcludedValues
        mask2 = ismember(input, excludedValues);
        if ~hasMask
            hasMask = true;
            mask = mask2;
        else
            mask = logical(mask | mask2);
        end
    end
    
    % When elements are replaced with this value, they do not participate
    % in determining the outcome of the local min (erosion) filter.
    if hasMask
        input(~mask) = intmax("uint32");
    end
    
    % Perform local min (erosion) filter.
    minWindow = double(minWindow); % Known Limitation of "strel"
    se = strel('rectangle', minWindow);
    eroded = imerode(input, se);
    
    % After erosion, the output may contain large areas filled with
    % intmax values. Remove those from the output.
    output = logical(input == eroded);
    if hasMask
        output(~mask) = false;
    end
end
