classdef HashStep < handle
    % HashStep represents a single step taking out of HashSpec.
    properties (SetAccess = immutable)
        % The previous step (if applicable)
        PrevStep HashStep {mustBeScalarOrEmpty}
        % Step number (one-based)
        StepId(1, 1) int32 {mustBePositive} = 1
        % The current stencil type. See HashChar class for details.
        HashChar HashChar {mustBeScalarOrEmpty}
        % The effective input window from combining the current step and all previous steps
        RowColSize(1, 2) {mustBeInteger, mustBePositive} = [1, 1]
        % The effective input radius from combining the current step and all previous steps
        RowColRadius(1, 2) {mustBeInteger, mustBeNonnegative} = [0, 0]
        % Number of pixels to exclude from each of the four border sides in the output. See HashMargin class for details.
        Margin HashMargin {mustBeScalarOrEmpty}
        % The stencil coordinates.
        RowColPoints(:, 2) {mustBeInteger}
    end
    methods
        function step = HashStep(hashChar, prevStep)
            step.HashChar = hashChar;
            if ~exist('prevStep', 'var') || isempty(prevStep)
                prevSize = [1, 1];
                prevMargin = HashMargin(0, 0, 0, 0);
            elseif isa(prevStep, 'HashMargin')
                prevSize = [1, 1];
                prevMargin = prevStep;
            elseif isa(prevStep, 'HashStep')
                step.PrevStep = prevStep;
                step.StepId = prevStep.StepId + 1;
                prevSize = prevStep.RowColSize;
                prevMargin = prevStep.Margin;
            else
                error('prevStep');
            end
            step.RowColSize = prevSize .* hashChar.RowColSize();
            step.RowColRadius = (step.RowColSize - 1) / 2;
            thisRadius = hashChar.RowColRadius();
            newMarginRowCol = thisRadius .* prevSize;
            newMargin = HashMargin(newMarginRowCol(1), newMarginRowCol(1), newMarginRowCol(2), newMarginRowCol(2));
            step.Margin = prevMargin + newMargin;
            hcPoints = hashChar.RowColPoints();
            hcNumPts = size(hcPoints, 1);
            step.RowColPoints = hcPoints .* repmat(prevSize, hcNumPts, 1);
        end
    end
end
