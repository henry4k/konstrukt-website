local lfs = require 'lfs'


local function IsUrlLocalPath( url )
    return not string.match(url, '^.-://')
end

local function StripHtmlTags( html )
    return string.gsub(html, '<.->', '')
end

-- luacheck: push ignore 542
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
-- luacheck: pop

local function ResolveRelativePath( path, basePath )
    local relativePath
    if basePath then
        relativePath = basePath..'/'..path
    else
        relativePath = path
    end
    return CanonicalizeRelativePath(relativePath)
end

local function DirectoryTree( filePath, prefix )
    prefix = prefix or ''
    local function yieldTree( directory )
        for entry in lfs.dir(prefix..directory) do
            if entry ~= '.' and entry ~= '..' then
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

return { isUrlLocalPath = IsUrlLocalPath,
         stripHtmlTags = StripHtmlTags,
         canonicalizeRelativePath = CanonicalizeRelativePath,
         resolveRelativePath = ResolveRelativePath,
         directoryTree = DirectoryTree }
