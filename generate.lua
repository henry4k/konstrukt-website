#!/usr/bin/env lua5.2

local cmark = require 'cmark'
local lustache = require 'lustache'


local CMarkOptions = cmark.OPT_DEFAULT


local function StripHtmlTags( html )
    return string.gsub(html, '<.->', '')
end

local function MakeAnchorId( str )
    str = string.lower(str)
    str = string.gsub(str, '%s', '-')
    str = string.gsub(str, '[^a-z0-9]', '-')
    str = string.gsub(str, '%-+', '-')
    str = string.match(str, '^%-*(.-)%-*$') -- trim - from start and end
    return str
end

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

local function SetupAnchor( parent, id )
    -- Gather child nodes:
    local children = {}
    local child = cmark.node_first_child(parent)
    while(child) do
        table.insert(children, child)
        child = cmark.node_next(child)
    end

    -- Remove all children from original container:
    for _, child in ipairs(children) do
        cmark.node_unlink(child)
    end

    local anchor = cmark.node_new(cmark.NODE_CUSTOM_INLINE)
    cmark.node_set_on_enter(anchor, string.format('<a href="#%s" id="%s" class="anchor">', id, id))
    cmark.node_set_on_exit(anchor, '</a>')

    -- Move child nodes into the anchor:
    for _, child in ipairs(children) do
        cmark.node_append_child(anchor, child)
    end

    assert(cmark.node_append_child(parent, anchor))
end

local function CreateEmptyHeading()
    return { children = {} }
end

local function AddHeading( index, level, heading )
    heading = heading or CreateEmptyHeading()
    if level == 1 then
        table.insert(index, heading)
        return heading
    else
        if #index == 0 then
            table.insert(index, CreateEmptyHeading())
        end
        return AddHeading(index[#index].children, level-1, heading)
    end
end

local function GenerateIndex( document )
    local index = {}
    local headings = {}

    for node, entering, nodeType in cmark.walk(document) do
        if nodeType == cmark.NODE_HEADING and not entering then
            local level = cmark.node_get_heading_level(node)
            local heading = AddHeading(index, level)
            heading.node = node
            table.insert(headings, heading)
        end
    end

    local usedIds = {}
    for _, heading in ipairs(headings) do
        local name = RenderChildren(heading.node, cmark.OPT_DEFAULT)
        local id = MakeAnchorId(StripHtmlTags(name))

        -- Ensure a unique id:
        if usedIds[id] then
            local i = 1
            while usedIds[id..'-'..tostring(i)] do
                i = i + 1
            end
            id = id..'-'..tostring(i)
        end

        heading.name = name
        heading.id = id

        SetupAnchor(heading.node, id)

        heading.node = nil -- as it isn't needed anymore
        usedIds[id] = true
    end

    return index
end

local function ProcessContent( markdown )
    local document = assert(cmark.parse_document(markdown, #markdown, cmark.OPT_DEFAULT))
    local index = GenerateIndex(document)
    local html = assert(cmark.render_html(document, CMarkOptions))
    return html, index
end

local template = nil
local function GenerateFinalHtml( contentHtml, contentIndex )
    if not template then
        local f = assert(io.open('template.html', 'r'))
        template = f:read('*a')
        f:close()
    end

    local model =
    {
        title = StripHtmlTags(contentIndex[1].name),
        menu =
        {
            { name = 'Showcase', url = '' },
            { name = 'Downloads', url = '' },
            { name = 'Packages', url = '' }
        },
        content = contentHtml,
        index = contentIndex[1].children
    }

    return lustache:render(template, model)
end

local function Generate( contentMarkdown )
    return GenerateFinalHtml(ProcessContent(contentMarkdown))
end

local srcFileName = arg[1]
local dstFileName = arg[2]
local srcFile = assert(io.open(srcFileName, 'r'))
local dstFile = assert(io.open(dstFileName, 'w'))
dstFile:write(Generate(srcFile:read('*a')))
srcFile:close()
dstFile:close()

