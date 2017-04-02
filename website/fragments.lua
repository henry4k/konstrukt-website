local cmark = require 'cmark'
local utils = require 'website/utils'
local markdown = require 'website/markdown'


local function CreateEmptyFragment()
    return { children = {} }
end

local function AddFragment( tree, level, fragment )
    fragment = fragment or CreateEmptyFragment()
    if level == 1 then
        table.insert(tree, fragment)
        return fragment
    else
        if #tree == 0 then
            table.insert(tree, CreateEmptyFragment())
        end
        return AddFragment(tree[#tree].children, level-1, fragment)
    end
end

local function LocateFragments( document )
    local tree = {}
    local flat = {}
    for node, entering, nodeType in cmark.walk(document) do
        if nodeType == cmark.NODE_HEADING and not entering then
            local level = cmark.node_get_heading_level(node)
            local fragment = AddFragment(tree, level)
            fragment.node = node
            table.insert(flat, fragment)
        end
    end
    return tree, flat
end

local function MakeFragmentId( str )
    str = string.lower(str)
    str = string.gsub(str, '%s', '-')
    str = string.gsub(str, '[^a-z0-9]', '-')
    str = string.gsub(str, '%-+', '-')
    str = string.match(str, '^%-*(.-)%-*$') -- trim - from start and end
    return str
end

local function GenerateFragmentNames( fragmentList )
    for _, fragment in ipairs(fragmentList) do
        fragment.name = markdown.renderChildren(fragment.node)
    end
end

local function GenerateFragmentIds( fragmentList )
    local usedIds = {}
    for _, fragment in ipairs(fragmentList) do
        assert(fragment.name, 'GenerateFragmentNames must be executed first.')
        local id = MakeFragmentId(utils.stripHtmlTags(fragment.name))

        -- Ensure a unique id:
        if usedIds[id] then
            local i = 1
            while usedIds[id..'-'..tostring(i)] do
                i = i + 1
            end
            id = id..'-'..tostring(i)
        end

        fragment.id = id

        usedIds[id] = true
    end
end

--[[
local function SetupFragment( parent, id )
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

    local fragment = cmark.node_new(cmark.NODE_CUSTOM_INLINE)
    cmark.node_set_on_enter(fragment, string.format('<a href="#%s" id="%s" class="fragment">', id, id))
    cmark.node_set_on_exit(fragment, '</a>')

    -- Move child nodes into the fragment:
    for _, child in ipairs(children) do
        cmark.node_append_child(fragment, child)
    end

    assert(cmark.node_append_child(parent, fragment))
end
]]

local function SetupFragment( parent, id )
    local fragment = cmark.node_new(cmark.NODE_CUSTOM_INLINE)
    cmark.node_set_on_enter(fragment, string.format('<a href="#%s" id="%s" title="Permalink" class="fragment">', id, id))
    cmark.node_set_on_exit(fragment, '</a>')
    assert(cmark.node_append_child(parent, fragment))
end

local function SetupFragments( fragmentList )
    for _, fragment in ipairs(fragmentList) do
        SetupFragment(fragment.node, fragment.id)
    end
end

local function Generate( document )
    local fragmentTree, fragmentList = LocateFragments(document)
    GenerateFragmentNames(fragmentList)
    GenerateFragmentIds(fragmentList)
    SetupFragments(fragmentList)
    return fragmentTree, fragmentList
end

return { generate = Generate }
