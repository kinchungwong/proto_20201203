function output = GetMask_Unique(input, mask, excludedValues)
% Create a mask that indicates input elements containing unique uint32 values
% output = GetUniqueMask(input, mask)
% 
% mask indicates which elements in the input matrix should be processed. 
% This argument is optional.
    arguments
        input(:, :) uint32 {mustBeReal}
        mask(:, :) logical = []
        excludedValues(1, :) uint32 = []
    end

    sz = size(input);
    hasMask = isequal(size(mask), sz);
    noMask = isempty(mask);
    if ~hasMask && ~noMask
        error('mask');
    end
    
    %%
    if hasMask
        samples = input(mask);
    else
        samples = input(:);
    end
   
    %%
    if isempty(samples)
        output = false(sz);
    elseif isscalar(samples)
        if ~isempty(excludedValues) && ismember(samples(1), excludedValues)
            output = false(sz);
        else
            output = logical(input == samples(1));
        end
    else
        samples = sort(samples);
        dups = samples(1:end-1) == samples(2:end);
        dupsMask = [dups; false] | [false; dups];
        samples = samples(~dupsMask);
        if ~isempty(excludedValues)
            samples = setdiff(samples, excludedValues);
        end
        output = ismember(input, samples);    
    end
end
