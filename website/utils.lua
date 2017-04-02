local lfs = require 'lfs'


local function StripHtmlTags( html )
    return string.gsub(html, '<.->', '')
end

local function CanonicalizeRelativePath( path )
    local elements = {}
    for element in string.gmatch(path, '[^/]+') do
        if element == '.' then
            -- ignore
        elseif element == '..' and
               #elements > 0 and
               elements[#elements] ~= '..' then
            table.remove(elements) -- pop last entry
        else
            table.insert(elements, element)
        end
    end
    return table.concat(elements, '/')
end

local function DirectoryTree( filePath, prefix )
    prefix = prefix or ''
    local function yieldTree( directory )
        for entry in lfs.dir(prefix..directory) do
            if entry == '.' or entry == '..' then
                -- ignore
            else
                local entryPath
                if directory == '' then
                    entryPath = entry
                else
                    entryPath = directory..'/'..entry
                end
                coroutine.yield(entryPath)
                if lfs.attributes(prefix..entryPath, 'mode') == 'directory' then
                    yieldTree(entryPath)
                end
            end
        end
    end
    return coroutine.wrap(function() yieldTree(filePath) end)
end

return { stripHtmlTags = StripHtmlTags,
         canonicalizeRelativePath = CanonicalizeRelativePath,
         directoryTree = DirectoryTree }
