local FS = require 'website/fs'
local Utils = require 'website/utils'
local Misc = require 'packagemanager/misc'


-------- DirectoryView

local DirectoryView = {}
DirectoryView.__index = DirectoryView

function DirectoryView:readFile( fileName )
    return FS.readFile(FS.path(self._path, fileName))
end

function DirectoryView:extractFile( fileName, destinationPath )
    local sourcePath = FS.path(self._path, fileName)
    local sourceFile = assert(io.open(sourcePath, 'rb'))
    local destinationFile = assert(io.open(destinationPath, 'wb'))
    Misc.writeFile(destinationFile, sourceFile)
end

function DirectoryView:destroy()
    -- nothing to do here
end

local function CreateDirectoryView( path )
    local self = setmetatable({}, DirectoryView)

    self._path = path

    local files = {}
    for fileName in Utils.directoryTree('', path..FS.dirSep) do
        table.insert(files, fileName)
    end
    self.files = files

    return self
end


-------- ZipView

local ZipView = {}
ZipView.__index = ZipView

function ZipView:readFile( fileName )
end

function ZipView:extractFile( fileName, destinationPath )
end

function ZipView:destroy()
end

local function CreateZipView( path )
    error('ZipView is not implemented yet.')
    local self = setmetatable({}, ZipView)
    return self
end


return function( path )
    if path:match('%.zip$') then
        return CreateZipView(path)
    else
        return CreateDirectoryView(path)
    end
end
