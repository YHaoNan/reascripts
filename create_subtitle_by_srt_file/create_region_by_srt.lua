--[[
 Requirements:
  - js_ReaScriptAPI: To open a file chooser to choose the srt file
    You can install it with Reapack or the link below:
    github: https://github.com/juliansader/ReaExtensions/tree/master/js_ReaScriptAPI/
 并不保证能够解析所有SRT，只保证解析网易见外生成的SRT
--]]

-- UTIL FUNCTIONS --
local LOG_ENABLED = false
function log(msg)
    if LOG_ENABLED then
        reaper.ShowConsoleMsg(tostring(msg).."\n")
    end
end

function string.trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

function exit(msg)
    reaper.ReaScriptError("!"..msg)
end

function assertTrue(condition, msg)
    if not condition then
        exit(msg)
    end
end

-- 输入字符串格式 hh:mm:ss,mss
-- 返回具有两位小数的数字，格式为秒.毫秒/10
function strToFloatTimePosition(str)
    h = tonumber(string.sub(str, 1, 2))
    m = tonumber(string.sub(str, 4, 5))
    s = tonumber(string.sub(str, 7, 8))
    ms = tonumber(string.sub(str, 10, 12))
    return h * 60 * 60 + m * 60 + s + (ms/10/100)
end

-- CORE LOGIC --

function chooseSrt()
    local retval, fileName = reaper.JS_Dialog_BrowseForOpenFiles(
        "选择SRT文件",nil, nil, "Srt files\0*.srt", false
    );
    
    assertTrue(retval == 1, "No srt file selected!")
    return fileName
end


function buildSubtitles(filename)
    file = io.open(filename, "r")
    assertTrue(file ~= nil, "file "..filename.." can not read, please make sure it exists and you have correct permission!")

    subtitles = {}
    curSubtitleIdx = -1

    line = file:read("l")
    while line ~= nil
    do
        -- 如果是纯数字，代表这是第几条字幕
        if string.match(line, "^%d+$") then
            curSubtitleIdx = tonumber(line) + 1
            subtitles[curSubtitleIdx] = {}
            subtitles[curSubtitleIdx]["id"] = curSubtitleIdx -1
        elseif string.match(line, "^(%d%d:%d%d:%d%d,%d%d%d)%s*-->%s*(%d%d:%d%d:%d%d,%d%d%d)$") then
            startStr, endStr = string.match(line, "^(%d%d:%d%d:%d%d,%d%d%d)%s*-->%s*(%d%d:%d%d:%d%d,%d%d%d)$")
            -- 这是时间信息
            subtitles[curSubtitleIdx]["start"] = strToFloatTimePosition(startStr)
            subtitles[curSubtitleIdx]["end"] = strToFloatTimePosition(endStr)
        elseif string.match(line, "%S+") then
            -- 这是字幕信息
            subtitles[curSubtitleIdx]["subtitle"] = line
        end
        line = file:read("l")
    end

    return subtitles
end

function createRegions(subtitles)
    for i, v in pairs(subtitles) do
        reaper.AddProjectMarker(0, 1, v["start"], v["end"], v["subtitle"], i)
    end
end

function main()
    filename = chooseSrt()
    log("Choose => " .. filename)
    subtitles = buildSubtitles(filename)
    createRegions(subtitles)
end


main()