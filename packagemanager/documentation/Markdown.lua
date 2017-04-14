local cmark = require 'cmark'
local Utils = require 'packagemanager/documentation/Utils'


local CMarkOptions = cmark.OPT_DEFAULT

local function TrimWhitespace( str )
    return string.match(str, '^%s*(.-)%s*$')
end

local function RenderChildren( parent )
    local root = cmark.node_new(cmark.NODE_CUSTOM_BLOCK)
    cmark.node_set_on_enter(root, '')
    cmark.node_set_on_exit(root, '')

    -- Gather child nodes:
    local children = {}
    local child = cmark.node_first_child(parent)
    while(child) do
        table.insert(children, child)
        child = cmark.node_next(child)
    end

    -- Move all child nodes to a temporary container:
    for _, child in ipairs(children) do
        cmark.node_unlink(child) -- from original container
        cmark.node_append_child(root, child)
    end

    local html = TrimWhitespace(cmark.render_html(root, CMarkOptions))

    -- Move the child nodes back to the original container:
    for _, child in ipairs(children) do
        cmark.node_unlink(child) -- from temporary container
        cmark.node_append_child(parent, child)
    end

    cmark.node_free(root)
    return html
end

local function Parse( markdownSource )
    local rootNode = assert(cmark.parse_document(markdownSource,
                                                 #markdownSource,
                                                 CMarkOptions))
    -- TODO: highlight fenced code blocks
    return rootNode
end

local function Render( rootNode )
    -- TODO: convert image nodes with special content (e.g. audio or videos)
    return assert(cmark.render_html(rootNode, CMarkOptions))
end

local function CreateEmptyHeading()
    return { children = {} }
end

local function AddHeading( tree, level, heading )
    heading = heading or CreateEmptyHeading()
    if level == 1 then
        table.insert(tree, heading)
        return heading
    else
        if #tree == 0 then
            table.insert(tree, CreateEmptyHeading())
        end
        return AddHeading(tree[#tree].children, level-1, heading)
    end
end

local function LocateHeadings( rootNode )
    local tree = {}
    local list = {}
    for node, entering, nodeType in cmark.walk(rootNode) do
        if nodeType == cmark.NODE_HEADING and not entering then
            local level = cmark.node_get_heading_level(node)
            local heading = AddHeading(tree, level)
            heading.node = node
            heading.name = RenderChildren(heading.node)
            table.insert(list, heading)
        end
    end
    return tree, list
end

local function MakeFragmentId( str )
    str = string.lower(str)
    str = string.gsub(str, '%s', '-')
    str = string.gsub(str, '[^a-z0-9]', '-')
    str = string.gsub(str, '%-+', '-')
    str = string.match(str, '^%-*(.-)%-*$') -- trim - from start and end
    return str
end

local function GenerateFragmentIds( headingList )
    local usedIds = {}
    for _, heading in ipairs(headingList) do
        local id = MakeFragmentId(Utils.stripHtmlTags(heading.name))

        -- Ensure a unique id:
        if usedIds[id] then
            local i = 1
            while usedIds[id..'-'..tostring(i)] do
                i = i + 1
            end
            id = id..'-'..tostring(i)
        end

        heading.fragmentId = id

        usedIds[id] = true
    end
end

local function CreateFragmentNode( headingNode, fragmentId )
    local fragmentNode = cmark.node_new(cmark.NODE_CUSTOM_INLINE)
    cmark.node_set_on_enter(fragmentNode, string.format('<a href="#%s" id="%s" title="Permalink" class="fragment">', fragmentId, fragmentId))
    cmark.node_set_on_exit(fragmentNode, '</a>')
    assert(cmark.node_append_child(headingNode, fragmentNode))
end

local function GenerateFragments( headingList )
    GenerateFragmentIds(headingList)
    for _, heading in ipairs(headingList) do
        CreateFragmentNode(heading.node, heading.fragmentId)
    end
end

local Reference = {}

function Reference:__index( key )
    if key == 'url' then
        return rawget(self, '_url')
    end
end

function Reference:__newindex( key, value )
    if key == 'url' then
        cmark.node_set_url(self.node, value)
        rawset(self, '_url', value)
    else
        rawset(self, key, value)
    end
end

---
-- Finds and returns all references.
--
-- Returned references have these properties:
--
-- - `node` - the CMark node, which is either a link or an image
-- - `url`
-- - `type` - either `link` or `media`
-- 
local function LocateReferences( rootNode )
    local references = {}
    for node, entering, nodeType in cmark.walk(rootNode) do
        if entering and
           (nodeType == cmark.NODE_LINK or
            nodeType == cmark.NODE_IMAGE) then
            local reference = { node = node,
                                _url = cmark.node_get_url(node) }
            if nodeType == cmark.NODE_LINK then
                reference.type = 'link'
            else
                reference.type = 'media'
            end
            setmetatable(reference, Reference)
            table.insert(references, reference)
        end
    end
    return references
end

return { parse = Parse,
         render = Render,
         locateHeadings = LocateHeadings,
         generateFragments = GenerateFragments,
         locateReferences = LocateReferences }
