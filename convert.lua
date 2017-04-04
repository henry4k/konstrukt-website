#!/usr/bin/env lua5.2
local convert = require 'website/convert'
local FS = require 'website/fs'
local FileDb = require 'website/filedb'
local lfs = require 'lfs'

local cfg =
{
    sourceTreeRoot = arg[1],
    resultTreeRoot = arg[2],
    templateHtml = FS.readFile('template.html')
}

--for entry in lfs.dir(cfg.resultTreeRoot) do
--    if entry ~= '.' and entry ~= '..' then
--        local entryPath = FS.path(cfg.resultTreeRoot, entry)
--        print('deleting', entryPath)
--        --FS.recursiveDelete(entryPath)
--    end
--end

local fileDb = FileDb()
convert.convertTree(cfg, fileDb)
