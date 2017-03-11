#!/usr/bin/env lua5.2

local cmark = require 'cmark'
local lustache = require 'lustache'

local CMarkOptions = cmark.OPT_DEFAULT

local function RenderChildren( parent )
    local root = cmark.node_new(cmark.NODE_CUSTOM_BLOCK)
    --cmark.node_set_on_enter(root, '')
    --cmark.node_set_on_exit(root, '')

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

    local html = cmark.render_html(root, CMarkOptions)

    -- Move the child nodes back to the original container:
    for _, child in ipairs(children) do
        cmark.node_unlink(child) -- from temporary container
        cmark.node_append_child(parent, child)
    end

    cmark.node_free(root)
    return html
end

local function GatherIndex( document )
    local index = {}

    for cur, entering, nodeType in cmark.walk(document) do
        if nodeType == cmark.NODE_HEADING and entering then
            local level = cmark.node_get_heading_level(cur)
            local name  = RenderChildren(cur, cmark.OPT_DEFAULT)
            -- TODO: Implement hierachy
            table.insert(index, {name = name,
                                 id = 'unknown',
                                 children = {}})
        end
    end

    return index
end

local function ProcessContent( markdown )
    local doc = cmark.parse_document(markdown, #markdown, cmark.OPT_DEFAULT)
    local index = GatherIndex(doc)
    local html = cmark.render_html(doc, CMarkOptions)
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
        title = 'test',
        menu =
        {
            { name = 'Showcase', url = '' },
            { name = 'Downloads', url = '' },
            { name = 'Packages', url = '' }
        },
        content = contentHtml,
        index = contentIndex
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

