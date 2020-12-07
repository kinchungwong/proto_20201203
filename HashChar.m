classdef HashChar
    enumeration 
        H3, H5, V3, V5
    end
    methods (Static = true)
        function hc = FromChar(c)
            if ~isscalar(c) || ~ischar(c)
                error('HashChar constructor only accepts a scalar char as input.');
            end
            switch c
                case 'h'
                    hc = HashChar.H3;
                case 'H'
                    hc = HashChar.H5;
                case 'v'
                    hc = HashChar.V3;
                case 'V'
                    hc = HashChar.V5;
                otherwise
                    error('Valid inputs for HashChar are h, H, v, V');
            end
        end
    end
    methods
        function sz = RowColSize(hc)
            switch hc
                case HashChar.H3
                    sz = [1, 3];
                case HashChar.H5
                    sz = [1, 5];
                case HashChar.V3
                    sz = [3, 1];
                case HashChar.V5
                    sz = [5, 1];
                otherwise
                    error('RowColSize');
            end
        end
        function sz = RowColRadius(hc)
            switch hc
                case HashChar.H3
                    sz = [0, 1];
                case HashChar.H5
                    sz = [0, 2];
                case HashChar.V3
                    sz = [1, 0];
                case HashChar.V5
                    sz = [2, 0];
                otherwise
                    error('RowColRadius');
            end
        end
        function rc = RowColPoints(hc)
            switch hc
                case HashChar.H3
                    rc = zeros(3, 2);
                    rc(:, 2) = -1:1;
                case HashChar.H5
                    rc = zeros(5, 2);
                    rc(:, 2) = -2:2;
                case HashChar.V3
                    rc = zeros(3, 2);
                    rc(:, 1) = -1:1;
                case HashChar.V5
                    rc = zeros(5, 2);
                    rc(:, 1) = -2:2;
                otherwise
                    error('RowColPoints');
            end
        end
    end
end
