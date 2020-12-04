classdef ImageHashPointCache < handle
    properties (SetAccess = immutable)
        Files FileTable
        Ids int32
        IdToImageHashPoints containers.Map
    end
    properties (GetAccess = private, SetAccess = private)
        IdHasProcessed containers.Map
    end
    properties
        Options AlgorithmOptions {mustBeScalarOrEmpty}
    end
    methods
        function hpcache = ImageHashPointCache(ft)
            hpcache.Files = ft;
            hpcache.IdToImageHashPoints = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            hpcache.Ids = ft.Ids;
            hpcache.IdHasProcessed = Init_IdHasProcessed(ft.Ids);
        end
        
        function Populate(hpcache, ids)
            if ~exist('ids', 'var') || isempty(ids)
                ids = hpcache.Ids;
            elseif ~isa(ids, 'int32')
                ids = int32(ids);
            end
            numIds = length(ids);
            for k = 1:numIds
                id = ids(k);
                if hpcache.IdHasProcessed(id)
                    ids(k) = 0;
                end
            end
            ids = ids(ids ~= 0);
            numIds = length(ids);
            if numIds > 0
                infoCells = GetInfoCellArray(hpcache.Files.IdToInfo, ids);
                imageHashPointCells = ProcessAll(infoCells, hpcache.Options);
                for k = 1:numIds
                    id = ids(k);
                    hpcache.IdToImageHashPoints(id) = imageHashPointCells{1, k};
                    hpcache.IdHasProcessed(id) = true;
                end
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

function idHasProcessed = Init_IdHasProcessed(ids)
    mustBeVector(ids);
    mustBeInteger(ids);
    idHasProcessed = containers.Map('KeyType', 'int32', 'ValueType', 'logical');
    for k = 1:length(ids)
        id = ids(k);
        idHasProcessed(id) = false;
    end
end

function imageHashPointCells = ProcessAll(infoCells, opts)
    if ~iscell(infoCells)
        error('infoCells');
    end
    mustBeA(opts, 'AlgorithmOptions');
    numIds = numel(infoCells);
    for k = 1:numIds
        mustBeA(infoCells{k}, 'ImageFileInfo');
    end
    if opts.UseParallel
        imageHashPointCells = ProcessAll_Parallel(infoCells, opts);
    else
        imageHashPointCells = ProcessAll_Sequential(infoCells, opts);
    end
end

function imageHashPointCells = ProcessAll_Parallel(infoCells, opts)
    numIds = numel(infoCells);
    imageHashPointCells = cell(size(infoCells));
    parfor k = 1:numIds
        tic;
        imageHashPointCells{k} = ProcessOne(infoCells{k}, opts);
        toc
    end
end

function imageHashPointCells = ProcessAll_Sequential(infoCells, opts)
    numIds = numel(infoCells);
    imageHashPointCells = cell(size(infoCells));
    for k = 1:numIds
        imageHashPointCells{k} = ProcessOne(infoCells{k}, opts);
    end
end

function imageHashPoints = ProcessOne(info, opts)
    mustBeA(info, 'ImageFileInfo');
    mustBeA(opts, 'AlgorithmOptions');
    id = info.Id;
    fprintf('[%d] Start\n', id);
    t1 = clock;
    imgProc = ImageHashProcessor(info);
    imgProc.Options = opts;
    imgProc.LoadImage();
    imgProc.ColorToInt();
    imgProc.ComputeHash();
    imgProc.ComputeMask();
    imageHashPoints = ImageHashPoints(imgProc);
    t2 = clock;
    et = etime(t2, t1);
    fprintf('[%d] Finish (%.3f secs)\n', id, et);
end
