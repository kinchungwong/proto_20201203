classdef MovementGraph < handle
% MovementGraph creates a connectivity graph based on movement of image
% content across a set of images. 
%
% The inputs used to compute the MovementGraph comes from 
% CommonMovementCache, which contains instances of CommonMovementClassifier, 
% each of which is in turn computed from small subsets of images having 
% shared image content shifted across the screen.
%
% See also CommonMovementClassifier, CommonMovementCache
%
    properties (SetAccess = immutable)
        % CommonMovementCache
        Cache CommonMovementCache {mustBeScalarOrEmpty}
        
        % Complete list of image IDs
        Ids(:, 1) int32
    end

    properties
        % If allowMultiDeltas is true, there can be multiple edges between a
        % pair of images, each edge representing a different row-column delta.
        % If allowMultiDeltas is false, at most one edge (the highest weight) 
        % will be retained between a pair of images after filtering.
        AllowMultiDeltas(1, 1) logical = true
    end
    
    properties (Access = private)
        % graphEdgeData contains individual records of graph edges and
        % associated data, with each row containing [a, b, dr, dc, w]
        % where 
        % ... (a, b) = the image pair (the a-th and b-th images)
        % ... (dr) = the row movement (delta) between (a) and (b)
        % ... (dc) = the column movement (delta) between (a) and (b)
        % ... (w) = the confidence (weight) of the edge
        %
        % This matrix may contain multiple rows where (a, b) are 
        % identical. When such rows exist, the row that has the highest 
        % weight (w) is the row that will be retained after post-process 
        % filtering.
        % 
        GraphEdgeData(:, 5) int32 = zeros(0, 5, "int32")
        
        % Graph
        G {IsScalarOrEmpty_GraphObj}
        
        % ConnComps
        CC
    end
    
    properties (Dependent)
        % Upper adjacency matrix with weights.
        % Adjacency(i, j) is the weight for an edge from the i-th image 
        % to the j-th image.
        Adjacency
        
        % Edges between nodes with positive weights. 
        % Edges is an N-by-2 matrix, each row containing (i, j)
        % representing an edge connecting the i-th and j-th images.
        Edges
        
        % The weights for each edge in Edges.
        % Weights is an N-by-1 vector.
        %
        % The weight values are computed using a formula that considers
        % both the raw votes in CommonMovementClassifier, the number of
        % images used as input in that CommonMovementClassifier, among
        % other factors.
        Weights
        
        % The movement vectors between a pair of images represented 
        % by each edge in Edges.
        % Deltas is an N-by-2 matrix, each row containing 
        % (rowDelta, colDelta) for the same row in Edges.
        Deltas
        
        % A MATLAB Graph object of connections between pairs of images.
        Graph
        
        % A cell vector containing each set of connected components found
        % in the graph.
        ConnComps
    end
    
    methods
        function mg = MovementGraph(cache)
            % Constructor. 
            % Usage: mg = MovementGraph(cache)
            % Input: 
            % ... cache CommonMovementCache
            %
            arguments
                cache(1, 1) CommonMovementCache
            end
            mg.Cache = cache;
            mg.Ids = cache.Ids;
        end
        
        function Process(mg)
            % Computes the graph by processing all CommonMovementClassifier 
            % instances found in the cache.
            arguments
                mg(1, 1) MovementGraph
            end
            mg.GraphEdgeData = Internal_Process(mg);
            [mg.G, mg.CC] = Internal_CreateGraph(mg);
        end
        
        function ab = get.Edges(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            ab = mg.GraphEdgeData(:, 1:2);
        end
        
        function w = get.Weights(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            w = mg.GraphEdgeData(:, 5);
        end
        
        function drdc = get.Deltas(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            drdc = mg.GraphEdgeData(:, 3:4);
        end
        
        function g = get.Graph(mg)
            % Converts the result into a graph.
            % See also: graph
            arguments
                mg(1, 1) MovementGraph
            end
            g = mg.G;
        end
        
        function mab = get.Adjacency(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            mab = mg.G.adjacency();
        end
        
        function [g, cc] = Subgraph(mg, ids, ids2)
            arguments
                mg(1, 1) MovementGraph
                ids(1, :) int32
                ids2(1, :) int32 = []
            end
            [g, cc] = Internal_CreateSubgraph(mg, ids, ids2);
        end
        
        function Plot(mg)
            % Creates a plot of the connectivity graph.
            arguments
                mg(1, 1) MovementGraph
            end
            g = mg.Graph;
            weights = mg.Weights;
            deltas = mg.Deltas;
            wd = cat(2, deltas, weights);
            strEdgeLabels = string(num2str(wd, "%d "));
            plot(g, "EdgeLabel", strEdgeLabels);
        end
        
        function cc = get.ConnComps(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            cc = mg.CC;
        end
    end
    
    % The following method block is used to hide the methods from the
    % documentation page.
    methods (Hidden)
        function varargout = findobj(g, varargin)
            varargout = findobj@handle(g, varargin);
        end
        function varargout = findprop(g, varargin)
            varargout = findprop@handle(g, varargin);
        end
        function varargout = addlistener(g, varargin)
            varargout = addlistener@handle(g, varargin);
        end
        function varargout = notify(g, varargin)
            varargout = notify@handle(g, varargin);
        end
        function varargout = listener(g, varargin)
            varargout = listener@handle(g, varargin);
        end
        function varargout = delete(g, varargin)
            varargout = delete@handle(g, varargin);
        end
        function varargout = gt(g, varargin)
            varargout = gt@handle(g, varargin);
        end
        function varargout = ge(g, varargin)
            varargout = ge@handle(g, varargin);
        end
        function varargout = lt(g, varargin)
            varargout = lt@handle(g, varargin);
        end
        function varargout = le(g, varargin)
            varargout = le@handle(g, varargin);
        end
        function varargout = eq(g, varargin)
            varargout = eq@handle(g, varargin);
        end
        function varargout = ne(g, varargin)
            varargout = ne@handle(g, varargin);
        end
    end    
end

function edgeData = Internal_Process(mg)
    arguments
        mg(1, 1) MovementGraph
    end
    
    % Incrementally populated GraphEdgeData. 
    % This matrix is preallocated, where edgeCount tracks
    % the number of valid rows of data.
    edgeData = zeros(100, 5, "int32");

    % Current number of valid rows inside (edgeData).
    edgeCount = 0;
   
    % The cache contains instances of CommonMovementClassifier.
    % Each instance is keyed by the set of image IDs used in its
    % computation.
    %
    cacheKeys = mg.Cache.Keys;
    cacheCount = length(cacheKeys);
    for cacheIndex = 1:cacheCount
        thisIds = cacheKeys{cacheIndex};
        thisImageCount = length(thisIds);
        
        % Though impossible, this has to be catched, otherwise subsequent
        % operations may have unintended consequences.
        if thisImageCount < 2
            continue;
        end
        
        cmc = mg.Cache.Get(thisIds);
        [bestVote, bestDeltas] = BestMovement(cmc);
        if bestVote == 0 || isempty(bestDeltas)
            continue;
        end
        
        % The weight is modified from CMC vote count, so that CMC computed
        % using a larger number of input images will have a boosted weight.
        %
        % This boosting is intended to compensate for the fact that, when a
        % CMC is computed using more input images, the amount of identical
        % image content occurring across all input image is reduced due to
        % content being shifted away, sometimes reduced to zero.
        %
        % Currently the boosting is computed as follows:
        % (CMC inputs) ... (boosting)
        %  2 images ... votes * 1.0
        %  3 images ... votes * 1.25
        %  4 images ... votes * 1.67
        %  5 images ... votes * 2.5
        %
        thisWeight = round(bestVote * 5 / (7 - thisImageCount));
        if thisWeight == 0
            continue;
        end

        for whichPair = 1:thisImageCount-1
            % Image index of each pair in the input
            ka = thisIds(whichPair);
            kb = thisIds(whichPair + 1);
            
            % Movement between the two images
            rowDelta = bestDeltas(1, whichPair * 2 - 1);
            colDelta = bestDeltas(1, whichPair * 2);
            
            % Insert into new row; reallocate matrix if necessary.
            edgeCount = edgeCount + 1;
            while edgeCount > size(edgeData, 1)
                dsz = size(edgeData);
                dcn = class(edgeData);
                edgeData = cat(1, edgeData, zeros(dsz, dcn));
            end
            
            % Write data into new row
            edgeData(edgeCount, :) = [ka, kb, rowDelta, colDelta, thisWeight];
        end
    end
    
    % Truncate unused preallocated rows from the matrix
    edgeData = edgeData(1:edgeCount, :);

    % ---
    % When multiple identical edge data exist between two images, where 
    % "identical" means between the same two images and the same movement
    % deltas, we can take the row with the highest weight, and discard the
    % duplicates.
    %
    % Edges between the same two images but with different movement deltas
    % will be treated as different edges.
    % 
    % To maintain correspondence with the MATLAB graph, it is a requirement 
    % that the GraphEdgeData matrix is always lexicographically sorted.
    % This is handled by Internal_DedupeEdgeData as well.
    % 
    edgeData = Internal_DedupeEdgeData(edgeData, mg.AllowMultiDeltas);
end

function [bestVote, bestDeltas] = BestMovement(cmc)
    % Given an instance of CommonMovementClassifier (CMC), find the 
    % highest voted movement whose deltas (vectors of row and column 
    % movement) that is not entirely zero across all input images 
    % to the CMC.
    %
    arguments
        cmc(1, 1) CommonMovementClassifier
    end
    votes = cmc.Votes;
    deltas = cmc.UniqueDeltas;
    numMoves = length(votes);
    bestVote = 0;
    bestDeltas = [];
    for kMove = 1:numMoves
        thisVote = votes(kMove);
        thisDeltas = deltas(kMove, :);
        if all(thisDeltas == 0)
            continue;
        end
        if thisVote > bestVote
            bestVote = thisVote;
            bestDeltas = thisDeltas;
        end
    end
end

function tf = IsScalarOrEmpty_GraphObj(g)
    if isempty(g)
        tf = true;
    elseif isa(g, "graph")
        tf = true;
    elseif iscell(g) && isscalar(g) && isa(g{1}, "graph")
        tf = true;
    else
        tf = false;
    end
end

function [g, cc] = Internal_CreateGraph(mg)
    arguments
        mg(1, 1) MovementGraph
    end
    a = mg.GraphEdgeData(:, 1);
    b = mg.GraphEdgeData(:, 2);
    w = mg.GraphEdgeData(:, 5);
    g = graph(single(a), single(b), single(w));
    cc = conncomp(g, "OutputForm", "cell");
end

function [g, cc] = Internal_CreateSubgraph(mg, ids, ids2)
    arguments
        mg(1, 1) MovementGraph
        ids(1, :) int32
        ids2(1, :) int32 = []
    end
    hasIds2 = isequal(length(ids2), length(ids));
    if ~isempty(ids2) && ~hasIds2
        error('Incorrect vector length for ID reassignment argument ids2.');
    end
    data = mg.GraphEdgeData;
    m = logical(ismember(data(:, 1:2), ids));
    m = logical(m(:, 1) & m(:, 2));
    data = data(m, :);
    data = sortrows(data);
    a = data(:, 1);
    b = data(:, 2);
    w = data(:, 5);
    if hasIds2
        idsBimap = SmallDenseIntegerBimap(ids, ids2);
        a = idsBimap.LtoR(a);
        b = idsBimap.LtoR(b);
    end
    g = graph(single(a), single(b), single(w));
    cc = conncomp(mg.G, "OutputForm", "cell");
end

function edgeData = Internal_DedupeEdgeData(edgeData, allowMultiDeltas)
    arguments
        edgeData(:, 5) int32
        allowMultiDeltas(1, 1) logical
    end
    count = size(edgeData, 1);
    if count == 0
        return;
    end
    a = "ascend";
    d = "descend";

    % ---
    % If allowMultiDeltas is true, there can be multiple edges between a
    % pair of images, each edge representing a different row-column delta.
    % If allowMultiDeltas is false, at most one edge (the highest weight) 
    % will be retained between a pair of images after filtering.
    % ---
    if allowMultiDeltas
        sortKeys = [1, 2, 3, 4, 5];
        sortDirs = [a, a, a, a, d];
        edgeData = sortrows(edgeData, sortKeys, sortDirs);
        fnDupe = @(rowData1, rowData2)(isequal(rowData1(:, 1:4), rowData2(:, 1:4)));
    else
        sortKeys = [1, 2, 5, 3, 4];
        sortDirs = [a, a, d, a, a];
        edgeData = sortrows(edgeData, sortKeys, sortDirs);
        fnDupe = @(rowData1, rowData2)(isequal(rowData1(:, 1:2), rowData2(:, 1:2)));
    end
    
    % ---
    % Compact the rows of the edgeData matrix, so that, 
    % for consecutive groups of rows with same image pair and 
    % row-column deltas, only the row with the highest weight
    % will be retained in the final edgeData matrix.
    % ---
    outCount = 1;
    for kin = 2:count
        if fnDupe(edgeData(kin, :), edgeData(outCount, :))
            continue;
        else
            outCount = outCount + 1;
            if outCount ~= kin
                edgeData(outCount, :) = edgeData(kin, :);
            end
        end
    end
    
    % Finish row compaction
    edgeData = edgeData(1:outCount, :);
end
