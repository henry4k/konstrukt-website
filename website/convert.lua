local FS = require 'website/fs'
local utils = require 'website/utils'
local markdown = require 'website/markdown'
local fragments = require 'website/fragments'
local references = require 'website/references'
local lustache = require 'lustache'
local lfs = require 'lfs'


local Convert

local function PrepareFileConversion( cfg, fileInfo )
    local absSourceFile = FS.path(cfg.sourceTreeRoot, fileInfo.sourceFile)
    local absResultFile = FS.path(cfg.resultTreeRoot, fileInfo.resultFile)
    FS.makeDirectoryPath(cfg.resultTreeRoot, FS.dirName(fileInfo.resultFile))
    return absSourceFile, absResultFile
end

local function CopyFile( cfg, fileDb, fileInfo )
    local absSourceFile,
          absResultFile = PrepareFileConversion(cfg, fileInfo)
    FS.writeFile(absResultFile, FS.readFile(absSourceFile)) -- TODO: implement actual copy function
end

local function ConvertMarkdown( cfg, fileDb, fileInfo )
    local absSourceFile,
          absResultFile = PrepareFileConversion(cfg, fileInfo)

    local document = markdown.parse(FS.readFile(absSourceFile))
    local fragmentTree, fragmentList = fragments.generate(document)
    local referenceList = references.locate(document, fileInfo.sourceFile)

    for _, reference in ipairs(referenceList) do
        if reference.sourcePath then
            local referenceFileInfo = Convert(cfg, fileDb, reference.sourcePath)
            fileDb:createDependency(fileInfo, referenceFileInfo)
            reference.resultPath = referenceFileInfo.resultFile
            -- TODO: Adapt reference URLs (see ResolveLocalReferences)
        end
    end

    local contentHtml = markdown.render(document)

    local model =
    {
        title = utils.stripHtmlTags(fragmentTree[1].name),
        menu =
        {
            { name = 'Showcase', url = '' },
            { name = 'Downloads', url = '' },
            { name = 'Packages', url = '' }
        },
        content = contentHtml,
        index = fragmentTree[1].children
    }

    local html = lustache:render(cfg.templateHtml, model)
    FS.writeFile(absResultFile, html)
end

---
-- @param sourceFile
--
-- @return
-- 1. `resultFile` - file name in the result tree
-- 2. `converter`  - conversion function
--
local function GetConversionInfo( sourceFile )
    local extension = FS.extension(sourceFile)
    if extension == 'md' then
        return FS.stripExtension(sourceFile)..'.html', ConvertMarkdown
    else
        return sourceFile, CopyFile
    end
end

local function NotExistingOrOlder( a, b )
    return not FS.fileExists(a) or
           (assert(lfs.attributes(a, 'modification')) <
            assert(lfs.attributes(b, 'modification')))
end

---
-- @param cfg
--
-- - `sourceTreeRoot`
-- - `resultTreeRoot`
-- - `templateHtml`
--
-- @param fileDb
-- A table which has an entry for each file in the result tree:
--
-- - `sourceFile` - the corresponding file of the source tree
-- - `references` - set of referenced files in the result tree
-- - `conversionResult` - value that the conversion function returned
--
-- @param sourceFile
--
-- @return
-- The respective `fileInfo` entry from the file database.
--
Convert = function( cfg, fileDb, sourceFile )
    local resultFile, converter = GetConversionInfo(sourceFile)

    local absSourceFile = FS.path(cfg.sourceTreeRoot, sourceFile)
    local absResultFile = FS.path(cfg.resultTreeRoot, resultFile)
    if NotExistingOrOlder(absResultFile, absSourceFile) then
        local fileInfo = fileDb:createOrReplaceFile(sourceFile, resultFile)
        fileInfo.conversionResult =
            converter(cfg, fileDb, fileInfo)
        return fileInfo
    else
        return assert(fileDb.bySourceFile[sourceFile],
                      'File is in result tree, but not in db.')
    end
end

local function ConvertTree( cfg, fileDb )
    -- Start by converting all markdown files:
    for sourceFile in utils.directoryTree('', cfg.sourceTreeRoot..FS.dirSep) do
        local extension = FS.extension(sourceFile)
        if extension == 'md' then
            Convert(cfg, fileDb, sourceFile)
        end
    end

    -- TODO: Check references?

    -- Remove all superfluous files from the result tree:
    for resultFile in utils.directoryTree('', cfg.resultTreeRoot..FS.dirSep) do
        local absResultFile = FS.path(cfg.resultTreeRoot, resultFile)
        if not fileDb.byResultFile[resultFile] and
           lfs.attributes(absResultFile, 'mode') ~= 'directory' then
            assert(os.remove(absResultFile))
        end
    end
end

return { convertTree = ConvertTree }
