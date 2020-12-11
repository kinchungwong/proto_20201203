classdef ImageHashPoints < handle
    properties
        Id int32 {mustBeScalarOrEmpty}
        ImageInfo ImageFileInfo {mustBeScalarOrEmpty}
        HashValues uint32
        HashRows int32
        HashCols int32
        HashColors uint32
    end
    methods
        function ihps = ImageHashPoints(imgProc)
            if ~isa(imgProc, 'ImageHashProcessor')
                error('imgProc');
            end
            ihps.Id = imgProc.ImageInfo.Id;
            ihps.ImageInfo = imgProc.ImageInfo;
            sz = [imgProc.ImageInfo.Height, imgProc.ImageInfo.Width];
            [ihps.HashRows, ihps.HashCols] = ind2sub(sz, find(imgProc.Mask));
            [ihps.HashValues] = imgProc.Hashed(imgProc.Mask);
            [ihps.HashColors] = imgProc.OriginalInt(imgProc.Mask);
        end
        function mask = GetMask(ihps)
            nrows = ihps.ImageInfo.Height;
            ncols = ihps.ImageInfo.Width;
            sz = [nrows, ncols];
            idx = sub2ind(sz, ihps.HashRows, ihps.HashCols);
            mask = false(sz);
            mask(idx) = true;
        end
    end
end
