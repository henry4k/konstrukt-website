local lfs = require 'lfs'


local FS = {}

FS.dirSep = package.config:sub(1,1)
if not FS.dirSep:match('[/\\]') then
    FS.dirSep = '/'
    io.stderr:write('Failed to get directory separator.  Assuming "/"')
end

function FS.path( ... )
    local elements = {...}
    for i = 2, #elements do
        assert(FS.isRelativePath(elements[i]))
    end
    return table.concat(elements, FS.dirSep)
end

function FS.isAbsolutePath( filePath )
    return filePath:match('^/') or filePath:match('^.:\\')
end

function FS.isRelativePath( filePath )
    return not FS.isAbsolutePath(filePath)
end

function FS.makeAbsolutePath( filePath, baseDir )
    if FS.isRelativePath(filePath) then
        baseDir = baseDir or FS.getCurrentDirectory()
        assert(FS.isAbsolutePath(baseDir))
        return FS.path(baseDir, filePath)
    else
        return filePath
    end
end

function FS.dirName( filePath )
    return filePath:match('^(.+)[/\\]') or '.'
end

function FS.baseName( filePath )
    return filePath:match('([^/\\]+)$')
end

function FS.extension( filePath )
    return filePath:match('%.([^./\\]+)$')
end

function FS.stripExtension( filePath )
    return filePath:match('(.+)%.[^./\\]*$') or filePath
end

function FS.fileExists( fileName )
    return lfs.attributes(fileName, 'mode') ~= nil
end

function FS.readFile( fileName )
    local file = assert(io.open(fileName, 'r'))
    local content = file:read('*a')
    file:close()
    return content
end

function FS.writeFile( fileName, content )
    local file = assert(io.open(fileName, 'w'))
    file:write(content)
    file:close()
end

function FS.parseFileName( fileName )
    local path, pathEnd = fileName:match('^(.*)[/\\]()')
    pathEnd = pathEnd or 1
    local extensionStart, extension = fileName:match('()%.([^.]*)$', pathEnd)
    extensionStart = extensionStart or 0
    local baseName = fileName:sub(pathEnd, extensionStart-1)
    return {path=path, baseName=baseName, extension=extension}
end

function FS.recursiveDelete( filePath )
    if lfs.symlinkattributes(filePath, 'mode') == 'directory' then
        for entry in lfs.dir(filePath) do
            if entry ~= '.' and
               entry ~= '..' then
                FS.recursiveDelete(FS.path(filePath, entry))
            end
        end
    end
    return os.remove(filePath)
end

local function MakeDirIfNotExists( path )
    local mode = lfs.attributes(path, 'mode')
    if not mode then
        return lfs.mkdir(path)
    elseif mode ~= 'directory' then
        return false, 'File exists'
    else
        return true
    end
end

function FS.makeDirectoryPath( base, path )
    for seperatorPos in path:gmatch('()[/\\]') do
        local subPath = path:sub(1, seperatorPos-1)
        local success, errMsg = MakeDirIfNotExists(FS.path(base, subPath))
        if not success then
            return false, errMsg
        end
    end
    return MakeDirIfNotExists(FS.path(base, path))
end

function FS.changeDirectory( path )
    assert(lfs.chdir(path))
end

function FS.getCurrentDirectory()
    return assert(lfs.currentdir())
end

local function GetSourcePath( stackIndex )
    local info = debug.getinfo(stackIndex+1, 'S')
    if info and
       info.source and
       info.source:sub(1,1) == '@' then
        return info.source:sub(2)
    end
end

local function GetSourceDir( stackIndex )
    local sourcePath = GetSourcePath(stackIndex+1)
    if sourcePath then
        return sourcePath:match('^(.*)[/\\]')
    end
end

--- Gives the current directory or a subpath thereof.
function FS.here( subPath )
    local path = GetSourceDir(2)
    if path then
        if subPath then
            return string.format('%s%s%s', path, FS.dirSep, subPath)
        else
            return path
        end
    end
end


return FS
