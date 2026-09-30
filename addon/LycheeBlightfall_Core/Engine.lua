local _, ns = ...
local Engine = {}
Engine.__index = Engine
ns.Engine = Engine

Engine.DT = 1233448
Engine.REAPER = 343294
Engine.BLIGHTFALL = 1271967
Engine.HEART = 1297761
Engine.SUDDEN_DOOM = 81340
Engine.VISCERAL_TALENT = 434157
Engine.EXTENDERS = { [47541] = true, [207317] = true, [1242174] = true, [383269] = true }
Engine.TRACKED = { [1233448] = true, [343294] = true, [1271967] = true,
    [47541] = true, [207317] = true, [1242174] = true, [383269] = true, [1297761] = true }

function Engine.New()
    return setmetatable({ gcd = 1.5, gcdAt = -math.huge, seen = {}, order = {}, cursor = 0 }, Engine)
end

function Engine:ResetCycle()
    self.armed = false
    self.dtEnd, self.srEnd, self.heartEnd = nil, nil, nil
    self.dtStart = nil
    self.reaperTextShown, self.reaperVoiced = false, false
    self.textShown, self.voiced = false, false
end

function Engine:Reset()
    self:ResetCycle()
    self:ForgetDoom()
    self.strengthEnd, self.spenderAt = nil, nil
end

function Engine:ForgetDoom()
    self.doomShown, self.doomAvailable, self.doomEnd = false, false, nil
end

function Engine:Overlay(shown, now)
    if not shown then self:ForgetDoom(); return end
    -- A repeated SHOW can be a redraw, not another charge or a refresh.
    -- Track at most one consumption per observed absent -> present transition.
    if self.doomShown then return end
    self.doomShown, self.doomAvailable, self.doomEnd = true, true, now + 10
end

function Engine:DoomReady(now)
    return self.doomAvailable and self.doomEnd and now < self.doomEnd - 0.15
end

function Engine:GCD(now)
    return now - self.gcdAt <= 10 and self.gcd or 1.5
end

function Engine:SetGCD(duration, now)
    -- A zero duration means no active GCD, not a zero-length GCD.
    if type(duration) ~= "number" or duration ~= duration or duration < 0.5 or duration > 2 then return false end
    local changed = math.abs(self:GCD(now) - duration) > 0.001
    self.gcd, self.gcdAt = duration, now
    return changed
end

function Engine:Cast(spellID, now, castGUID, useVisceral)
    if not self.TRACKED[spellID] then return false end
    if castGUID and castGUID ~= "" then
        if self.seen[castGUID] then return false end
        self.cursor = self.cursor % 16 + 1
        local old = self.order[self.cursor]
        if old then self.seen[old] = nil end
        self.order[self.cursor] = castGUID
        self.seen[castGUID] = true
    end
    if spellID == self.DT then
        local heartEnd = self.heartEnd
        self:ResetCycle()
        if heartEnd and heartEnd > now then self.heartEnd = heartEnd end
        self.armed, self.dtEnd = true, now + 15
        self.dtStart = now
        return true
    end
    if spellID == self.HEART then
        self.heartEnd = now + 20
        return true
    end
    local consumed = false
    if self.EXTENDERS[spellID] then
        self.spenderAt = now
        if useVisceral and self:DoomReady(now) then
            self.strengthEnd = now + 5
            self.doomAvailable = false
            consumed = true
        end
    end
    if not self.armed then return consumed end
    if spellID == self.BLIGHTFALL then self:ResetCycle(); return true end
    if spellID == self.REAPER then
        self.srEnd = now + 8
        return true
    end
    if self.EXTENDERS[spellID] and now < self.dtEnd then
        self.dtEnd = self.dtEnd + 1
        return true
    end
    return consumed or self.EXTENDERS[spellID] == true
end

