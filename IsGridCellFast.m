function tf = IsGridCellFast(c)
% IsGridCellFast checks whether a scalar struct looks like an instance of
% GridCellFast.
%
% Since GridCellFast is a struct, it is not strongly-typed. Thus, 
% the check consists of confirming the existence of the struct fields 
% that are usually expected on GridCellFast.
%
% See also Grid2D, GridCell, GridCellFast
%
    fns = ["Bounds", "RowMin", "RowMax", "ColMin", "ColMax", "CellSize", "ExtractFrom"];
    f = @(v)(isstruct(v) && isscalar(v) && all(isfield(v, fns)));
    tf = f(c);
end
