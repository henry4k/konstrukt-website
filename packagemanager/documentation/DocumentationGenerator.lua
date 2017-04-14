local Misc = require 'packagemanager/Misc'
local Utils = require 'packagemanager/documentation/Utils'
local FS = require 'packagemanager/FS'
local Markdown = require 'packagemanager/documentation/Markdown'
local lustache = require 'lustache'


local MediaHandlers =
{
    png = function( node )
        -- Nothing to do here
    end,

    webm = function( node )
        error('WebM is not supported yet.')
    end
}

local DocumentParsers =
{
    md = function( fileContent )
        return Markdown.parse(fileContent)
    end,

    lua = function( fileContent )
        error('Parsing Lua is not supported yet.')
    end
}

local function IterDocuments( sourceTree )
    return coroutine.wrap(function()
        for filePath in Utils.directoryTree('', sourceTree..FS.dirSep) do
            local extension = FS.extension(filePath)
            local parser = DocumentParsers[extension]
            if parser then
                local absFilePath = FS.path(sourceTree, filePath)
                local fileContent = FS.readFile(absFilePath)
                local rootNode = parser(fileContent)
                coroutine.yield(filePath, rootNode)
            end
        end
    end)
end

local function IsUrlLocalPath( url )
    return not string.match(url, '^.-://')
end

local function ResolveReference( sourceDir, reference )
    -- - Aus einem Verweis innerhalb des Quell-Baumes wird ein Verweis
    --   innerhalb des Ziel-Baumes
    --   - z.B. `.md` zu `.html`
    -- - Referenzen auf Dokumente werden geprüft
    -- - Lokale Referenzen nur zu Dokumenten und bestimmten Mediendateien erlauben
    --   - `.png`, `.svg`, `.webm`, ... ?
    --   - Mediendateien grob prüfen (sollten nicht zu groß sein)
    -- - Externe Referenzen nur in Links erlauben

    local url = reference.url
    if IsUrlLocalPath(url) then
        local extension = FS.extension(url)

        if reference.type == 'media' then
            if not MediaHandlers[extension] then
                error('File type is not supported in a media element.')
            end
        else
            if not DocumentParsers[extension] and
               not MediaHandlers[extension] then
               error('File type is not allowed as link target.')
           end
        end

        if DocumentParsers[extension] then
            url = FS.stripExtension(url)..'.html'
        end

        if url:match('^/') then
            error('Can\'t handle absolute paths yet.')
        else
            url = Utils.resolveRelativePath(url, sourceDir)
            reference.fileName = url
            if url:match('^%.%./') then
                error('Relative paths may not leave the package directory.')
            end
        end
    else
        if reference.type == 'media' then
            error('External media is not allowed.')
        end
    end
    reference.url = url
end

local function RenderDocument( templateHtml, sourceFileName, document )
    local contentHtml = Markdown.render(document.rootNode)
    local title = document.headingTree[1].name

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
        index = document.headingTree[1].children
    }

    return lustache:render(templateHtml, model)
end

local function GatherReferencedMediaFiles( documents )
    local mediaFiles = {}
    for _, document in pairs(documents) do
        for _, reference in ipairs(document.references) do
            if reference.fileName then
                local extension = FS.extension(reference.fileName)
                if MediaHandlers[extension] then
                    -- TODO: Whats about absolute file paths?
                    mediaFiles[reference.fileName] = true
                end
            end
        end
    end
    return mediaFiles
end

local function Generate( sourceTree, resultTree )
    -- Quell-Baum durchlaufen und alle Dokumente einlesen
    local documents = {}
    for sourceFileName, rootNode in IterDocuments(sourceTree) do
        local headingTree, headingList = Markdown.locateHeadings(rootNode)
        local references = Markdown.locateReferences(rootNode)
        documents[sourceFileName] = { rootNode = rootNode,
                                      headingTree = headingTree,
                                      headingList = headingList,
                                      references = references }
    end

    -- Fragmente generieren
    for _, document in pairs(documents) do
        Markdown.generateFragments(document.headingList)
    end

    -- Referenzen auflösen
    for sourceFileName, document in pairs(documents) do
        local sourceDir = FS.dirName(sourceFileName)
        for _, reference in ipairs(document.references) do
            ResolveReference(sourceDir, reference)
        end
    end

    -- Dokumente als HTML gerendert in den Ziel-Baum schreiben
    local templateHtml = FS.readFile('template.html')
    for sourceFileName, document in pairs(documents) do
        local html = RenderDocument(templateHtml, sourceFileName, document)
        local resultFileName = FS.stripExtension(sourceFileName)..'.html'
        local absResultFileName = FS.path(resultTree, resultFileName)
        FS.makeDirectoryPath(resultTree, FS.dirName(resultFileName))
        FS.writeFile(absResultFileName, html)
    end

    -- Lokale referenzierte Mediendateien finden und in den Ziel-Baum kopieren
    local mediaFiles = GatherReferencedMediaFiles(documents)
    for fileName in pairs(mediaFiles) do
        FS.makeDirectoryPath(resultTree, FS.dirName(fileName))
        local sourceFile = assert(io.open(FS.path(sourceTree, fileName), 'rb'))
        local resultFile = assert(io.open(FS.path(resultTree, fileName), 'wb'))
        Misc.writeFile(resultFile, sourceFile)
        sourceFile:close()
        resultFile:close()
    end
end


return { generate = Generate,
         resolveReference = ResolveReference }
