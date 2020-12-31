classdef GridCell
    properties (SetAccess = immutable)
        % The first row coordinate of the grid cell. Inclusive.
        RowMin {mustBeInteger, mustBeScalarOrEmpty}
        
        % The last row coordinate of the grid cell. Inclusive.
        RowMax {mustBeInteger, mustBeScalarOrEmpty}
        
        % The first column coordinate of the grid cell. Inclusive.
        ColMin {mustBeInteger, mustBeScalarOrEmpty}
        
        % The last column coordinate of the grid cell. Inclusive.
        ColMax {mustBeInteger, mustBeScalarOrEmpty}

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
            c.RowMin = rowMin;
            c.RowMax = rowMax;
            c.ColMin = colMin;
            c.ColMax = colMax;
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
            dest(c.RowMin:c.RowMax, c.ColMin:c.ColMax, :) = dataToWrite;
        end
        
        function csz = CellSize(c)
            % Returns the size of this GridCell.
            % Usage
            % ... csz = CellSize(c)
            % where 
            % ... csz = [rowCount, colCount]
            rowCount = c.RowMax - c.RowMin + 1;
            colCount = c.ColMax - c.ColMin + 1;
            csz = [rowCount, colCount];
        end
    end
end
