classdef CommonMovementCache < handle
    % A cache for CMC (Common Movement Classifier) with a list of IDs as key.
    properties (SetAccess = immutable)
        Data containers.Map {mustBeScalarOrEmpty}
    end
    methods
        function cache = CommonMovementCache()
            cache.Data = containers.Map('KeyType', 'char', 'ValueType', 'any');
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
