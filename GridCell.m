classdef GridCell
% GridCell is a subrectangle into a 2D matrix that has been partitioned
% into approximately evenly-sized cells by Grid2D.
%
    properties (SetAccess = immutable)
        % The integer-valued bounds, 
        % defined as [RowMin, RowMax, ColMin, ColMax]
        Bounds(1, 4) int32 = [0, 0, 0, 0]

        % The 2D Grid definition. This property may be unavailable.
        Grid2D Grid2D {mustBeScalarOrEmpty}
        
        % The grid cell's row index. This property may be unavailable, 
        % or have more than one element, or have non-integer values, 
        % depending on how the grid cell is defined.
        RowIndex {mustBeNumeric, mustBeReal}

        % The grid cell's column index. This property may be unavailable, 
        % or have more than one element, or have non-integer values, 
        % depending on how the grid cell is defined.
        ColIndex {mustBeNumeric, mustBeReal}
    end
    
    properties (Dependent)
        % The first row coordinate of the grid cell. Inclusive.
        RowMin
        
        % The last row coordinate of the grid cell. Inclusive.
        RowMax
        
        % The first column coordinate of the grid cell. Inclusive.
        ColMin
        
        % The last column coordinate of the grid cell. Inclusive.
        ColMax

        % Size of the cell, defined as [RowMax-RowMin+1, ColMax-ColMin+1].
        CellSize
    end
    
    methods
        function c = GridCell(rowMin, rowMax, colMin, colMax, g, ri, ci)
            if ~isscalar(rowMin) || ~isnumeric(rowMin) || ~isreal(rowMin) 
                error('rowMin');
            end
            if ~isscalar(rowMax) || ~isnumeric(rowMax) || ~isreal(rowMax) 
                error('rowMax');
            end
            if ~isscalar(colMin) || ~isnumeric(colMin) || ~isreal(colMin) 
                error('colMin');
            end
            if ~isscalar(colMax) || ~isnumeric(colMax) || ~isreal(colMax) 
                error('colMax');
            end
            if rowMin > rowMax
                error('rowMin, rowMax');
            end
            if colMin > colMax
                error('colMin, colMax');
            end
            c.Bounds = [rowMin, rowMax, colMin, colMax];
            if exist('g', 'var')
                c.Grid2D = g;
            end
            if exist('ri', 'var')
                c.RowIndex = ri;
            end
            if exist('ci', 'var')
                c.ColIndex = ci;
            end
        end
        
        function output = ExtractFrom(c, input)
            output = input(c.RowMin:c.RowMax, c.ColMin:c.ColMax, :);
        end
        
        function dest = WriteTo(c, dest, dataToWrite)
            warning("Warning: GridCell.WriteTo() returns modified matrix as output.");
            dest(c.RowMin:c.RowMax, c.ColMin:c.ColMax, :) = dataToWrite;
        end
        
        function rowMin = get.RowMin(c)
            rowMin = c.Bounds(1);
        end

        function rowMax = get.RowMax(c)
            rowMax = c.Bounds(2);
        end

        function colMin = get.ColMin(c)
            colMin = c.Bounds(3);
        end

        function colMax = get.ColMax(c)
            colMax = c.Bounds(4);
        end
        
        function csz = get.CellSize(c)
            % Returns the size of this GridCell.
            % Usage
            % ... csz = CellSize(c)
            % where 
            % ... csz = [rowCount, colCount]
            rowMin = c.Bounds(1);
            rowMax = c.Bounds(2);
            colMin = c.Bounds(3);
            colMax = c.Bounds(4);
            rowCount = rowMax - rowMin + 1;
            colCount = colMax - colMin + 1;
            csz = [rowCount, colCount];
        end
    end
end
