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
    
    properties (Access = private)
        % Weighted adjacency matrix.
        %
        % First plane, M(:, :, 1), is the weight, computed from votes.
        %
        % Second and third plane, M(:, :, 2:3), is the best movement vector
        % associated with the current weight.
        %
        M(:, :, 3) int32
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
        Weights
        
        % The movement vectors between a pair of images represented 
        % by each edge in Edges.
        % Deltas is an N-by-2 matrix, each row containing 
        % (rowDelta, colDelta) for the same row in Edges.
        Deltas
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
            numIds = length(mg.Ids);
            mg.M = zeros(numIds, numIds, 3, "uint32");
        end
        
        function Process(mg)
            % Computes the graph by processing all CommonMovementClassifier 
            % instances found in the cache.
            arguments
                mg(1, 1) MovementGraph
            end
            Internal_Process(mg);
        end
        
        function m = get.Adjacency(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            m = mg.M(:, :, 1);
        end
        
        function ij = get.Edges(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            [i, j] = find(mg.M(:, :, 1));
            ij = cat(2, int32(i), int32(j));
        end
        
        function w = get.Weights(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            m = mg.M(:, :, 1);
            w = m(m > 0);
        end
        
        function d = get.Deltas(mg)
            arguments
                mg(1, 1) MovementGraph
            end
            m = mg.M(:, :, 1);
            r = mg.M(:, :, 2);
            c = mg.M(:, :, 3);
            r = r(m > 0);
            c = c(m > 0);
            d = cat(2, r, c);
        end
        
        function g = graph(mg)
            % Converts the result into a graph.
            % See also: graph
            arguments
                mg(1, 1) MovementGraph
            end
            g = graph(double(mg.Adjacency), "upper");
        end
        
        function plot(mg, varargin)
            % Creates a plot of the connectivity graph.
            
            %{
            arguments
                mg(1, 1) MovementGraph
            end
            %}
            plot(graph(mg), varargin{:});
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

function Internal_Process(mg)
    arguments
        mg(1, 1) MovementGraph
    end
    allIds = mg.Ids;
    keys = mg.Cache.Keys;
    numCMC = length(keys);
    for kCMC = 1:numCMC
        thisIds = keys{kCMC};
        cmc = mg.Cache.Get(thisIds);
        [bestVote, bestDeltas] = BestMovement(cmc);
        if bestVote == 0 || isempty(bestDeltas)
            continue;
        end
        thisWeight = bestVote * length(thisIds);
        for kPair = 1:(length(thisIds)-1)
            ka = thisIds(kPair);
            kb = thisIds(kPair + 1);
            % ---
            % Convert image IDs into matrix coordinate
            %
            % (For image IDs that are sequentially assigned starting at 1,
            % this step is idempotent. However, the former condition isn't
            % guaranteed.)
            % ---
            ka = find(allIds == ka, 1, "first");
            kb = find(allIds == kb, 1, "first");
            rowDelta = bestDeltas(1, kPair * 2 - 1);
            colDelta = bestDeltas(1, kPair * 2);
            if thisWeight > mg.M(ka, kb, 1)
                mg.M(ka, kb, 1) = thisWeight;
                mg.M(ka, kb, 2) = rowDelta;
                mg.M(ka, kb, 3) = colDelta;
            end
        end
    end
end

function [bestVote, bestDeltas] = BestMovement(cmc)
    arguments
        cmc(1, 1) CommonMovementClassifier
    end
    votes = cmc.Votes;
    deltas = cmc.Deltas;
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
