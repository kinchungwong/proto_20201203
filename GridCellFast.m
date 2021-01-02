function c = GridCellFast(rowMin, rowMax, colMin, colMax, g, ri, ci)
% Initializes a GridCellFast struct.
%
% Usage
%     c = GridCellFast(rowMin, rowMax, colMin, colMax, grid2D, rowIndex, colIndex)
%
% Fields in the GridCellFast struct
%     Bounds    The integer-valued bounds [rowMin, rowMax, colMin, colMax]
%     RowMin    The first row coordinate of the grid cell. Inclusive.  
%     RowMax    The last row coordinate of the grid cell. Inclusive.  
%     ColMin    The first column coordinate of the grid cell. Inclusive.  
%     ColMax    The last column coordinate of the grid cell. Inclusive.  
%     CellSize  Size of the cell, defined as [rowMax - rowMin + 1, colMax - colMin + 1].
% 
% Optional fields in the GridCellFast struct. These fields may be empty.
%     Grid2D    The 2D Grid definition.
%     RowIndex  The grid cell's row index.
%     ColIndex  The grid cell's column index.
%
% The GridCellFast struct also contains a ExtractFrom function handle:
%     ExtractFrom   @(input)(input(rowMin:rowMax, colMin:colMax, :));
%
% To verify whether a variable looks like a GridCellFast struct, 
% use IsGridCellFast function.
%
% See also Grid2D, GridCell, IsGridCellFast
%
    arguments
        rowMin(1, 1) int32
        rowMax(1, 1) int32
        colMin(1, 1) int32
        colMax(1, 1) int32
        g Grid2D = []
        ri = []
        ci = []
    end
    fExtractFrom = @(input)(input(rowMin:rowMax, colMin:colMax, :));
    fWriteTo = @(~, ~)(error("GridCellFast.WriteTo not implemented"));
    c = struct(...
        "Bounds", [rowMin, rowMax, colMin, colMax], ...
        "RowMin", rowMin, ...
        "RowMax", rowMax, ...
        "ColMin", colMin, ...
        "ColMax", colMax, ...
        "CellSize", [rowMax-rowMin+1, colMax-colMin+1], ...
        "Grid2D", g, ...
        "RowIndex", ri, ...
        "ColIndex", ci, ...
        "ExtractFrom", fExtractFrom, ...
        "WriteTo", fWriteTo);
end
