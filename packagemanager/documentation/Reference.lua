local cmark    = require 'cmark'
local FS       = require 'packagemanager/FS'
local Utils    = require 'packagemanager/documentation/Utils'
local Document = require 'packagemanager/documentation/Document'


local Processor = {}
Processor.__index = Processor
Processor.nodeFilter = {cmark.NODE_LINK}

function Processor:leaveNode( node )
    local url = cmark.node_get_url(node)
    if Utils.isUrlLocalPath(url) then
        local extension = FS.extension(url)

        if not Document.getType(extension) then
            error('File type is not allowed as link target.')
        end

        if url:match('^/') then
            error('Can\'t handle absolute paths yet.')
        else
            local fileName = Utils.resolveRelativePath(url, self.sourceDir)
            if fileName:match('^%.%./') then
                error('Relative paths may not leave the package directory.')
            end
        end

        -- Currently internal references may only target documents:
        cmark.node_set_url(node, FS.stripExtension(url)..'.html')
    end
end

local function CreateProcessor( sourceDir )
    local self = { sourceDir = sourceDir }
    return setmetatable(self, Processor)
end

return { createProcessor = CreateProcessor }
