#!/usr/bin/env lua5.2
local cmark = require 'cmark'

---
-- @return
--
-- A list of comments, which have these properties:
-- - text
-- - subject
-- - fileName
-- - firstLine
-- - lastLine
local function ReadComments( fileName )
    local comments = {}
    local file = io.open(fileName, 'r')
    local comment = nil
    local lineNumber = 0

    local function completeComment( subject )
        comment.subject = subject
        comment.lastLine = lineNumber
        table.insert(comments, comment)
        comment = nil
    end

    for line in file:lines() do
        lineNumber = lineNumber + 1
        if not comment then
            local text = line:match('^%s*%-%-%-%s*(.-)$')
            if text then
                comment = { lines = {text},
                            subject = nil,
                            fileName = fileName,
                            firstLine = lineNumber,
                            lastLine = nil }
            end
        else
            local text = line:match('^%s*%-%-%s*(.-)$')
            if text then
                table.insert(comment.lines, text)
            else
                completeComment(line:match('^%s*(.-)%s*$'))
            end
        end
    end
    file:close()

    if comment then
        completeComment()
    end

    return comments
end

local function ConvertLinesToTags( comment )
    local tag = { type = 'description',
                  lines = {} }
    local tags = { tag }
    for _, line in ipairs(comment.lines) do
        local tagType, tail = line:match('^@(%w+)(.*)$')
        if tagType then
            tag = { type = tagType,
                    lines = {tail} }
            table.insert(tags, tag)
        else
            table.insert(tag.lines, line)
        end
    end
    comment.lines = nil
    comment.tags = tags
end

local function ProcessTags( )

local srcFileName = arg[1]
local comments = ReadComments(srcFileName)
local mm = require 'mm'
for _, comment in ipairs(comments) do
    ConvertLinesToTags(comment)
    mm(comment)
end
