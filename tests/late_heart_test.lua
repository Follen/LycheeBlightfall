-- Heart and Soul Reaper are independent reasons to cue Blightfall.
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
local afterHeart = late:Update(20, options, true)
assert(afterHeart.reason == "soul_reaper" and afterHeart.deadline == 24.5,
    "active Reaper remains a Blightfall condition after Heart expires")

local missed = cycle(19)
local missedCue = missed:Update(19, options, true)
assert(missedCue.reason == "heart" and missedCue.show and missedCue.voice,
    "late Reaper must never silence the urgent Heart Blightfall cue")
assert(missed:Update(20, options, true).reason == "soul_reaper",
    "after a missed Heart, the live Reaper window still matters")

local waiting = E.New()
waiting:Cast(E.HEART, 0, "waiting-heart")
waiting:Cast(E.DT, 1, "waiting-dt")
for i = 2, 9 do waiting:Cast(47541, i, "waiting-coil" .. i) end
local beforeReaper = waiting:Update(14, options, true)
assert(beforeReaper.reason == "heart" and beforeReaper.target == 17
    and beforeReaper.show and beforeReaper.voice,
    "Heart must cue Blightfall before expiry even without a Reaper cast")
assert(waiting:Update(19, options, true).show,
    "Heart cue stays visible through the last second")
assert(waiting:Update(20, options, true).waitingReaper,
    "after Heart expires, an extended transformation may still wait for Reaper")
assert(waiting:Update(24, options, true) == nil,
    "waiting without Heart or Reaper ends with transformation")

local heartOnly = E.New()
heartOnly:Cast(E.HEART, 0, "solo-heart")
heartOnly:Cast(E.DT, 1, "solo-dt")
local soloCue = heartOnly:Update(17, options, true)
assert(soloCue.reason == "heart" and soloCue.show and soloCue.voice,
    "Heart remains an independent swallow condition after transformation expires")
assert(heartOnly:Update(20, options, true) == nil,
    "a lone Heart cue ends when both Heart and transformation have expired")

print("Late Heart assertions passed")
