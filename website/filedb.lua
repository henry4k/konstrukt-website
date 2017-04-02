local FileDb = {}
FileDb.__index = FileDb

function FileDb:createOrReplaceFile( sourceFile, resultFile )
    assert(self.bySourceFile[sourceFile] == self.byResultFile[resultFile],
           'Existing source and result files refer are not a pair.')

    local fileInfo = { sourceFile = sourceFile,
                       resultFile = resultFile,
                       dependsOn = {},
                       requiredBy = {} }

    local oldFileInfo = self.bySourceFile[sourceFile]
    if oldFileInfo then
        for dependency in pairs(oldFileInfo.dependsOn) do
            self:removeDependency(fileInfo, dependency)
        end
        fileInfo.requiredBy = oldFileInfo.requiredBy
    end

    self.bySourceFile[sourceFile] = fileInfo
    self.byResultFile[resultFile] = fileInfo
    return fileInfo
end

function FileDb:removeFile( fileInfo )
    for dependency in pairs(fileInfo.dependsOn) do
        self:removeDependency(fileInfo, dependency)
    end
    assert(not next(fileInfo.requiredBy),
           'File is still required by other files.')
    self.bySourceFile[fileInfo.sourceFile] = nil
    self.byResultFile[fileInfo.resultFile] = nil
end

function FileDb:createDependency( fileInfoA, fileInfoB )
    fileInfoA.dependsOn[fileInfoB]  = true
    fileInfoB.requiredBy[fileInfoA] = true
end

function FileDb:removeDependency( fileInfoA, fileInfoB )
    assert(fileInfoA.dependsOn[fileInfoB] and fileInfoB.requiredBy[fileInfoA],
           'No such dependency.')
    fileInfoA.dependsOn[fileInfoB]  = nil
    fileInfoB.requiredBy[fileInfoA] = nil

    if not next(fileInfoB.requiredBy) then
        self:removeFile(fileInfoB)
    end
end

-- FileDb:write( fileName )
-- FileDb:read( fileName )

return function()
    local self = setmetatable({}, FileDb)
    self.bySourceFile = {}
    self.byResultFile = {}
    return self
end
