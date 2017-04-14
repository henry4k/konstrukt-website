#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Markdown = require 'packagemanager/documentation/Markdown'
local DocGen   = require 'packagemanager/documentation/DocumentationGenerator'

plan(21)


-- DocGen.resolveReference

local SourceDir
local function ResolveRef( markdownSource )
    local rootNode = Markdown.parse(markdownSource)
    local references = Markdown.locateReferences(rootNode)
    assert(#references == 1)
    local reference = references[1]
    DocGen.resolveReference(SourceDir, reference)
    return reference
end


SourceDir = ''

is(ResolveRef('[aaa](aaa.md)').url,  'aaa.html')
is(ResolveRef('[aaa](aaa.lua)').url, 'aaa.html')
is(ResolveRef('[aaa](aaa/bbb/ccc.md)').url, 'aaa/bbb/ccc.html')
is(ResolveRef('[aaa](aaa/../ccc.md)').url, 'ccc.html')
is(ResolveRef('[aaa](aaa.png)').url, 'aaa.png')
error_like(ResolveRef, {'[aaa](../aaa.md)'}, '.*')

-- Allow links only to valid media and document formats:
error_like(ResolveRef, {'[aaa](aaa.exe)'}, '.*')
-- Links must be recognized as such:
is(ResolveRef('[aaa](aaa.md)').type, 'link')
is(ResolveRef('[aaa](aaa.png)').type,'link')

-- Display media:
is(ResolveRef('![aaa](aaa.png)').type, 'media')
is(ResolveRef('![aaa](aaa.png)').url, 'aaa.png')
-- Allow only specific media:
error_like(ResolveRef, {'![aaa](aaa.md)'}, '.*')
error_like(ResolveRef, {'![aaa](aaa.exe)'}, '.*')

-- Absolute domain relative paths:
--is(ResolveRef('[aaa](/aaa.md)').url,  '/aaa.html')
-- Complete URLs may not be altered:
is(ResolveRef('[aaa](http://example.org/aaa.md)').url, 'http://example.org/aaa.md')
is(ResolveRef('[aaa](xxxx://example.org/aaa.exe)').url, 'xxxx://example.org/aaa.exe')
-- Only media from the current package may be used:
error_like(ResolveRef, {'![aaa](/aaa.png)'}, '.*')
error_like(ResolveRef, {'![aaa](http://example.org/aaa.png)'}, '.*')


is(ResolveRef('[aaa](aaa.png)').fileName, 'aaa.png')
is(ResolveRef('[aaa](aaa/bbb.png)').fileName, 'aaa/bbb.png')
is(ResolveRef('[aaa](aaa/../bbb.png)').fileName, 'bbb.png')
is(ResolveRef('![aaa](aaa.png)').fileName, 'aaa.png')
--is(ResolveRef('![aaa](/aaa.png)').fileName, '/aaa.png')
