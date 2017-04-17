local lfs = require 'lfs'
local FS  = require 'packagemanager/FS'


local function IsUrlLocalPath( url )
    return not string.match(url, '^.-://')
end

local function StripHtmlTags( html )
    return string.gsub(html, '<.->', '')
end

-- luacheck: push ignore 542
local function CanonicalizeRelativePath( path, dirSep )
    dirSep = dirSep or FS.dirSep
    local elements = {}
    for element in string.gmatch(path, '[^/\\]+') do
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
    return table.concat(elements, dirSep)
end
-- luacheck: pop

local function ResolveRelativePath( path, basePath, dirSep )
    dirSep = dirSep or FS.dirSep
    local relativePath
    if basePath then
        relativePath = basePath..dirSep..path
    else
        relativePath = path
    end
    return CanonicalizeRelativePath(relativePath)
end

return { isUrlLocalPath = IsUrlLocalPath,
         stripHtmlTags = StripHtmlTags,
         canonicalizeRelativePath = CanonicalizeRelativePath,
         resolveRelativePath = ResolveRelativePath }
