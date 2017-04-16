local Utils = require 'packagemanager/documentation/Utils'
local Markdown = require 'packagemanager/documentation/Markdown'
local FS = require 'packagemanager/FS'

local DocumentTypes =
{
    md =
    {
        parser = function( fileContent )
            return Markdown.parse(fileContent)
        end
    },

    lua =
    {
        parser = function()
            error('Parsing Lua is not supported yet.')
        end
    }
}

local function GetDocumentType( extension )
    return DocumentTypes[extension]
end

local function IterDocuments( sourceTree )
    return coroutine.wrap(function()
        for filePath in Utils.directoryTree('', sourceTree..FS.dirSep) do
            local extension = FS.extension(filePath)
            local documentType = GetDocumentType(extension)
            if documentType then
                local absFilePath = FS.path(sourceTree, filePath)
                local fileContent = FS.readFile(absFilePath)
                local rootNode = documentType.parser(fileContent)
                coroutine.yield(filePath, rootNode)
            end
        end
    end)
end

return { getType = GetDocumentType,
         iterSourceTree = IterDocuments }
