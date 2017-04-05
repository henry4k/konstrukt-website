local cmark = require 'cmark'

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

local function Render( document )
    return assert(cmark.render_html(document, CMarkOptions))
end

local function Parse( markdown )
    return assert(cmark.parse_document(markdown, #markdown, cmark.OPT_DEFAULT))
end

local function CheckDocument( document )
    -- TODO: Check document for forbidden stuff here:
    -- - raw HTML code
    -- - external images
    -- - missing level 1 heading
    -- - ...
end

return { parse = Parse,
         render = Render,
         renderChildren = RenderChildren,
         checkDocument = CheckDocument }
