classdef SmallDenseIntegerBimap < handle
    % Provides a low-overhead bidirectional map between small and densely 
    % assigned integers (typically from one-based indexing).
    %
    % The bidirectional map consists of pairs of values (a[k], b[k])
    % where:
    % ... the set of values a[k] form a set A (type int32)
    % ... the set of values b[k] form a set B (type int32)
    % ... all a[k] values are unique
    % ... all b[k] values are unique
    % ... the range between the minimum and maximum of each set 
    % ... is relatively small, say, less than a million.
    % 
    properties (SetAccess = immutable)
        DataCount(1, 1) int32 = 0
        LeftData(1, :) int32 = []
        RightData(1, :) int32 = []
        LeftMin(1, 1) int32 = 0
        LeftMax(1, 1) int32 = 0
        RightMin(1, 1) int32 = 0
        RightMax(1, 1) int32 = 0
    end
    
    properties (Access = private)
        Lookup_LTR(1, :) int32 = []
        Lookup_RTL(1, :) int32 = []
    end
    
    methods
        function m = SmallDenseIntegerBimap(leftVec, rightVec)
            arguments
                leftVec(1, :) int32
                rightVec(1, :) int32
            end
            if length(leftVec) ~= length(rightVec)
                error('Vector length mismatch');
            end
            count = length(leftVec);
            m.DataCount = count;
            if length(unique(leftVec)) ~= count
                error('Left vector contains duplicates.');
            end
            if length(unique(rightVec)) ~= count
                error('Right vector contains duplicates.');
            end
            leftMin = min(leftVec);
            leftMax = max(leftVec);
            rightMin = min(rightVec);
            rightMax = max(rightVec);
            if int64(leftMax) - int64(leftMin) + int64(1) >= intmax("int32")
                error('Left vector integer min/max range too large.');
            end
            if int64(rightMax) - int64(rightMin) + int64(1) >= intmax("int32")
                error('Right vector integer min/max range too large.');
            end
            % In constructing the low-overhead lookup table, some entries may 
            % be left unassigned. These unassigned entries will have value
            % zero.
            %
            % This will not collide with valid values because all valid 
            % lookup values are positive integers.
            %
            % These positive valid integer values are created by subtracting 
            % minValue from the input values, followed by adding one.
            %
            LTR = zeros(1, leftMax - leftMin + 1, "int32");
            RTL = zeros(1, rightMax - rightMin + 1, "int32");
            leftVec2 = leftVec - leftMin + 1;
            rightVec2 = rightVec - rightMin + 1;
            LTR(leftVec2) = rightVec2;
            RTL(rightVec2) = leftVec2;
            m.LeftData = leftVec;
            m.RightData = rightVec;
            m.LeftMin = leftMin;
            m.LeftMax = leftMax;
            m.RightMin = rightMin;
            m.RightMax = rightMax;
            m.Lookup_LTR = LTR;
            m.Lookup_RTL = RTL;
        end
        
        function right = LtoR(m, left)
            arguments
                m(1, 1) SmallDenseIntegerBimap
                left(:, :) int32
            end
            left2 = left - m.LeftMin + int32(1);
            right2 = m.Lookup_LTR(left2);
            right = right2 + m.RightMin - int32(1);
        end
        
        function left = RtoL(m, right)
            arguments
                m(1, 1) SmallDenseIntegerBimap
                right(:, :) int32
            end
            right2 = right - m.RightMin + int32(1);
            left2 = m.Lookup_RTL(right2);
            left = left2 + m.LeftMin + int32(1);
        end
    end
end
