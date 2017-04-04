local cmark = require 'cmark'
local FS = require 'website/fs'
local utils = require 'website/utils'


local function IsUrlLocalPath( url )
    return not string.match(url, '^.-://')
end

---
-- Finds and returns all references.
--
-- Returned references have these properties:
--
-- - `node` - the CMark node, which is either a link or an image
-- - `url`
-- - `sourcePath` - Path to referenced file in the source tree
-- 
local function LocateReferences( document, documentSourcePath )
    local basePath = FS.dirName(documentSourcePath)
    local references = {}
    for node, entering, nodeType in cmark.walk(document) do
        if entering and
           (nodeType == cmark.NODE_LINK or
            nodeType == cmark.NODE_IMAGE) then
            local url = cmark.node_get_url(node)
            local isLocalPath = IsUrlLocalPath(url)
            if nodeType == cmark.NODE_IMAGE and not isLocalPath then
                error('No external images allowed.')
            end
            local reference = { node = node,
                                url = url }
            if isLocalPath then
                reference.sourcePath = utils.resolveLocalUrlToPath(url, basePath)
            end
            table.insert(references, reference)
        end
    end
    return references
end

---
-- Generates a `resultPath` entry for each reference and modifies the URL accordingly.
--
-- @param documents
-- - document source path (relative path in source tree)
-- - document result path (relative path in result tree)
-- - fragment map (maps fragment ids to fragments)
--
local function ResolveLocalReferences( references, documents )
    -- TODO
end

return { locate = LocateReferences }
