classdef U32
    properties
        Data uint32 {mustBeReal}
    end
    methods
        function u32 = U32(input, sz)
            if isinteger(input)
                switch class(input)
                    case 'uint32'
                        u32.Data = input;
                    otherwise
                        error('input');
                end
            elseif isfloat(input)
                if nnz(input < 0) > 0 || nnz(input > 0xffffffffu32) > 0
                    error('input');
                end
                u32.Data = input;
            elseif islogical(input)
                u32.Data = input;
            else
                error('input');
            end
            if nargin >= 2
                if any(sz ~= 1)
                    u32.Data = repmat(u32.Data, sz);
                end
            end
        end
        function data = uint32(u32)
            data = u32.Data;
        end
        function result = plus(a, b)
            if isa(b, "U32")
                result = U32(uint32(bitand(uint64(a.Data) + uint64(b.Data), 0xffffffffu64)));
            elseif isnumeric(b) && isscalar(b) && isreal(b)
                result = U32(uint32(bitand(uint64(a.Data) + uint64(b), 0xffffffffu64)));
            else
                error('plus');
            end
        end
        function result = times(a, b)
            if isa(b, "U32")
                result = U32(uint32(bitand(uint64(a.Data) * uint64(b.Data), 0xffffffffu64)));
            elseif isnumeric(b) && isscalar(b) && isreal(b)
                result = U32(uint32(bitand(uint64(a.Data) * uint64(b), 0xffffffffu64)));
            else
                error('times');
            end
        end
        function result = bitxor(a, b)
            if isa(b, "U32")
                result = U32(bitxor(a.Data, b.Data));
            elseif isnumeric(b) && isscalar(b) && isreal(b)
                result = U32(bitxor(a.Data, b));
            else
                error('bitxor');
            end
        end
        function result = bitrotate(a, amount)
            if ~isa(a, "U32")
                error('a');
            end
            if ~isscalar(amount) || ~isnumeric(amount) || ~isreal(amount)
                error('amount');
            end
            if amount ~= floor(amount)
                error('amount');
            end
            amount = bitand(int32(amount), int32(31));
            if amount ~= 0
                result = U32(bitor(bitshift(a.Data, amount), bitshift(a.Data, amount - 32)));
            else
                result = a;
            end
        end
    end
end
