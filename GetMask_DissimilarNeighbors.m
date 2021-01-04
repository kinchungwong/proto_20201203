function output = GetMask_DissimilarNeighbors(input, strHVDA)
% Finds elements that has no similar neighbors in a uint32 matrix.
%
% Usage:
%     output = GetDissimilarNeighborsMask(input, strHVDA)
% 
% This function returns a mask indicating elements that are dissimilar 
% with all of its neighbors.
% 
% Input must be a 2-dim uint32 matrix.
%
% StrHVDA (optional) controls whether 4-neighborhood or 8-neighborhood is
% used. Default is 8-neighborhood.
%
% For this function, similarity is defined as having the same uint32 value.
% 
% Remark on function naming. 
% This may not be the most fitting name for the functionality; the 
% functionality matters most.
% 
    if ~isa(input, "uint32") || ~ismatrix(input) || ~isreal(input)
        error('input');
    end
    %%
    if exist("strHVDA", "var")
        strHVDA = char(lower(strHVDA));
        hasH = any(strHVDA == 'h');
        hasV = any(strHVDA == 'v');
        hasD = any(strHVDA == 'd');
        hasA = any(strHVDA == 'a');
    else
        hasH = true;
        hasV = true;
        hasD = true;
        hasA = true;
    end
    %%
    sz = size(input);
    output = true(sz);
    %% horz (col+1)
    if hasH
        sameH = logical(input(:, 1:end-1) == input(:, 2:end));
        output(:, 1:end-1) = output(:, 1:end-1) & ~sameH;
        output(:, 2:end) = output(:, 2:end) & ~sameH;
    end
    %% vert (row+1)
    if hasV
        sameV = logical(input(1:end-1, :) == input(2:end, :));
        output(1:end-1, :) = output(1:end-1, :) & ~sameV;
        output(2:end, :) = output(2:end, :) & ~sameV;
    end
    %% diag (row+1, col+1)
    if hasD
        sameD = logical(input(1:end-1, 1:end-1) == input(2:end, 2:end));
        output(1:end-1, 1:end-1) = output(1:end-1, 1:end-1) & ~sameD;
        output(2:end, 2:end) = output(2:end, 2:end) & ~sameD;
    end
    %% anti (row+1, col-1)
    if hasA
        sameA = logical(input(1:end-1, 2:end) == input(2:end, 1:end-1));
        output(1:end-1, 2:end) = output(1:end-1, 2:end) & ~sameA;
        output(2:end, 1:end-1) = output(2:end, 1:end-1) & ~sameA;
    end
end
