classdef ImageHashPoints < handle
    properties
        ImageInfo ImageFileInfo {mustBeScalarOrEmpty}
        HashValues uint32
        HashRows int32
        HashCols int32
        HashColors uint32
    end
    methods
        function hp = ImageHashPoints(imgProc)
            if ~isa(imgProc, 'ImageHashProcessor')
                error('imgProc');
            end
            hp.ImageInfo = imgProc.ImageInfo;
            sz = [imgProc.ImageInfo.Height, imgProc.ImageInfo.Width];
            [hp.HashRows, hp.HashCols] = ind2sub(sz, find(imgProc.Mask));
            [hp.HashValues] = imgProc.Hashed(imgProc.Mask);
            [hp.HashColors] = imgProc.OriginalInt(imgProc.Mask);
        end
    end
end
