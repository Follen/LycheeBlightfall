local addonName, ns = ...
local app = LycheeBlightfall
local engine = ns.Engine.New()
local enemies = ns.Enemies.New()
local frame = CreateFrame("Frame")
local timer, generation, active, ready, reaping = nil, 0, false, false, false
local visceral = false
local defaultSound = "荔枝：准备吞病（温暖少女）"
local soundPath = "Interface\\AddOns\\LycheeBlightfall_Core\\Media\\prepare-blightfall.ogg"
local reaperSoundPath = "Interface\\AddOns\\LycheeBlightfall_Core\\Media\\prepare-reaper.ogg"
local defaultReaperSound = "荔枝：准备收割（温暖少女）"
local defaults = { enabled = true, textEnabled = true, soundEnabled = true,
    textLead = 3, soundLead = 3, fontSize = 32, x = 0, y = 160, sound = defaultSound,
    reaperEnabled = true, reaperSound = defaultReaperSound }

local function public(value)
    return not issecretvalue(value)
end
local function cancelTimer()
    generation = generation + 1
    if timer then timer:Cancel(); timer = nil end
end
local function clearCycle()
    cancelTimer()
    engine:Reset()
    frame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
    ns.Display:Hide()
end
function ns.PlayVoice(force, action)
    if not force and not ns.db.soundEnabled then return end
    local isReaper = action == "reaper"
    local path = ns.media:Fetch("sound", isReaper and ns.db.reaperSound or ns.db.sound, true)
    if path == nil then path = isReaper and reaperSoundPath or soundPath end
    if path == "" then return end -- SharedMedia's explicit None entry.
    if type(path) == "number" then PlaySound(path, "Dialog")
    else PlaySoundFile(path, "Dialog") end
end
function ns.Refresh(refreshEnemies)
    cancelTimer()
    if not active then ns.Display:Hide(); return end
    if engine.armed and refreshEnemies ~= false then enemies:Refresh() end
    local aoe = enemies:IsAOE()
    local state = engine:Update(GetTime(), ns.db, reaping, aoe, visceral)
    if not engine.armed then frame:UnregisterEvent("SPELL_UPDATE_COOLDOWN") end
    if not state then ns.Display:Hide(); return end
    -- One line / one voice at a time. Blightfall always wins when due.
    local reaperState
    if not state.show and not state.voice and not engine.textShown and not engine.voiced then
        reaperState = engine:UpdateReaper(GetTime(), ns.db, reaping, aoe)
    end
    if reaperState then
        state.wake = math.min(state.wake, reaperState.wake)
        if reaperState.show then ns.Display:Show(reaperState.target, "reaper")
        else ns.Display:Hide() end
        if reaperState.voice then ns.PlayVoice(false, "reaper") end
    elseif state.show then
        ns.Display:Show(state.target)
    else ns.Display:Hide() end
    if state.voice then ns.PlayVoice(false) end
    if state.wake then
        local current = generation
        timer = C_Timer.NewTimer(math.max(0.001, state.wake - GetTime()), function()
            if current ~= generation then return end
            timer = nil
            ns.Refresh()
        end)
    end
end
local function observeGCD()
    local info = C_Spell.GetSpellCooldown(61304)
    if not public(info) or type(info) ~= "table" then return false end
    local duration, rate = info.duration, info.modRate
    if not public(duration) or not public(rate) then return false end
    if type(duration) ~= "number" or duration ~= duration or duration < 0 then return false end
    if duration == 0 then engine:SetReaperReady(GetTime()); return false end
    if rate == nil then rate = 1 end
    if type(rate) ~= "number" or rate <= 0 then return false end
    local now, start = GetTime(), info.startTime
    if public(start) and type(start) == "number" and start == start and start <= now then
        local ends = start + duration / rate
        if ends >= now and ends <= now + 2 then engine:SetReaperReady(ends) end
    end
    return engine:SetGCD(duration / rate, now)
