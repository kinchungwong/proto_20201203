classdef ImageHashPointCache < handle
    properties (SetAccess = immutable)
        Files FileTable
        Data containers.Map
    end
    properties
        Options AlgorithmOptions {mustBeScalarOrEmpty}
    end
    methods
        function hpcache = ImageHashPointCache(ft)
            hpcache.Files = ft;
            hpcache.Data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
        end
        
        function Populate(hpcache, ids)
            if ~exist('ids', 'var') || isempty(ids)
                ids = hpcache.Files.Ids;
            end
            numIds = length(ids);
            infos = GetInfoCellArray(hpcache.Files.IdToInfo, ids);
            data = cell(1, numIds);
            opts = hpcache.Options;
            parfor k = 1:numIds
                tic;
                imgProc = ImageHashProcessor(infos{1, k});
                imgProc.Options = opts;
                imgProc.LoadImage();
                imgProc.ColorToInt();
                imgProc.ComputeHash();
                imgProc.ComputeMask();
                data{1, k} = ImageHashPoints(imgProc);
                toc
            end
            for k = 1:numIds
                hpcache.Data(ids(k)) = data{1, k};
            end
        end
    end
end

function infos = GetInfoCellArray(idToInfoMap, ids)
    if ~isa(idToInfoMap, 'containers.Map')
        error('idToInfo');
    end
    numIds = length(ids);
    infos = cell(1, numIds);
    for k = 1:numIds
        id = ids(k);
        infos{1, k} = idToInfoMap(id);
    end
end
