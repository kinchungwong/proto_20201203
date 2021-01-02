classdef Grid2D < handle
% Performs a partitioning of a 2D integer-valued input domain
% into non-overlapping grid cells in a Cartesian way.
%
    properties (SetAccess = immutable)
        % Size of the input domain of integer coordinates
        % InputSize = [inputRowCount, inputColCount]
        % Whereas the input domain is 
        % (rows = 1:inputRowCount, cols = 1:inputColCount)
        InputSize(1, 2) {mustBePositive} = [1, 1]
        
        % Number of grid rows and columns.
        % GridSize = [gridRows, gridCols]
        GridSize(1, 2) {mustBePositive} = [1, 1]
        
        % The minimum size of all grid cells.
        % MinCellSize = [minCellRow, minCellCol]
        MinCellSize(1, 2) {mustBePositive} = [1, 1]

        % The maximum size of all grid cells.
        % MaxCellSize = [maxCellRow, maxCellCol]
        MaxCellSize(1, 2) {mustBePositive} = [1, 1]
        
        % Start and stop coordinates for cell rows. Start is inclusive.
        % Stop is exclusive. For the k-th row of cells, the start-stop pair
        % can be extracted as RowMarks(k, k+1).
        RowMarks(1, :) {mustBePositive}
        
        % Start and stop coordinates for cell cols. Start is inclusive.
        % Stop is exclusive. For the k-th column of cells, the start-stop pair
        % can be extracted as ColMarks(k, k+1).
        ColMarks(1, :) {mustBePositive}
    end
    
    methods
        function g = Grid2D(inputSize, varargin)
            % Creates a 2D grid over an input domain of integer coordinates
            [g.InputSize, g.GridSize, g.MinCellSize, g.MaxCellSize, g.RowMarks, g.ColMarks] = Internal_Init(inputSize, varargin{:});
        end
        
        function c = GetCell(g, cellRowIndex, cellColIndex)
            % Returns one grid cell at the specified grid row and column.
            % Usage
            % ... c = GetCell(g, cellRowIndex, cellColIndex)
            arguments
                g(1, 1) Grid2D
                cellRowIndex(1, 1) int32 {mustBePositive}
                cellColIndex(1, 1) int32 {mustBePositive}
            end
            if cellRowIndex > g.GridSize(1)
                error('cellRowIndex out of range');
            end
            if cellColIndex > g.GridSize(2)
                error('cellRowIndex out of range');
            end
            rowMin = g.RowMarks(cellRowIndex);
            rowMax = g.RowMarks(cellRowIndex + 1) - 1;
            colMin = g.ColMarks(cellColIndex);
            colMax = g.ColMarks(cellColIndex + 1) - 1;
            c = GridCellFast(rowMin, rowMax, colMin, colMax, g, cellRowIndex, cellColIndex);
        end

        function c = GetApproxCellBounds(g, cellRowIndex, cellColIndex)
            % Returns approximately interpolated grid cell bounds.
            %
            % Usage
            % ... c = GetApproxCellBounds(g, cellRowIndex, cellColIndex)
            %
            % When this function is called with the same arguments as
            % GetCell(g, cellRowIndex, cellColIndex), the outputs are
            % identical.
            %
            % When this function is called with non-integer inputs, 
            % the MATLAB function "interp1" is used to interpolate the cell
            % boundaries based on the result of GetCell. The interpolated 
            % bounds are then rounded to the nearest integer.
            %
            % When "cellRowIndex" (also "cellColIndex") contain more than
            % one values, its minimum and maximum elements will be used 
            % to calculate the lower-bound and upper-bound for rows (also
            % cols), respectively.
            %
            % This function can be used to obtain the bounds of a rectangle
            % that covers multiple grid cells (consisting of one or more
            % rows of cells, and one or more columns of cells).
            % 
            cellRowIndex = max(cellRowIndex, 1);
            cellRowIndex = min(cellRowIndex, g.GridSize(1));
            cellColIndex = max(cellColIndex, 1);
            cellColIndex = min(cellColIndex, g.GridSize(2));
            rowMin = Internal_Interp_rounded(1:g.GridSize(1), g.RowMarks(1:end-1), min(cellRowIndex));
            rowMax = Internal_Interp_rounded(1:g.GridSize(1), g.RowMarks(2:end), max(cellRowIndex)) - 1;
            colMin = Internal_Interp_rounded(1:g.GridSize(2), g.ColMarks(1:end-1), min(cellColIndex));
            colMax = Internal_Interp_rounded(1:g.GridSize(2), g.ColMarks(2:end), max(cellColIndex)) - 1;
            c = GridCellFast(rowMin, rowMax, colMin, colMax, g, cellRowIndex, cellColIndex);
        end
        
        function m = AsLabelMatrix(g)
            % Returns a matrix having the size of the input domain, and
            % each element containing an integer value that is unique and
            % sequentially-assigned for each cell.
            isz = g.InputSize;
            gsz = g.GridSize; % {captured}
            m = zeros(isz); % {captured, modified}
            function v = fillValue(c)
                v = sub2ind(gsz, c.RowIndex, c.ColIndex);
            end
            function fillFunc(c)
                m = c.WriteTo(m, fillValue(c));
            end
            g.Invoke(@(~, cc)(fillFunc(cc)));
        end
        
        function Invoke(g, f)
            % Invoke the given function for each and every cell.
            % Invocation:
            % ... f(g, c)
            % where:
            % ... g is the Grid2D instance
            % ... c is an instance of GridCell
            for kCol = 1:g.GridSize(2)
                for kRow = 1:g.GridSize(1)
                    c = g.GetCell(kRow, kCol);
                    f(g, c);
                end
            end
        end
        
        function InvokeApproxRowCol(g, f, rr, cc)
            % Invoke the given function over approximate cell bounds.
            % Usage:
            % ... g.InvokeApproxRowCol(f, rr, cc)
            % Invocation:
            % ... f(g, gc)
            % where:
            % ... g is the Grid2D instance
            % ... gc is an instance of GridCell
            % where gc is defined by 
            % ... g.GetApproxCellBounds(rr(krr, :), cc(kcc, :))
            % where each row of "rr" contains the approximate row index
            % where each row of "cc" contains the approximate column index
            % ... rr, cc are arguments to InvokeApproxRowCol
            % ... rr, cc can have size (:, 1) or (:, 2)
            % ... rr, cc can contain non-integer values
            % where
            % ... krr, kcc are loop variables
            % ... 1 <= krr <= size(rr, 1)
            % ... 1 <= kcc <= size(cc, 1)
            %
            % Refer to source code for implementation details.
            %
            if ~ismatrix(rr)
                error('rr');
            end
            if ~ismatrix(cc)
                error('cc');
            end
            if size(rr, 2) > 2
                error('Each row in rr, cc should contain the min and max approx cell row and col.');
            end
            if size(cc, 2) > 2
                error('Each row in rr, cc should contain the min and max approx cell row and col.');
            end
            minRR = min(rr, [], "all");
            maxRR = max(rr, [], "all");
            minCC = min(cc, [], "all");
            maxCC = max(cc, [], "all");
            if minRR < 1 || maxRR > g.GridSize(1) || minCC < 1 || maxCC > g.GridSize(2)
                warning('Some values in rr, cc exceeded grid index range.');
            end
            nrr = size(rr, 1);
            ncc = size(cc, 1);
            for kcc = 1:ncc
                for krr = 1:nrr
                    rii = rr(krr, :);
                    cii = cc(kcc, :);
                    c = g.GetApproxCellBounds(rii, cii);
                    f(g, c);
                end
            end
        end
    end
    
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

