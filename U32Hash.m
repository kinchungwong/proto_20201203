classdef U32Hash < handle
    properties
        Data(1, 1) U32 = []
    end
    methods
        function h = U32Hash()
            h.Data = uint32([]);
        end
        
        function Ingest(h, input)
            if ~isa(input, "U32")
                error('input');
            end
            if isempty(h.Data) || isempty(h.Data.Data)
                h.Data = U32(0, size(input.Data));
            elseif ~isequal(size(h.Data.Data), size(input.Data))
                error('size');
            end
            % Transforms the output by "ingesting" a single step of input.
            % Ingestion consists of applying a transformation function on each 
            % input element, followed by applying a mixing function taking each
            % output element and corresponding input element and producing a 
            % new output element that replaces the old one.
            c1 = 0xcc9e2d51u32;
            c2 = 0x1b873593u32;
            c3 = 0xe6546b64u32;
            % TransformData
            input = input .* c1;
            input = input.bitrotate(15);
            input = input .* c2;
            % UpdateState
            h.Data = h.Data.bitxor(input);
            h.Data = h.Data.bitrotate(13);
            h.Data = h.Data .* 5;
            h.Data = h.Data + c3;
        end
    end
end
