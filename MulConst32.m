function output = MulConst32(output, value)
% Given an array of unsigned 32-bit integers and a scalar, computes 
% their multiplicative product, and retain the lower 32-bit portion
% of the result.
%
%     output = MulConst32(output, value)
% 

    if ~isa(output, 'uint32')
        error('output');
    end
    if ~isscalar(value) || ~isnumeric(value) || ~isreal(value)
        error('input');
    end
    
    output = uint32(bitand(uint64(output) * uint64(value), 0xffffffffu64));
end
