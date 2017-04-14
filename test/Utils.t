#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Utils = require 'packagemanager/documentation/Utils'

plan(7)

is(Utils.stripHtmlTags('a<div>b</div>c'), 'abc')

is(Utils.canonicalizeRelativePath('aaa/bbb/ccc'), 'aaa/bbb/ccc')
is(Utils.canonicalizeRelativePath('aaa/../ccc'), 'ccc')
is(Utils.canonicalizeRelativePath('aaa/../ccc/..'), '')
is(Utils.canonicalizeRelativePath('aaa/./ccc'), 'aaa/ccc')
is(Utils.canonicalizeRelativePath('././aaa'), 'aaa')
is(Utils.canonicalizeRelativePath('aaa/../../..'), '../..')

is(Utils.resolveRelativePath('ccc', 'aaa/bbb'), 'aaa/bbb/ccc')
is(Utils.resolveRelativePath('../ccc', 'aaa/bbb'), 'aaa/ccc')
