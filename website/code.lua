local cmark = require 'cmark'



local function HighlightCode( language, code )
    return table.concat({'<pre>', '</pre>'})
end

local function HighlightCodeBlocks( document )
    for node, entering, nodeType in cmark.walk(document) do
        if nodeType == cmark.NODE_CODE_BLOCK and entering then
            local language = cmark.node_get_fence_info(node)
            local code = cmark.node_get_literal(node)

            local html = HighlightCode(language, code)

            local newNode = cmark.node_new(cmark.NODE_HTML_BLOCK)
            cmark.node_set_literal(newNode, html)

            assert(cmark.node_replace(node, newNode))
        end
    end
end

return { highlightCodeBlocks = HighlightCodeBlocks }