function [inputSize, gridSize, minCellSize, maxCellSize, rowMarks, colMarks] = Internal_Init(inputSize, varargin)
    if isscalar(varargin) && isscalar(varargin{1}) && isnumeric(varargin{1})
        varargin = { "ApproxTotal", varargin{1} };
    end
    ip = inputParser();
    ip.addRequired("inputSize", ...
        @(v)validateattributes(v, "numeric", {"integer", "real", "positive", "size", [1, 2]}));
    ip.addParameter("ApproxTotal", [], ...
        @(v)validateattributes(v, "numeric", ["real", "positive"]));
    ip.addParameter("ApproxCellDims", [], ...
        @(v)validateattributes(v, "numeric", ["real", "positive"]));
    ip.addParameter("ApproxGridDims", [], ...
        @(v)validateattributes(v, "numeric", ["real", "positive"]));
    ip.parse(inputSize, varargin{:});
    args = ip.Results;
    if isfield(args, "ApproxTotal") && ~isempty(args.ApproxTotal)
        [rowMarks, colMarks] = Internal_Init_ApproxTotal(inputSize, args.ApproxTotal);
    end
    if isfield(args, "ApproxCellDims") && ~isempty(args.ApproxCellDims)
        [rowMarks, colMarks] = Internal_Init_ApproxCellDims(inputSize, args.ApproxCellDims);
    end
    if isfield(args, "ApproxGridDims") && ~isempty(args.ApproxGridDims)
        [rowMarks, colMarks] = Internal_Init_ApproxGridDims(inputSize, args.ApproxGridDims);
    end
    gridSize = [numel(rowMarks) - 1, numel(colMarks) - 1];
    cellRows = diff(rowMarks);
    cellCols = diff(colMarks);
    minCellSize = [min(cellRows), min(cellCols)];
    maxCellSize = [max(cellRows), max(cellCols)];