function Engine:UpdateReaper(now, options, useReaper)
    if not self.armed or not options.reaperEnabled or not useReaper
        or self.srEnd or not self.dtStart or now >= self.dtEnd
        or self.heartEnd and now >= self.heartEnd then return nil end
    if not options.textEnabled and not options.soundEnabled then return nil end
    local target = self.heartEnd and self.heartEnd > now and self.heartEnd - 9
        or self.dtStart + 7.01
    local state = { target = target, wake = self.dtEnd, action = "reaper" }
    if options.textEnabled then
        local at = target - options.textLead
        if self.reaperTextShown or now >= at then
            self.reaperTextShown, state.show = true, true
        else state.wake = math.min(state.wake, at) end
    end
    if options.soundEnabled and not self.reaperVoiced then
        local at = target - options.soundLead
        if now >= at then self.reaperVoiced, state.voice = true, true
        else state.wake = math.min(state.wake, at) end
    end
    return state
end

function Engine:Update(now, options, useReaper, useVisceral)
    if not self.armed then return nil end
    if not options.textEnabled and not options.soundEnabled then return nil end
    -- Heart can prompt a swallow on its own. Once it fades, an actual Reaper
    -- window may still prompt one if Blightfall has not been cast.
    if self.heartEnd and now >= self.heartEnd then self.heartEnd = nil end
    if useReaper and not self.srEnd and not self.heartEnd then
        -- Without Heart, wait for an observed Reaper rather than guessing it.
        local wake = self.dtEnd
        if now >= wake then self:ResetCycle(); return nil end
        return { wake = wake, waitingReaper = true }
    end
    local deadline, reason = self.dtEnd, "dark_transformation"
    if useReaper and self.srEnd then
        -- Reaping follows the observed Soul Reaper, not a guessed window.
        deadline, reason = self.srEnd, "soul_reaper"
    elseif useReaper and self.heartEnd then
        deadline, reason = self.heartEnd, "heart"
    end
    -- Whichever active condition ends first determines the earlier cue.
    if self.heartEnd and self.heartEnd < deadline then
        deadline, reason = self.heartEnd, "heart"
    end
    if now >= deadline then self:ResetCycle(); return nil end
    local gcd = self:GCD(now)
    local readyAt = math.max(now,
        useReaper and self.srEnd and self.srEnd - 8 + gcd or now,
        self.spenderAt and self.spenderAt + gcd or now)
    local base = deadline - 2 * gcd
    local target = base
    local strengthCovers = useVisceral and self.strengthEnd
        and self.strengthEnd > math.max(now, base, readyAt) + 0.15
    local prepareUntil = base - gcd - 0.2
    -- Prepare BEFORE the APL threshold; never delay an eligible Blightfall
    -- for strength. Reserve one spender GCD plus a small reaction margin.
    -- Five seconds of strength must also cover the spender's +1s DT extension.
    local prepare = useVisceral and not strengthCovers and self:DoomReady(now)
        and math.max(now, readyAt) + gcd + 0.2 < base
    -- A just-cast spender may still occupy the GCD when the APL window opens.
    if self.spenderAt and self.spenderAt + gcd > now then
        target = math.max(target, math.min(self.spenderAt + gcd, deadline - 0.15))
    end
    -- Recompute on every relevant cast and observed GCD change.
    local state = { target = target, deadline = deadline, reason = reason, wake = deadline }
    state.strengthCovers = not not strengthCovers
    local prepareAt = base - 3.8
    if prepare then
        if now >= prepareAt then state.prepare = true
        else state.wake = math.min(state.wake, prepareAt) end
        state.wake = math.min(state.wake, prepareUntil, self.doomEnd - 0.15)
    end
    if useVisceral and self.strengthEnd and self.strengthEnd - 0.15 > now then
        state.wake = math.min(state.wake, self.strengthEnd - 0.15)
    end
    if options.textEnabled then
        local textAt = target - options.textLead
        if self.textShown or now >= textAt then
            self.textShown, state.show = true, true
        else state.wake = math.min(state.wake, textAt) end
    end
    if options.soundEnabled and not self.voiced then
        local soundAt = target - options.soundLead
        if now >= soundAt then self.voiced, state.voice = true, true
        else state.wake = math.min(state.wake, soundAt) end
    end
    return state
end
