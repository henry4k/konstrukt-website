#!/usr/bin/env lua5.2
local convert = require 'website/convert'
local FS = require 'website/fs'
local FileDb = require 'website/filedb'

local cfg =
{
    sourceTreeRoot = arg[1],
    resultTreeRoot = arg[2],
    templateHtml = FS.readFile('template.html')
}

local fileDb = FileDb()

convert.convertTree(cfg, fileDb)
