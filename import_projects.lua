-- Need to figure out how to ensure dependencies
-- 1. SWS extensions
-- 2. Custom stopgo function


-- Todo: Configure Tracks (Start from a template?)
-- Todo: Configure Template(s)

-- Load each project and concatenate tracks with regions and tempo maps
local dir = "/Users/sethcenterbar/ReaperHacking/"
project_files = {
    dir .. "song2/song2.RPP",
    dir .. "song3/song3.RPP",
}


    -- Copy tempo map from the original project
function getTempoMap(project)
    numTempos = reaper.CountTempoTimeSigMarkers(project)
    tempoMarkers = {}
    for i = 0, numTempos - 1 do
        local retval, timepos, measurepos, beatpos, bpm, timesig_num, timesig_denom, lineartempo = reaper.GetTempoTimeSigMarker(project, i)
        table.insert(tempoMarkers, {timepos, bpm, timesig_num, timesig_denom, lineartempo})
    end
    return tempoMarkers
end

function setTempoMap(current_position, tempoMarkers, targetProject)
    -- Paste the copied tempo map

    for _, marker in ipairs(tempoMarkers) do
        reaper.SetTempoTimeSigMarker(targetProject, -1, marker[1] + current_position, -1, -1, marker[2], marker[3], marker[4], marker[5], false)
    end
end

local date_string = os.date("%Y-%m-%d_%H-%M-%S")

local setlist = dir .. "setlists/" .. date_string .. "setlist.rpp"
reaper.Main_OnCommand(40859, 0)  -- New Project Tab

-- Configure Setlist Project
-- Set the timebase 
reaper.SNM_SetIntConfigVar("itemtimelock", 0)
reaper.SNM_SetIntConfigVar("tempoenvtimelock", 0)

reaper.Main_SaveProjectEx("setlist", setlist, 0)

for index, project in ipairs(project_files) do
    reaper.Main_openProject("noprompt:" .. project)

    local focus_command_id = reaper.NamedCommandLookup("_BR_FOCUS_ARRANGE_WND")
    reaper.Main_OnCommand(focus_command_id, 0) -- Focus arrange window before select & copy
    reaper.Main_OnCommand(40035, 0) -- Select all items in the current project
    reaper.Main_OnCommand(40698, 0) -- Copy all selected items

    tempoMap = getTempoMap(project)

    reaper.Main_openProject("noprompt:" .. setlist)

    local region_start = reaper.GetCursorPositionEx(setlist)

    reaper.Main_OnCommand(40043, 0)  -- Go to the end of the project
    setTempoMap(region_start, tempoMap, setlist)
    reaper.Main_OnCommand(41748, 0)  -- Paste items
    
    local region_end = reaper.GetCursorPositionEx(setlist)

    -- Pull project name from filepath for region name
    local filename_with_extension = project:match("^.+/(.+)$")
    local project_name = filename_with_extension:gsub("%.RPP$", "")
    reaper.AddProjectMarker(setlist, true, region_start, region_end, project_name, index)

    stop_and_go_cmd = reaper.NamedCommandLookup("_5be53a17badd48e39dcbc5f1482d9f49")
    -- Add Stop Marker that stops playback and moves playhead to next region
    reaper.AddProjectMarker(setlist, false, region_end - 1, 0, "!" .. stop_and_go_cmd, index)

    reaper.Main_SaveProjectEx("setlist", setlist, 0)
end

reaper.Main_OnCommand(40042, 0)  -- Go to the start of the project
reaper.Main_SaveProjectEx("setlist", setlist, 0)

-- Horizontally zoom out until everything fits
reaper.Main_OnCommand(40296, 0) -- View: Zoom out project

-- Vertically zoom out until all tracks fit
reaper.Main_OnCommand(40295, 0) -- View: Zoom out project vertically

-- reaper.ShowConsoleMsg(region_end .. "\n")
