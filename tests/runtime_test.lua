-- Event/timer integration test with public/secret sentinels; no game client.
local now, frames, timers, sounds, count = 0, {}, {}, 0, 0
local secret = {}
local cooldown = {duration=1.5, modRate=1}
local ns = {}
local units, plates = {}, {}
local knowsVisceral, rejectOverlay, knowsReaping = true, false, false
local soundFiles = {}
function UnitIsPlayer(unit) return units[unit].player or false end
function UnitCanAttack(_,unit) return units[unit].attackable ~= false end
function UnitIsDeadOrGhost(unit) return units[unit].dead or false end
function UnitAffectingCombat(unit) return units[unit].combat end
C_NamePlate = {GetNamePlates=function() return plates end}
local function eq(a, b, message)
    assert(a == b, message .. ": " .. tostring(a) .. " ~= " .. tostring(b))
    count = count + 1
end
function GetTime() return now end
function issecretvalue(v) return rawequal(v, secret) end
function CreateFrame()
    local f = {events={}}
    function f:RegisterEvent(e)
        if rejectOverlay and e == "SPELL_ACTIVATION_OVERLAY_SHOW" then error("unavailable event") end
        self.events[e] = true
    end
    function f:RegisterUnitEvent(e, unit) self.events[e] = unit end
    function f:UnregisterEvent(e) self.events[e] = nil end
    function f:UnregisterAllEvents() self.events = {} end
    function f:SetScript(name, fn) self[name] = fn end
    frames[#frames+1] = f
    return f
end
C_Timer = {}
function C_Timer.NewTimer(delay, fn)
    local t = {at=now+delay, fn=fn}
    function t:Cancel() self.cancelled = true end
    timers[#timers+1] = t
    return t
end
local function advance(to)
    while true do
        local earliest
        for _, t in ipairs(timers) do
            if not t.cancelled and not t.fired and t.at <= to and (not earliest or t.at < earliest.at) then earliest=t end
        end
        if not earliest then break end
        now, earliest.fired = earliest.at, true
        earliest.fn()
    end
    now = to
end
local function pending()
    local n=0
    for _, t in ipairs(timers) do if not t.cancelled and not t.fired then n=n+1 end end
    return n
end
C_Spell = {GetSpellCooldown=function(id) eq(id,61304,"only inspect public GCD"); return cooldown end}
C_SpellBook = {IsSpellKnown=function(id)
    if id == 434157 then return knowsVisceral end
    if id == 377514 or id == 343294 then return knowsReaping end
    return true
end}
LycheeBlightfall = {eligible=true}
LycheeBlightfallDB = {textLead=0/0, soundLead=99, x=math.huge,reaperEnabled=false}
local media = {sounds={}}
function media:Register(_, name, path) self.sounds[name]=path end
function media:Fetch(_, name) return self.sounds[name] end
function LibStub() return media end
function PlaySoundFile(path) sounds = sounds+1; soundFiles[#soundFiles+1]=path end
PlaySound = PlaySoundFile
ns.Display = {Hide=function(self) self.target=nil; self.action=nil end,
    Show=function(self, at, action) self.target=at; self.action=action end, Apply=function() end,
    SetUnlocked=function(self, unlocked) self.unlocked=unlocked end}
ns.SettingsUI = {Register=function(self) self.registered=true end,
    Refresh=function() end, Open=function() end}
assert(loadfile("addon/LycheeBlightfall_Core/Engine.lua"))("LycheeBlightfall_Core",ns)
assert(loadfile("addon/LycheeBlightfall_Core/Enemies.lua"))("LycheeBlightfall_Core",ns)
assert(loadfile("addon/LycheeBlightfall_Core/Runtime.lua"))("LycheeBlightfall_Core",ns)
local f = frames[1]
local function event(name, ...)
    if f.events[name] then f.OnEvent(f,name,...) end
end
local function cast(id, guid) event("UNIT_SPELLCAST_SUCCEEDED","player",guid,id) end
event("ADDON_LOADED","LycheeBlightfall_Core")
eq(ns.db.textLead,3,"NaN setting reset")
eq(ns.db.soundLead,3,"out-of-range lead reset")
eq(ns.db.x,0,"infinite position reset")
eq(ns.SettingsUI.registered,true,"native settings registered")
eq(pending(),0,"idle no timers")
eq(f.events.SPELL_UPDATE_COOLDOWN,nil,"idle no cooldown events")
cast(1233448,"dt1")
eq(pending(),1,"one scheduled wake")
eq(f.events.SPELL_UPDATE_COOLDOWN,true,"GCD listener armed")
advance(9)
eq(ns.Display.target,12,"default 3 sec text lead")
eq(sounds,1,"default 3 sec sound lead")
advance(10)
cast(47541,"coil1")
eq(ns.Display.target,13,"visible target updates after coil")
cast(47541,"coil1")
eq(ns.Display.target,13,"dedup in runtime")
eq(sounds,1,"extension never repeats voice")
cast(1271967,"bf1")
eq(ns.Display.target,nil,"cast clears text")
eq(pending(),0,"cast cancels pending work")
eq(f.events.SPELL_UPDATE_COOLDOWN,nil,"cast unregisters cooldown")
advance(30)
cast(1233448,"dt2")
local stale=timers[#timers]
event("PLAYER_REGEN_ENABLED")
stale.fn() -- Cancellation race: old callback must not resurrect the cycle.
eq(ns.Display.target,nil,"stale timer cannot show text")
eq(pending(),0,"combat end no timers")
cast(1233448,"dt3")
cast(secret,"secret-event")
eq(pending(),0,"secret cast abandons uncertain inference")
cast(1233448,"dt4")
cast(47541,secret)
eq(pending(),0,"secret GUID safe")
cooldown={duration=secret,modRate=1}
cast(1233448,"dt5")
advance(39)
eq(ns.Display.target,42,"secret GCD uses fallback")
LycheeBlightfall.SetEligible(false)
eq(next(f.events),nil,"wrong spec unregisters all runtime events")
eq(pending(),0,"wrong spec no timers")
eq(ns.Display.target,nil,"wrong spec hides text")
LycheeBlightfall.SetEligible(true)
eq(f.events.UNIT_SPELLCAST_SUCCEEDED,"player","re-enable player events")
ns.db.textEnabled,ns.db.soundEnabled=false,false
ns.ApplySettings()
eq(next(f.events),nil,"both outputs off stops runtime")
ns.ResetSettings()
eq(ns.db.reaperEnabled,true,"reset enables the new reminder")
ns.db.reaperEnabled=false -- Continue the existing Blightfall-only regression cases.
eq(f.events.UNIT_SPELLCAST_SUCCEEDED,"player","defaults re-enable")
cooldown={duration=0,modRate=1}
advance(50)
cast(1233448,"dt6")
advance(59)
eq(ns.Display.target,62,"zero GCD cannot cause zero margin")
event("PLAYER_DEAD")
eq(pending(),0,"death clears timers")
eq(ns.Display.target,nil,"death clears display")
knowsReaping=true
LycheeBlightfall.SetEligible(true)
advance(70)
cast(1233448,"dt7")
advance(71)
cast(343294,"sr7")
advance(73)
eq(ns.Display.target,76,"single target follows SR")
for i=1,3 do
    local unit="nameplate"..i
    units[unit]={combat=true}
    plates[i]={unitToken=unit}
    event("NAME_PLATE_UNIT_ADDED",unit)
end
eq(ns.Display.target,82,"third engaged plate switches current cycle to AOE")
advance(80)
eq(ns.Display.target,82,"AOE survives expired SR")
units.nameplate3.dead=true
event("UNIT_FLAGS","nameplate3")
eq(ns.Display.target,nil,"return to single after expired SR hides stale recommendation")
event("UNIT_FLAGS",secret)
eq(pending(),0,"secret nameplate event does not schedule unsafe work")
units.nameplate3.dead=false
event("UNIT_FLAGS","nameplate3")
advance(100)
cast(1233448,"dt8")
advance(109)
eq(ns.Display.target,112,"new automatic AOE cycle works")
eq(sounds,5,"AOE branch switch never repeats voice")
eq(f.events.SPELL_ACTIVATION_OVERLAY_SHOW,true,"public proc event registered for selected talent")
event("PLAYER_REGEN_ENABLED")
advance(200)
cast(1233448,"dt-visceral")
advance(209)
event("SPELL_ACTIVATION_OVERLAY_SHOW",81340)
advance(209.1)
eq(ns.Display.target,212,"AOE prepares without delaying swallow")
eq(ns.Display.action,nil,"proc preparation keeps the standard swallow prompt")
local once=sounds
cast(207317,"epidemic-visceral")
eq(ns.Display.target,213,"strength consumption and DT extension recompute together")
eq(ns.Display.action,nil,"after spending return to normal swallow text")
event("SPELL_ACTIVATION_OVERLAY_HIDE",81340)
eq(ns.Display.target,213,"expected hide after spender preserves strength")
eq(sounds,once,"proc handling never repeats voice")
event("PLAYER_REGEN_ENABLED")
advance(220)
cast(1233448,"dt-secret-overlay")
advance(229)
event("SPELL_ACTIVATION_OVERLAY_SHOW",81340)
event("SPELL_ACTIVATION_OVERLAY_HIDE",secret)
eq(ns.Display.target,232,"secret overlay drops optional preparation, not the whole cycle")
event("SPELL_ACTIVATION_OVERLAY_SHOW",81340)
event("SPELL_ACTIVATION_OVERLAY_HIDE",nil)
eq(ns.Display.target,232,"hide-all cannot be interpreted as a consumed proc")
eq(pending(),1,"overlay bursts keep only one pending wake")
event("PLAYER_REGEN_ENABLED")
knowsVisceral=false
LycheeBlightfall.SetEligible(true)
eq(f.events.SPELL_ACTIVATION_OVERLAY_SHOW,nil,"unselected talent removes proc listeners")
knowsVisceral=true
rejectOverlay=true
LycheeBlightfall.SetEligible(true)
eq(f.events.SPELL_ACTIVATION_OVERLAY_SHOW,nil,"failed registration degrades gracefully")
eq(f.events.SPELL_ACTIVATION_OVERLAY_HIDE,nil,"partial event registration rolled back")
advance(240)
cast(1233448,"dt-unavailable")
advance(249)
eq(ns.Display.target,252,"unavailable proc events retain baseline reminder")

-- New dual-reminder behavior: actual casts, one timer, both branches.
event("PLAYER_REGEN_ENABLED")
ns.db.reaperEnabled=true
local initialSounds=sounds
advance(300)
cast(1297761,"heart-reaper-aoe")
cast(1233448,"dt-reaper-aoe")
advance(307.9)
eq(ns.Display.target,nil,"Heart Reaper waits for lead")
advance(308)
eq(ns.Display.action,"reaper","AOE shares Heart timing")
eq(ns.Display.target,311,"Heart plus eleven seconds")
eq(sounds,initialSounds+1,"Reaper audio once")
advance(308.5)
cast(207317,"aoe-extension")
eq(ns.Display.target,311,"extension leaves Reaper fixed")
advance(309)
cast(343294,"aoe-sr")
eq(ns.Display.target,nil,"actual Reaper removes prompt")
advance(310)
eq(ns.Display.target,313,"AOE swallow still uses DT tail")
eq(sounds,initialSounds+2,"swallow voice separate")
event("PLAYER_REGEN_ENABLED")
event("NAME_PLATE_UNIT_REMOVED","nameplate2")
event("NAME_PLATE_UNIT_REMOVED","nameplate3")
advance(330)
cast(1297761,"heart-reaper-st")
cast(1233448,"dt-reaper-st")
advance(338)
eq(ns.Display.action,"reaper","ST delayed Heart cue")
eq(ns.Display.target,341,"same Heart rule in ST")
advance(339)
eq(ns.Display.action,"reaper","no false swallow before actual Reaper")
advance(341)
cast(343294,"sr-heart-st")
eq(ns.Display.target,nil,"Reaper success clears cue")
advance(343)
eq(ns.Display.target,346,"swallow follows actual cast plus eight minus two GCDs")
advance(344)
cast(47541,"st-extension")
eq(ns.Display.target,346,"ST swallow ignores DT extension")
event("PLAYER_REGEN_ENABLED")
cooldown={duration=1.5,modRate=1,startTime=359}
advance(360)
initialSounds=sounds
cast(1233448,"dt-immediate-st")
eq(ns.Display.action,nil,"no Heart ST waits for default threshold")
eq(ns.Display.target,nil,"no premature ST cue")
eq(sounds,initialSounds,"no early ST voice")
advance(361)
cast(343294,"sr-immediate")
advance(363)
eq(ns.Display.target,366,"early SR still produces swallow reminder")
eq(sounds,initialSounds+1,"manual early SR cancels pending Reaper voice")
event("PLAYER_REGEN_ENABLED")
cooldown={duration=1.5,modRate=1,startTime=secret}
advance(390)
cast(1233448,"dt-missed-sr")
eq(ns.Display.target,nil,"secret GCD cannot advance default ST timing")
advance(399)
eq(ns.Display.action,"reaper","missing SR never triggers fictitious ST swallow")
eq(pending(),1,"waiting retains one expiry timer")
advance(405)
eq(ns.Display.target,nil,"missed SR expires")
eq(pending(),0,"no timers after expiry")
for i=2,3 do event("NAME_PLATE_UNIT_ADDED","nameplate"..i) end
advance(410)
cast(1233448,"dt-immediate-aoe")
eq(ns.Display.action,"reaper","AOE without Heart is immediate too")
event("PLAYER_REGEN_ENABLED")
knowsReaping=false
LycheeBlightfall.SetEligible(true)
advance(430)
cast(1233448,"dt-no-talents")
advance(439)
eq(ns.Display.target,442,"without Reaping fallback uses DT")
event("PLAYER_REGEN_ENABLED")
eq(pending(),0,"reset clears all work")
print("Runtime assertions passed: " .. count)
