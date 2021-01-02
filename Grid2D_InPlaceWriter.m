classdef Grid2D_InPlaceWriter < handle
% Grid2D_InPlaceWriter is a handle class that owns a writeable matrix
% that can be updated by specifying a GridCell (providing the subscripts)
% and the data to be written.
%
% A GridCell is a non-empty sub-rectangle with positive integer
% coordinates. GridCell can be obtained from Grid2D. This class also
% supports GridCellFast, which is a struct similar to GridCell.
%
% This class is useful for constructing anonymous functions and callback
% functions which must perform partial modifications (updates) on a 
% destination matrix via slicing. 
%
% In imperative programming, a destination matrix is typically updated
% with: 
%     dest(rowMin:rowMax, colMin:colMax) = newData;
%
% However, the assignment operator (a single equal sign) is generally not 
% available when creating anonymous functions.
%
% With Grid2D_InPlaceWriter, one can instead write:
%
% ... % ... Initialze a Grid2D.
% ... g = Grid2D([rows, cols], numGridCells);
% ...
% ... % ... Initialize an in-place writer that owns the result matrix.
% ... % ... The result matrix must be initialized with a function output.
% ... gipw = Grid2D_InPlaceWriter(g, @()(zeros(rows, cols)));
% ...
% ... % ... Define an anonymous function that uses the in-place writer
% ... % ... to update the result matrix without using the assignment
% ... % ... operator.
% ... fnCallback = @(c, newData)(gipw.Write(c, newData));
% ... 
% ... % ... The anonymous function can then be composed (chained) and 
% ... % ... used with any facility that invokes callbacks.
%
% See also Grid2D, GridCell, GridCellFast
%
    properties (SetAccess = immutable)
        Grid2D Grid2D {mustBeScalarOrEmpty}
    end
    
    properties (Dependent)
        % Retrieves the result matrix.
        Result
    end
    
    properties (Access = private)
        InternalResult
    end
    
    methods
        function gipw = Grid2D_InPlaceWriter(g, finit)
            % Initializes with a Grid2D and a callback that creates a result matrix.
            if ~isa(g, "Grid2D")
                error('g');
            end
            if ~isa(finit, "function_handle")
                error('finit');
            end
            gipw.Grid2D = g;
            gipw.InternalResult = finit();
            sz = size(gipw.InternalResult);
            if ~isequal(sz, gipw.Grid2D.InputSize)
                error('sz');
            end
        end
        
        function Write(gipw, c, data)
            % Updates a region of the result matrix specified by a GridCell.
            % Usage:
            %     gipw.Write(gipw, gridCell, newData)
            % 
            % Supports both GridCell and GridCellFast.
            %
            if ~isa(c, "GridCell") && ~Internal_IsGridCellFast(c)
                error('c');
            end
            csz = c.CellSize;
            dsz = size(data);
            if ~isequal(dsz, csz)
                error('sz');
            end
            gipw.InternalResult(c.RowMin:c.RowMax, c.ColMin:c.ColMax) = data;
        end
        
        function Result = get.Result(gipw)
            Result = gipw.InternalResult;
        end
    end
end

function tf = Internal_IsGridCellFast(c)
    fns = ["Bounds", "RowMin", "RowMax", "ColMin", "ColMax", "CellSize", "ExtractFrom"];
    tf = isstruct(c) && all(isfield(c, fns));
end
