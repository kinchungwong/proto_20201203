classdef CommonMovementCache < handle
    % A cache for CMC (Common Movement Classifier) with a list of IDs as key.
    
    properties (SetAccess = immutable)
        Ids(1, :) int32
        Data containers.Map {mustBeScalarOrEmpty}
    end
    
    properties (Dependent)
        % A logical matrix indicating the presence of image IDs in a
        % particular record. 
        %
        % Each column corresponds to one image ID. The column index
        % is determined with find(Ids == id).
        % 
        % Each row corresponds to one CommonMovementClassifier.
        % 
        PresenceMask
        
        % A column cell vector, each cell containing the image IDs 
        % consumed in a particular run of CommonMovementClassifier.
        Keys
    end
    
    properties (Access = private)
        InternalMask(:, :) logical = []
        InternalKeys
        InternalRowCount(1, 1) int32 = 0
    end
    
    methods
        function cache = CommonMovementCache(ids)
            arguments
                ids(1, :) int32
            end
            cache.Data = containers.Map('KeyType', 'char', 'ValueType', 'any');
            cache.Ids = ids;
            cache.InternalMask = false(100, length(ids));
            cache.InternalKeys = cell(100, 1);
        end
        
        function Add(cache, cmc)
            % Inserts the CommonMovementClassifier instance to the cache.
            if ~isa(cmc, "CommonMovementClassifier")
                error('cmc');
            end
            ids = cmc.Ids;
            ks = stc_IntVecAsKey(ids);
            if ~cache.Data.isKey(ks)
                cache.Data(ks) = cmc;
                InsertPresenceMaskRow(cache, ids);
            else
                strCmcIds = num2str(ids, " %d");
                sprintf("CommonMovementCache already contains [%s], not inserted.\n", strCmcIds);
            end
        end
        
        function cmc = Get(cache, ids)
            % Retrieves the CommonMovementClassifier with the specified IDs as key.
            % If the key does not exist, an empty result is returned.
            ks = stc_IntVecAsKey(ids);
            if cache.Data.isKey(ks)
                cmc = cache.Data(ks);
            else
                cmc = CommonMovementClassifier.empty();
            end
        end
        
        function mask = get.PresenceMask(cache)
            mask = cache.InternalMask(1:cache.InternalRowCount, :);
        end

        function keys = get.Keys(cache)
            keys = cache.InternalKeys(1:cache.InternalRowCount, :);
        end
        
        function c = cell(cache)
            allKeys = cache.Data.keys;
            keyCount = numel(allKeys);
            c = cell(keyCount, 3);
            for k = 1:keyCount
                ks = allKeys{k};
                c{k, 1} = stc_ParseIntVecKey(ks);
                c{k, 2} = ks;
                c{k, 3} = cache.Data(ks);
            end
        end
        
        function t = table(cache)
            vn = [ "Ids", "Key", "Data" ];
            t = cell2table(cell(cache), 'VariableNames', vn);
        end
    end
    
    methods (Static)
        function ks = IntVecAsKey(intVec)
            ks = stc_IntVecAsKey(intVec);
        end
        
        function intVec = ParseIntVecKey(ks)
            intVec = stc_ParseIntVecKey(ks);
        end
    end
end

function ks = stc_IntVecAsKey(intVec)
    if isempty(intVec) || ~isnumeric(intVec) || ~isvector(intVec) || ~isequal(intVec, floor(intVec))
        error('intVec');
    end
    fs = @(v)sprintf('%d',v);
    fs2 = @(v)string(fs(v));
    a = arrayfun(fs2, intVec);
    ks = join(a, ",");
end

function intVec = stc_ParseIntVecKey(ks)
    if ~isStringScalar(ks) && ~(ischar(ks) && isvector(ks))
        error('ks');
    end
    kss = split(ks, ',');
    kss = kss(strlength(kss) > 0);
    intVec = str2double(kss);
    intVec = intVec(:)';
    if ~isequal(intVec, floor(intVec))
        error('intVec');
    end
    intVec = int32(intVec);
end

function InsertPresenceMaskRow(cache, newIds)
    arguments
        cache(1, 1) CommonMovementCache
        newIds(1, :) int32
    end
    
    % Compute the logical presence indicator of ids
    allIds = cache.Ids;
    maskRow = logical(ismember(allIds, newIds));
    
    % Assign row ID for the presence indicator matrix
    newRowId = cache.InternalRowCount + 1;
    
    % Double the size of the table until it can fit the new row
    while newRowId > size(cache.InternalMask, 1)
        cache.InternalMask = cat(1, cache.InternalMask, false(size(cache.InternalMask)));
    end
    
    while newRowId > length(cache.InternalKeys)
        cache.InternalKeys = cat(1, cache.InternalKeys, cell(size(cache.InternalKeys)));
    end
    
    % Insert the row into the presence indicator matrix
    cache.InternalMask(newRowId, :) = maskRow;
    cache.InternalKeys{newRowId} = newIds;
    cache.InternalRowCount = newRowId;
end
