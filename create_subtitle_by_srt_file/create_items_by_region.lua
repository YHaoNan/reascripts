local LOG_ENABLED = false
function log(msg)
    if LOG_ENABLED then
        reaper.ShowConsoleMsg(tostring(msg).."\n")
    end
end

local num_regions, _ = reaper.CountProjectMarkers( 0 )
log("Regions => " .. num_regions)

local num_selected_tracks = reaper.CountSelectedTracks( 0 )
log("Selected tracks => " .. num_selected_tracks)


for i=0, num_regions do
  retval, isrgn, pos, rgnend, name, index = reaper.EnumProjectMarkers(i)
  if isrgn then
    for j=0, num_selected_tracks - 1 do
      track = reaper.GetSelectedTrack(0, j)
      midi_item = reaper.CreateNewMIDIItemInProj(track, pos, rgnend)
      midi_item_take = reaper.GetMediaItemTake(midi_item, 0)
      reaper.GetSetMediaItemTakeInfo_String(midi_item_take, "P_NAME", name, true)
      reaper.TrackFX_CopyToTake(track, 0, midi_item_take, 0, false)
    end
  end
end
