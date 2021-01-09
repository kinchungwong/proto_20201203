classdef OutputImageComposer_Ver1 < handle
    % A minimal implementation of composing the stitched image.
    % 
    % This minimal implementation is only used for diagnostics 
    % during algorithm development. It does not implement fancy
    % algorithms to reject potentially invalid stitching results.
    %
    
    properties (SetAccess = immutable)
        
    end
    
    properties (Access = private)
        dRowMin
        dRowMax
        dColMin
        dColMax
        Dest
        DestWeight
    end
    
    properties (Dependent)
        Result
    end
    
    methods
        function oic = OutputImageComposer_Ver1(dRowMin, dRowMax, dColMin, dColMax)
            numRows = dRowMax - dRowMin + 1;
            numCols = dColMax - dColMin + 1;
            oic.Dest = zeros(numRows, numCols);
            oic.DestWeight = zeros(numRows, numCols);
            oic.dRowMin = dRowMin;
            oic.dRowMax = dRowMax;
            oic.dColMin = dColMin;
            oic.dColMax = dColMax;
        end
        
        function Add(oic, source, sRowMin, sRowMax, sColMin, sColMax, pRow, pCol, sourceMask)
            % Copies from a source image subrect to a destination subrect.
            % 
            % Usage: Add(oic, source, 
            %            sRowMin, sRowMax, sColMin, sColMax, 
            %            pRow, pCol, sourceMask)
            %
            % Inputs:
            %     oic 
            %         OutputImageComposer_Ver1
            %     source
            %         real-valued grayscale source image
            %     (sRowMin, sRowMax, sColMin, sColMax) 
            %         subrect to be applied to the source image
            %     (pRow, pCol)
            %         top-left corner to be 
            arguments
                oic(1, 1) OutputImageComposer_Ver1
                source
                sRowMin(1, 1) int32
                sRowMax(1, 1) int32
                sColMin(1, 1) int32
                sColMax(1, 1) int32
                % paste coordinate
                pRow(1, 1) int32 
                pCol(1, 1) int32
                sourceMask logical = []
            end
            
            % TODO handle color images
            if ~ismatrix(source)
                source = source(:, :, 1);
            end
            if ~isempty(sourceMask) && ~isequal(size(sourceMask), size(source))
                error('sourceMask');
            end
            pRowMin = pRow;
            pRowMax = pRow - sRowMin + sRowMax;
            pColMin = pCol;
            pColMax = pCol - sColMin + sColMax;
            if pRowMin < oic.dRowMin
                amt = oic.dRowMin - pRowMin;
                pRowMin = pRowMin + amt;
                sRowMin = sRowMin + amt;
            end
            if pRowMax > oic.dRowMax
                amt = pRowMax - oic.dRowMin;
                pRowMax = pRowMin - amt;
                sRowMax = sRowMin - amt;
            end
            if pColMin < oic.dColMin
                amt = oic.dColMin - pColMin;
                pColMin = pColMin + amt;
                sColMin = sColMin + amt;
            end
            if pColMax > oic.dColMax
                amt = pColMax - oic.dColMin;
                pColMax = pColMin - amt;
                sColMax = sColMin - amt;
            end
            if sRowMax >= sRowMin && sColMax >= sColMin
                wRowMin = pRowMin - oic.dRowMin + 1;
                wRowMax = pRowMax - oic.dRowMin + 1;
                wColMin = pColMin - oic.dColMin + 1;
                wColMax = pColMax - oic.dColMin + 1;
                imgS = source(sRowMin:sRowMax, sColMin:sColMax);
                imgD = oic.Dest(wRowMin:wRowMax, wColMin:wColMax);
                imgW = oic.DestWeight(wRowMin:wRowMax, wColMin:wColMax);
                if isempty(sourceMask)
                    imgD = imgD + imgS;
                    imgW = imgW + 1;
                else
                    mskS = sourceMask(sRowMin:sRowMax, sColMin:sColMax);
                    imgD(mskS) = imgD(mskS) + imgS(mskS);
                    imgW(mskS) = imgW(mskS) + 1;
                end
                oic.Dest(wRowMin:wRowMax, wColMin:wColMax) = imgD;
                oic.DestWeight(wRowMin:wRowMax, wColMin:wColMax) = imgW;
            end
        end
        
        function result = get.Result(oic)
            arguments
                oic(1, 1) OutputImageComposer_Ver1
            end
            result = oic.Dest ./ max(eps, oic.DestWeight);
        end
    end
end
