#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Markdown = require 'packagemanager/documentation/Markdown'

plan(24)


-- Markdown.locateHeadings

local rootNode = Markdown.parse([[
# aaa
Text text text text.
Text text text text.

## bbb
Text text text text.
Text text text text.

### ccc
Text text text text.
Text text text text.

## ddd
Text text text text.
Text text text text.

## eee
Text text text text.
Text text text text.

# eee
Text text text text.
Text text text text.
]])

local headingTree, headingList = Markdown.locateHeadings(rootNode)
is(#headingList, 6)
is(headingTree[1].name, 'aaa')
is(headingTree[1].children[1].name, 'bbb')
is(headingTree[1].children[3].name, 'eee')
is(headingTree[2].name, 'eee')


-- Markdown.generateFragments

Markdown.generateFragments(headingList)
is(type(headingTree[1].fragmentId), 'string')
-- Must generate unique fragment ids, even if both headings have the same name:
isnt(headingTree[1].children[3].fragmentId,
     headingTree[2].fragmentId)


-- Markdown.locateReferences

local function ParseReference( markdownSource )
    local rootNode = Markdown.parse(markdownSource)
    local references = Markdown.locateReferences(rootNode)
    assert(#references == 1)
    return references[1]
end

is(ParseReference('[aaa](aaa.md)').url,  'aaa.md')
is(ParseReference('[aaa](aaa/bbb/ccc.md)').url, 'aaa/bbb/ccc.md')
is(ParseReference('[aaa](aaa.md)').type, 'link')
is(ParseReference('[aaa](aaa.png)').type,'link')
is(ParseReference('![aaa](aaa.png)').type, 'media')
is(ParseReference('![aaa](aaa.png)').url, 'aaa.png')
is(ParseReference('[aaa](/aaa.md)').url,  '/aaa.md')
is(ParseReference('[aaa](http://example.org/aaa.md)').url, 'http://example.org/aaa.md')
is(ParseReference('[aaa](xxxx://example.org/aaa.exe)').url, 'xxxx://example.org/aaa.exe')
