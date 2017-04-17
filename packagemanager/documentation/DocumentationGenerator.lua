local lustache  = require 'lustache'
local FS        = require 'packagemanager/FS'
local TreeView  = require 'packagemanager/TreeView'
local Utils     = require 'packagemanager/documentation/Utils'
local Markdown  = require 'packagemanager/documentation/Markdown'
local Document  = require 'packagemanager/documentation/Document'
local Heading   = require 'packagemanager/documentation/Heading'
local Media     = require 'packagemanager/documentation/Media'
local Reference = require 'packagemanager/documentation/Reference'


local function RenderDocument( templateHtml,
                               rootNode,
                               headingTree )
    local contentHtml = Markdown.render(rootNode)
    local title = headingTree[1].name

    local model =
    {
        title = Utils.stripHtmlTags(title),
        menu =
        {
            { name = 'Showcase', url = '' },
            { name = 'Downloads', url = '' },
            { name = 'Packages', url = '' }
        },
        content = contentHtml,
        index = headingTree[1].children
    }

    return lustache:render(templateHtml, model)
end

local function Generate( sourceTree, resultTree )
    local mediaFiles = {}
    local templateHtml = FS.readFile('template.html')

    for sourceFileName, rootNode in Document.iterSourceTree(sourceTree) do
        local sourceDir = FS.dirName(sourceFileName)

        local headingProcessor = Heading.createProcessor()
        local referenceProcessor = Reference.createProcessor(sourceDir)
        local mediaProcessor = Media.createProcessor(sourceDir)

        Markdown.process(rootNode, { headingProcessor,
                                     referenceProcessor,
                                     mediaProcessor })

        Media.addMediaFiles(mediaFiles, mediaProcessor.mediaFiles)

        -- Generate HTML:
        local html = RenderDocument(templateHtml,
                                    rootNode,
                                    headingProcessor.headingTree)
        local resultFileName = FS.stripExtension(sourceFileName)..'.html'
        local resultFile = resultTree:openFile(resultFileName, 'w')
        resultFile:write(html)
        resultFile:close()
    end

    Media.processMediaFiles(mediaFiles, sourceTree, resultTree)
end

return { generate = Generate }
