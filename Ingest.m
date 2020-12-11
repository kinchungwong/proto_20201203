function output = Ingest(output, input)
% Transforms the output by "ingesting" a single step of input.
% Ingestion consists of applying a transformation function on each 
% input element, followed by applying a mixing function taking each
% output element and corresponding input element and producing a 
% new output element that replaces the old one.

    if ~isa(input, 'uint32')
        error('input');
    end
    if ~isa(output, 'uint32')
        error('output');
    end
    if ndims(input) ~= ndims(output)
        error('ndims');
    end
    if any(size(input) ~= size(output))
        error('size');
    end
    c1 = 0xcc9e2d51u32;
    c2 = 0x1b873593u32;
    c3 = 0xe6546b64u32;
    % TransformData
    input = MulConst32(input, c1);
    input = Rotate32(input, 15);
    input = MulConst32(input, c2);
    % UpdateState
    output = bitxor(output, input);
    output = Rotate32(output, 13);
    output = MulConst32(output, 5);
    output = AddConst32(output, c3);
end
