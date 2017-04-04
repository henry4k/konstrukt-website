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
    local references = {}

    -- collect references
    for node, entering, nodeType in cmark.walk(document) do
        if entering and
           (nodeType == cmark.NODE_LINK or
            nodeType == cmark.NODE_IMAGE) then
            local url = cmark.node_get_url(node)
            local reference = { node = node,
                                url = url }
            table.insert(references, reference)
        end
    end

    -- resolve local paths
    local convert = require 'website/convert' -- not cool man
    local basePath = FS.dirName(documentSourcePath)
    for _, reference in ipairs(references) do
        local url = reference.url
        if IsUrlLocalPath(url) then
            if url[1] ~= '/' then -- only relative paths
                reference.sourcePath = utils.resolveRelativePath(url, basePath)
            end
            reference.url = convert.getConversionInfo(url)
            cmark.node_set_url(reference.node, reference.url);
        end
    end

    return references
end

return { locate = LocateReferences }
