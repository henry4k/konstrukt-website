#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local utils = require 'website/utils'

plan(7)

is(utils.stripHtmlTags('a<div>b</div>c'), 'abc')

is(utils.canonicalizeRelativePath('aaa/bbb/ccc'), 'aaa/bbb/ccc')
is(utils.canonicalizeRelativePath('aaa/../ccc'), 'ccc')
is(utils.canonicalizeRelativePath('aaa/../ccc/..'), '')
is(utils.canonicalizeRelativePath('aaa/./ccc'), 'aaa/ccc')
is(utils.canonicalizeRelativePath('././aaa'), 'aaa')
is(utils.canonicalizeRelativePath('aaa/../../..'), '../..')

is(utils.resolveRelativePath('ccc', 'aaa/bbb'), 'aaa/bbb/ccc')
is(utils.resolveRelativePath('../ccc', 'aaa/bbb'), 'aaa/ccc')
