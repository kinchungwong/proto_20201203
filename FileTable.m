classdef FileTable < handle
    properties
        FileExtensions containers.Map
        PathToId containers.Map
        NameToId containers.Map
        IdToPath containers.Map
        IdToName containers.Map
        IdToInfo containers.Map
        Ids int32 = zeros(1, 0, 'int32')
        NextId int32 = 1
    end
    methods
        function ft = FileTable()
            ft.FileExtensions = containers.Map('KeyType', 'char', 'ValueType', 'any');
            ft.FileExtensions('.png') = [];
            ft.PathToId = containers.Map('KeyType', 'char', 'ValueType', 'int32');
            ft.NameToId = containers.Map('KeyType', 'char', 'ValueType', 'int32');
            ft.IdToPath = containers.Map('KeyType', 'int32', 'ValueType', 'char');
            ft.IdToName = containers.Map('KeyType', 'int32', 'ValueType', 'char');
            ft.IdToInfo = containers.Map('KeyType', 'int32', 'ValueType', 'any');
        end
        function AddFolder(ft, folder)
            if ~isfolder(folder)
                error('folder');
            end
            files = dir(fullfile(folder));
            rawCount = length(files);
            newIds = zeros(1, rawCount);
            for rawIndex = 1:rawCount
                curPath = fullfile(folder, files(rawIndex).name);
                [~, curName, ext] = fileparts(curPath);
                if ~ft.FileExtensions.isKey(lower(ext))
                    continue;
                end
                curId = ft.NextId;
                ft.NextId = ft.NextId + 1;
                newIds(rawIndex) = curId;
                ft.PathToId(curPath) = curId;
                ft.NameToId(curName) = curId;
                ft.IdToPath(curId) = curPath;
                ft.IdToName(curId) = curName;
                ft.IdToInfo(curId) = ImageFileInfo(curPath, curId, curName);
            end
            ft.Ids = cat(2, ft.Ids, newIds(newIds > 0));
        end
    end
end
