local mod = require 'core/mods'


-- -------------------------------------------------------------------------
-- UTILS: MIDI IN

local function send_midi_msg(msg)
  local data = midi.to_data(msg)
  local is_affecting = false

  -- midi in
  for _, dev in pairs(midi.devices) do
    if dev.port ~= nil and dev.name == 'virtual' then
      if midi.vports[dev.port].event ~= nil then
        midi.vports[dev.port].event(data)
        break
      end
    end
  end
end

local function note_on(note_num, vel)
  local msg = {
    type = 'note_on',
    note = note_num,
    vel = vel,
    ch = 1,
  }
  return send_midi_msg(msg)
end

local function note_off(note_num)
  local msg = {
    type = 'note_off',
    note = note_num,
    vel = 100,
    ch = 1,
  }
  return send_midi_msg(msg)
end


-- -------------------------------------------------------------------------
-- UTILS: OSC IN

-- OSC input
local osc_vel  = nil
local osc_note = nil
local function script_osc_in(path, args, from)

  if string.find(path, 'Velocity') ~= nil then
    osc_vel  = args[1]    -- Ableton Connection Kit sends velocity before note, so we
    osc_note = nil        -- 1. Erase previous note upon receiving new velocity.

  elseif string.find(path, 'Note') ~= nil then
    osc_note = args[1]    -- 2. Update note value upon receiving it.

  end

  if osc_note ~= nil then -- 3. Trigger a complete note.

    -- Note on
    if osc_vel > 0 then
      note_on(osc_note, osc_vel)

      -- Note off
    else
      note_off(osc_note) -- Note off

    end
  end
end


-- -------------------------------------------------------------------------
-- MAIN

mod.hook.register("script_pre_init", "osc-in-midi", function()
                    local script_init = init
                    init = function ()
                      script_init()

                      print("mod - osc-in-midi - init")
                      osc.event = script_osc_in
                    end
end)
