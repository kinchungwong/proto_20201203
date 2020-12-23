classdef AdaptiveMovementClassifier < handle
    properties (SetAccess = immutable)
        ImageHashPointCache ImageHashPointCache {mustBeScalarOrEmpty}
        Options AlgorithmOptions {mustBeScalarOrEmpty}
    end
    properties (SetAccess = private)
        Ids(1, :) int32
        WhichPass(1, 1) int32 = 0
        HasFinished(1, 1) logical = false
        Cache CommonMovementCache {mustBeScalarOrEmpty}
    end
    properties (GetAccess = private, SetAccess = private)
        idsel IdSelector {mustBeScalarOrEmpty}
    end
    properties
        MinCount(1, 1) int32 {mustBePositive} = 2
        MaxCount(1, 1) int32 {mustBePositive} = 5
        Logging(1, 1) logical = true
    end
    methods
        function amc = AdaptiveMovementClassifier(hpcache, opts)
            if ~isa(hpcache, "ImageHashPointCache")
                error('Expects ImageHashPointCache');
            end
            amc.ImageHashPointCache = hpcache;
            amc.Options = opts;
            amc.Ids = hpcache.Ids;
            amc.Cache = CommonMovementCache();
        end
        function [cmcIds, deltas, votes] = ProcessStep(amc)
            cmcIds = [];
            deltas = [];
            votes = [];
            while isempty(cmcIds)
                if isempty(amc.idsel)
                    if amc.WhichPass == 2 % no more pass
                        amc.HasFinished = true;
                        return;
                    end
                    amc.idsel = IdSelector(amc.Ids);
                    amc.idsel.MinCount = amc.MinCount;
                    amc.idsel.MaxCount = amc.MaxCount;
                    amc.WhichPass = amc.WhichPass + 1;
                end
                cmcIds = amc.idsel.Select();
                if isempty(cmcIds)
                    amc.idsel = IdSelector.empty();
                end
            end
            if amc.Logging
                arrStrThroughPass = ["First Pass", "Second Pass"];
                strThroughPass = arrStrThroughPass(amc.WhichPass);
                strCmcIds = num2str(cmcIds, " %d");
                fprintf("==========\n");
                fprintf("%s, Processing [%s]\n", strThroughPass, strCmcIds);
                fprintf("----------\n");
            end
            cmc = amc.Cache.Get(cmcIds);
            if isempty(cmc)
                cmc = CommonMovementClassifier(amc.ImageHashPointCache, cmcIds);
            end
            cmc.Options = amc.Options;
            cmc.SelectFeatures();
            cmc.ExtractCoords();
            cmc.ComputeDeltas();
            cmc.ComputeUniqueDeltas();
            cmc.ComputeLabelsAndVotes();
            cmc.SortLabelsByVotes();
            cmc.ComputeFlags();
            amc.Cache.Add(cmc);
            deltas = cmc.UniqueDeltas;
            votes = cmc.Votes;
            numMoves = size(deltas, 1);
            if numMoves == 0
                idToRemove = min(cmcIds);
                amc.idsel.Remove(idToRemove);
                amc.Ids = setdiff(amc.Ids, idToRemove, 'stable');
                if amc.Logging
                    fprintf("Removing %d due to abrupt content change.\n", idToRemove);
                    fprintf("----------\n");
                end
                % Nothing to print; early return from ProcessStep().
                return;
            end
            if amc.Logging
                for kMove = 1:numMoves
                    curDelta = deltas(kMove, :);
                    curVote = votes(kMove);
                    fprintf("Deltas: %s  (Votes: %d)\n", sprintf("%5d", curDelta), curVote);
                end
                fprintf("----------\n");
            end
            if numel(cmcIds) == 2 && numMoves == 1 && nnz(deltas) == 0
                idToRemove = max(cmcIds);
                amc.idsel.Remove(idToRemove);
                amc.Ids = setdiff(amc.Ids, idToRemove, 'stable');
                if amc.Logging
                    fprintf("Removing %d due to zero movement.\n", idToRemove);
                    fprintf("----------\n");
                end
            end
        end
    end
end
