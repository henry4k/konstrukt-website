local lfs   = require 'lfs'
local cmark = require 'cmark'
local FS    = require 'packagemanager/FS'
local Misc  = require 'packagemanager/Misc'
local Utils = require 'packagemanager/documentation/Utils'


local Processor = {}
Processor.__index = Processor
Processor.nodeFilter = {cmark.NODE_IMAGE}

local MediaTypes =
{
    png =
    {
        maxSize = math.pow(2, 20) -- 1 MiB
    },
    webm =
    {
        maxSize = math.pow(2, 20)*3, -- 3 MiB
        nodeTransformator = function()
            error('WebM is not supported yet.')
        end
    }
}

local function GetMediaType( extension )
    return MediaTypes[extension]
end

function Processor:leaveNode( node )
    local url = cmark.node_get_url(node)

    if not Utils.isUrlLocalPath(url) then
        error('External media is not allowed.')
    end

    if url:match('^/') then
        error('Can\'t handle absolute paths yet.')
    end

    local extension = FS.extension(url)
    local mediaType = GetMediaType(extension)
    if not mediaType then
        error('File type is not supported in a media element.')
    end

    if mediaType.nodeTransformator then
        mediaType.nodeTransformator(node)
    end

    local fileName = Utils.resolveRelativePath(url, self.sourceDir)
    if fileName:match('^%.%./') then
        error('Relative paths may not leave the package directory.')
    end

    self.mediaFiles[fileName] = true
end

local function CreateProcessor( sourceDir )
    local self = { sourceDir = sourceDir,
                   mediaFiles = {} }
    return setmetatable(self, Processor)
end

local function AddMediaFiles( destination, source )
    for fileName in pairs(source) do
        destination[fileName] = true
    end
end

local function ProcessMediaFiles( mediaFiles, sourceTree, resultTree )
    for fileName in pairs(mediaFiles) do
        local absSourceFileName = FS.path(sourceTree, fileName)
        local absResultFileName = FS.path(resultTree, fileName)

        -- Check file size:
        local size = assert(lfs.attributes(absSourceFileName, 'size'))
        local extension = FS.extension(fileName)
        local mediaType = GetMediaType(extension)
        if size > mediaType.maxSize then
            local unitName, unitSize = Misc.getByteUnit(mediaType.maxSize)
            print(string.format('%s is too large: %.1f %s (Maximum is %.1f %s)',
                fileName, size/unitSize, unitName, mediaType.maxSize/unitSize, unitName))
        end

        -- Copy file:
        FS.makeDirectoryPath(resultTree, FS.dirName(fileName))
        local sourceFile = assert(io.open(absSourceFileName, 'rb'))
        local resultFile = assert(io.open(absResultFileName, 'wb'))
        Misc.writeFile(resultFile, sourceFile)
        sourceFile:close()
        resultFile:close()
    end
end

return { createProcessor = CreateProcessor,
         addMediaFiles = AddMediaFiles,
         processMediaFiles = ProcessMediaFiles }
