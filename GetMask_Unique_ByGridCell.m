function output = GetMask_Unique_ByGridCell(input, g, rr2, cc2, mask, excludedValues)
    arguments
        input(:, :) uint32
        g(1, 1) Grid2D
        rr2(1, 1) {mustBeInteger, mustBeReal, mustBePositive} = 1
        cc2(1, 1) {mustBeInteger, mustBeReal, mustBePositive} = 1
        mask(:, :) logical = []
        excludedValues(1, :) uint32 = []
    end
    sz = size(input);
    hasMask = isequal(size(mask), sz);
    noMask = isempty(mask);
    if ~hasMask && ~noMask
        error('mask');
    end
    if hasMask
        maskFunc = @(c)(c.ExtractFrom(mask));
    else
        maskFunc = @(c)(true(c.CellSize));
    end
    gipw = Grid2D_InPlaceWriter(g, @()(true(sz)), '&');
    callModifyInplace = @(c)(gipw.Write(c, GetMask_Unique(c.ExtractFrom(input), maskFunc(c), excludedValues)));
    callWithCellInfo = @(~, c)(callModifyInplace(c));
    gsz = g.GridSize;
    rr(:, 1) = 1:(gsz(1)-rr2+1);
    rr(:, 2) = rr(:, 1) + (rr2-1);
    cc(:, 1) = 1:(gsz(2)-cc2+1);
    cc(:, 2) = cc(:, 1) + (cc2-1);
    g.InvokeApproxRowCol(callWithCellInfo, rr, cc);
    output = gipw.Result;
end