end
local function activate()
    if not ready then return end
    local wanted = app.eligible and ns.db.enabled and (ns.db.textEnabled or ns.db.soundEnabled)
    local nextReaping = C_SpellBook.IsSpellKnown(377514) and C_SpellBook.IsSpellKnown(343294)
    local nextVisceral = C_SpellBook.IsSpellKnown(ns.Engine.VISCERAL_TALENT)
    if active == not not wanted and reaping == not not nextReaping
        and visceral == not not nextVisceral then return end
    active, reaping = not not wanted, not not nextReaping
    visceral = not not nextVisceral
    frame:UnregisterAllEvents()
    clearCycle()
    enemies:Clear()
    if active then
        frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("PLAYER_ENTERING_WORLD")
        frame:RegisterEvent("PLAYER_DEAD")
        frame:RegisterEvent("CHALLENGE_MODE_START")
        frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        frame:RegisterEvent("UNIT_FLAGS")
        frame:RegisterEvent("UNIT_FACTION")
        if visceral then
            -- Ordinary events, not hooks into pooled/forbidden UI objects.
            -- An unavailable registration only disables proc inference.
            local showOK = pcall(frame.RegisterEvent, frame, "SPELL_ACTIVATION_OVERLAY_SHOW")
            local hideOK = pcall(frame.RegisterEvent, frame, "SPELL_ACTIVATION_OVERLAY_HIDE")
            if not showOK or not hideOK then
                frame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_SHOW")
                frame:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_HIDE")
            end
        end
        enemies:Rebuild()
    elseif ns.Display.unlocked then
        ns.Display:SetUnlocked(false)
    end
end
function app.SetEligible(value)
    app.eligible = not not value
    activate()
    ns.SettingsUI:Refresh()
end
function ns.ApplySettings()
    -- Appearance/lead/sound edits preserve the observed casts and voice latch.
    -- activate still clears everything when monitoring is disabled.
    ns.Display:Apply()
    activate()
    ns.Refresh(false)
end
function ns.ResetSettings()
    for key, value in pairs(defaults) do ns.db[key] = value end
    ns.ApplySettings()
end
local function initialize()
    local db = type(LycheeBlightfallDB) == "table" and LycheeBlightfallDB or {}
    for key, value in pairs(defaults) do
        if type(db[key]) ~= type(value) then db[key] = value end
    end
    db.mode = nil -- Remove the abandoned manual-mode setting, if present.
    local ranges = { textLead = {0, 10}, soundLead = {0, 10}, fontSize = {18, 60},
        x = {-10000, 10000}, y = {-10000, 10000} }
    for key, limits in pairs(ranges) do
        local value = db[key]
        if value ~= value or value < limits[1] or value > limits[2] then db[key] = defaults[key] end
    end
    LycheeBlightfallDB, ns.db = db, db
    ns.media = LibStub("LibSharedMedia-3.0")
    ns.media:Register("sound", defaultSound, soundPath)
    ns.media:Register("sound", defaultReaperSound, reaperSoundPath)
    ns.SettingsUI:Register()
    ready = true
    activate()
end
frame:SetScript("OnEvent", function(_, event, unit, castGUID, spellID)
    if event == "ADDON_LOADED" then
        if unit == addonName then frame:UnregisterEvent(event); initialize() end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Never compare, format or index with a secret payload.
        if not public(unit) or not public(spellID) then clearCycle(); return end
        if unit ~= "player" or not ns.Engine.TRACKED[spellID] then return end
        if not public(castGUID) then clearCycle(); return end
        if engine:Cast(spellID, GetTime(), castGUID, visceral) then
            if engine.armed then
                frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
                observeGCD()
            end
            ns.Refresh()
        end
    elseif event == "SPELL_ACTIVATION_OVERLAY_SHOW" or event == "SPELL_ACTIVATION_OVERLAY_HIDE" then
        -- The first payload is the aura spellID here, not a unit token.
        if not public(unit) then engine:ForgetDoom()
        elseif event == "SPELL_ACTIVATION_OVERLAY_HIDE" and unit == nil then engine:ForgetDoom()
        elseif unit == ns.Engine.SUDDEN_DOOM then
            engine:Overlay(event == "SPELL_ACTIVATION_OVERLAY_SHOW", GetTime())
        else return end
        if engine.armed then ns.Refresh(false) end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        if observeGCD() then ns.Refresh(false) end
    elseif event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED"
        or event == "UNIT_FLAGS" or event == "UNIT_FACTION" then
        local before = enemies:IsAOE()
        if event == "NAME_PLATE_UNIT_ADDED" then enemies:Add(unit)
        elseif event == "NAME_PLATE_UNIT_REMOVED" then enemies:Remove(unit)
        else enemies:Update(unit) end
        if engine.armed and before ~= enemies:IsAOE() then ns.Refresh(false) end
    else
        clearCycle()
        if event == "PLAYER_ENTERING_WORLD" or event == "CHALLENGE_MODE_START" then enemies:Rebuild()
        else enemies:Refresh() end
    end
end)
frame:RegisterEvent("ADDON_LOADED")