end

function [rowMarks, colMarks] = Internal_Init_ApproxTotal(inputSize, approxTotal)
    %{
    %aspect = max(inputSize) / min(inputSize);
    %approxTotal = min(approxTotal, floor(aspect));
    %}
    area = prod(inputSize);
    approxSideLen = sqrt(area / approxTotal);
    cellDims = [approxSideLen, approxSideLen];
    [rowMarks, colMarks] = Internal_Init_ApproxCellDims(inputSize, cellDims);
end

function [rowMarks, colMarks] = Internal_Init_ApproxCellDims(inputSize, cellDims)
    if isscalar(cellDims)
        cellDims = [cellDims, cellDims];
    end
    cellDims = max(cellDims, 1);
    gridDims = inputSize ./ cellDims;
    gridDims = round(gridDims);
    gridDims = max(gridDims, 1);
    [rowMarks, colMarks] = Internal_Init_ApproxGridDims(inputSize, gridDims);
end

function [rowMarks, colMarks] = Internal_Init_ApproxGridDims(inputSize, gridDims)
    rowMarks = Internal_InitMarks_OneDim(inputSize(1), gridDims(1));
    colMarks = Internal_InitMarks_OneDim(inputSize(2), gridDims(2));
end

function [marks] = Internal_InitMarks_OneDim(inputLength, numCells)
    % Computes the start and stop coordinates that approximately evenly
    % divides the length of an input matrix.
    %
    % If the length is divided into N segments, this function returns (N+1)
    % values, where the pair of values (k, k+1) denotes the start and stop
    % coordinates of the k-th segment. The start coordinate is inclusive.
    % The stop coordinate is exclusive.
    %
    if numCells < 1
        numCells = 1;
    end
    marks = 1 + round((0:numCells) * (double(inputLength)/double(numCells)));
end

function vq = Internal_Interp_rounded(x, v, xq)
    tfExact = logical(x == xq);
    if nnz(tfExact) == 1
        vq = v(tfExact);
    else
        vq = round(interp1(x, v, xq));
    end
end
