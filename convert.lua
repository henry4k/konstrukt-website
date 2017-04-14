#!/usr/bin/env lua5.2
local DocumentationGenerator = require 'packagemanager/documentation/DocumentationGenerator'

local sourceTree = arg[1]
local resultTree = arg[2]
DocumentationGenerator.generate(sourceTree, resultTree)
