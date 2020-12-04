classdef ImageFileInfo < handle
    properties
        Id int32 {mustBeScalarOrEmpty} = -1
        Name string {mustBeTextScalar} = ""
        FilePath string {mustBeFile}
        FileSize int64 {mustBeScalarOrEmpty}
        Width int32 {mustBeScalarOrEmpty}
        Height int32 {mustBeScalarOrEmpty}
        Channels int32 {mustBeScalarOrEmpty}
    end
    methods
        function info = ImageFileInfo(filePath, id, name)
            info.FilePath = filePath;
            if exist('id', 'var')
                info.Id = id;
            end
            if exist('name', 'var')
                info.Name = name;
            end
            tempInfo = imfinfo(filePath);
            info.FileSize = int64(tempInfo.FileSize);
            info.Width = int32(tempInfo.Width);
            info.Height = int32(tempInfo.Height);
            info.Channels = int32(3);
        end
    end
end
