-- A late Soul Reaper must not schedule single-target Blightfall after Heart fades.
local ns = {}
assert(loadfile("addon/LycheeBlightfall_Core/Engine.lua"))("Test", ns)
local E = ns.Engine
local options = {textEnabled=true, soundEnabled=true, textLead=3, soundLead=3, reaperEnabled=true}

local function cycle(reaperAt)
    local engine = E.New()
    engine:Cast(E.HEART, 0, "heart")
    engine:Cast(E.DT, 1, "dt")
    for i = 2, 5 do engine:Cast(47541, i, "coil" .. i) end
    engine:Cast(E.REAPER, reaperAt, "reaper")
    return engine
end

local onTime = cycle(11)
assert(onTime:Update(11, options, true).target == 16,
    "on-time Reaper keeps the existing Soul Reaper tail")

local late = cycle(16.5)
local cue = late:Update(16.5, options, true)
assert(cue.reason == "heart" and cue.target == 17,
    "late Reaper must bring the swallow cue forward to the remaining Heart window")
assert(cue.show and cue.voice, "late cast must alert immediately when the lead time has passed")
local fallback = late:Update(20.1, options, true)
assert(fallback and fallback.reason == "soul_reaper" and fallback.target == 21.5,
    "after Heart fades, an unused Soul Reaper gets its remaining fallback window")

local missed = cycle(19)
local missedCue = missed:Update(19, options, true)
assert(missedCue.reason == "soul_reaper" and missedCue.target == 24,
    "do not promise Heart if the post-Reaper GCD already outlasts it")

print("Late Heart assertions passed")
