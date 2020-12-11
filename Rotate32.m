function output = Rotate32(output, amount)
% Rotate the 32-bit integers by the amount
%
%     output = Rotate32(output, amount)
% 

    if ~isa(output, 'uint32')
        error('output');
    end
    if ~isscalar(amount) || ~isnumeric(amount) || ~isreal(amount)
        error('amount');
    end
    if amount ~= round(amount)
        error('amount');
    end
    
    amount = bitand(int32(amount), int32(31));
    if amount ~= 0
        output = bitor(bitshift(output, amount), bitshift(output, amount - 32));
    end
end
