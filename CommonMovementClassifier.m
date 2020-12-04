classdef CommonMovementClassifier < handle
    properties (SetAccess = immutable)
        Ids int32
        Data containers.Map
    end
    properties
        Options AlgorithmOptions {mustBeScalarOrEmpty}
        Features uint32
        Coords int32
        Deltas int32
        UniqueDeltas int32
        Labels int32
        Votes int32
        VoteFlags logical
    end
    methods
        function cmc = CommonMovementClassifier(hpcache, ids)
            if ~isa(hpcache, 'ImageHashPointCache')
                error('hpcache');
            end
            if ~exist('ids', 'var') || isempty(ids)
                ids = hpcache.Files.Ids;
            end
            cmc.Ids = ids;
            cmc.Data = containers.Map('KeyType', 'int32', 'ValueType', 'any');
            numIds = length(ids);
            for k = 1:numIds
                id = ids(k);
                cmc.Data(id) = hpcache.Data(id);
            end
        end
        function SelectFeatures(cmc)
            cmc.Features = FindIntersectFeatures(cmc.Ids, cmc.Data);
        end
        function ExtractCoords(cmc)
            cmc.Coords = Internal_ExtractPoints(cmc.Ids, cmc.Data, cmc.Features);
        end
        function ComputeDeltas(cmc)
            coords = cmc.Coords;
            cmc.Deltas = coords(:, 3:end) - coords(:, 1:end-2);
        end
        function ComputeUniqueDeltas(cmc)
            cmc.UniqueDeltas = unique(cmc.Deltas, 'rows');
        end
        function ComputeLabelsAndVotes(cmc)
            numUnique = size(cmc.UniqueDeltas, 1);
            [~, cmc.Labels] = ismember(cmc.Deltas, cmc.UniqueDeltas, 'rows');
            cmc.Labels = cmc.Labels(cmc.Labels >= 1);
            cmc.Votes = accumarray(cmc.Labels, 1, [numUnique, 1]);
            totalVotes = sum(cmc.Votes);
            countThr = cmc.Options.CommonMovementClassifier_VoteCountThreshold;
            fracThr = cmc.Options.CommonMovementClassifier_VoteFracThreshold;
            cmc.VoteFlags = false(numUnique, 4);
            cmc.VoteFlags(:, 1) = logical(cmc.Votes >= countThr);
            cmc.VoteFlags(:, 2) = logical(cmc.Votes >= (double(totalVotes) * fracThr));
            cmc.VoteFlags(:, 3) = Internal_AnyZeroesInDelta(cmc.UniqueDeltas);
            cmc.VoteFlags(:, 4) = Internal_AllZeroesInDelta(cmc.UniqueDeltas);
        end
    end
end

function feats = FindUnionFeatures(ids, data)
% Returns a feature array containing all features that have occurred at
% least once in any of the input images.
%
% Currently, a feature row is defined as [ hashValue, hashColor ].
%
    n = numel(ids);
    numUnfilt = 0;
    for k = 1:n
        item = data(ids(k));
        numUnfilt = numUnfilt + length(item.HashValues);
    end
    feats = zeros(numUnfilt, 2, 'uint32');
    copyOffset = 0;
    for k = 1:n
        item = data(ids(k));
        numThis = length(item.HashValues);
        feats(copyOffset + (1:numThis), 1) = item.HashValues;
        feats(copyOffset + (1:numThis), 2) = item.HashColors;
        copyOffset = copyOffset + numThis;
    end
    feats = unique(feats, 'rows');
end

function feats = FindIntersectFeatures(ids, data)
% Returns a feature array containing features that are common to all
% images. Each feature must occur in every input image.
%
% Currently, a feature row is defined as [ hashValue, hashColor ].
%
    n = numel(ids);
    for k = 1:n
        item = data(ids(k));
        itemFeats = cat(2, item.HashValues, item.HashColors);
        if ~exist('feats', 'var')
            feats = itemFeats;
        else
            feats = intersect(feats, itemFeats, 'rows');
        end
    end
end

function pts = Internal_ExtractPoints(ids, data, feats)
    n = numel(ids);
    nf = size(feats, 1);
    pts = zeros(nf, n * 2, 'int32');
    for k = 1:n
        item = data(ids(k));
        itemFeats = cat(2, item.HashValues, item.HashColors);
        [~, sampleIdx] = ismember(feats, itemFeats, 'rows');
        ptsColSelect = ((k - 1) * 2) + (1:2);
        pts(:, ptsColSelect) = cat(2, item.HashRows(sampleIdx), item.HashCols(sampleIdx));
    end    
end

function flags = Internal_AnyZeroesInDelta(deltas)
    if ~ismatrix(deltas)
        error('deltas');
    end
    [nrows, ncols] = size(deltas);
    flags = false(nrows, 1);
    for k = 1:2:ncols-1
        curIsZero = (deltas(:, k) == 0) & (deltas(:, k + 1) == 0);
        flags = flags | curIsZero;
    end
end

function flags = Internal_AllZeroesInDelta(deltas)
    if ~ismatrix(deltas)
        error('deltas');
    end
    [nrows, ncols] = size(deltas);
    flags = true(nrows, 1);
    for k = 1:2:ncols-1
        curIsZero = (deltas(:, k) == 0) & (deltas(:, k + 1) == 0);
        flags = flags & curIsZero;
    end
end
