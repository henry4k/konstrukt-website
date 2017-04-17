#!/usr/bin/env lua5.2
local TreeView = require 'packagemanager/TreeView'
local DocumentationGenerator = require 'packagemanager/documentation/DocumentationGenerator'

local sourceTree = TreeView(arg[1])
local resultTree = TreeView(arg[2])
DocumentationGenerator.generate(sourceTree, resultTree)
