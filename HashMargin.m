classdef HashMargin
    properties (SetAccess = immutable)
        Top(1, 1) int32 {mustBeNonnegative} = 0
        Bottom(1, 1) int32 {mustBeNonnegative} = 0
        Left(1, 1) int32 {mustBeNonnegative} = 0
        Right(1, 1) int32 {mustBeNonnegative} = 0
    end
    methods
        function margin = HashMargin(top, bottom, left, right)
            margin.Top = top;
            margin.Bottom = bottom;
            margin.Left = left;
            margin.Right = right;
        end
        function m1m2 = plus(m1, m2)
            if ~isa(m1, 'HashMargin')
                error('m1');
            end
            if ~isa(m2, 'HashMargin')
                error('m2');
            end
            top = m1.Top + m2.Top;
            bottom = m1.Bottom + m2.Bottom;
            left = m1.Left + m2.Left;
            right = m1.Right + m2.Right;
            m1m2 = HashMargin(top, bottom, left, right);
        end
    end
end
