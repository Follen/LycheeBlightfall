local _, ns = ...
local Enemies = {}
Enemies.__index = Enemies
ns.Enemies = Enemies

local function public(value) return not issecretvalue(value) end
local function validToken(unit)
    return public(unit) and type(unit) == "string" and unit:match("^nameplate%d+$") ~= nil
end
local function classify(unit)
    -- Only public booleans are used. No health, GUID, range or threat data.
    local player = UnitIsPlayer(unit)
    if not public(player) then return "unknown" end
    if player then return "excluded" end
    local attackable = UnitCanAttack("player", unit)
    if not public(attackable) then return "unknown" end
    if not attackable then return "excluded" end
    local dead = UnitIsDeadOrGhost(unit)
    if not public(dead) then return "unknown" end
    if dead then return "excluded" end
    local combat = UnitAffectingCombat(unit)
    if not public(combat) then return "unknown" end
    return combat and "engaged" or "excluded"
end
function Enemies.New()
    return setmetatable({ units = {}, count = 0, unknown = 0 }, Enemies)
end
function Enemies:Clear()
    self.units, self.count, self.unknown = {}, 0, 0
end
function Enemies:Set(unit, state)
    local old = self.units[unit]
    if old == state then return false end
    if old == "engaged" then self.count = self.count - 1 end
    if old == "unknown" then self.unknown = self.unknown - 1 end
    self.units[unit] = state
    if state == "engaged" then self.count = self.count + 1 end
    if state == "unknown" then self.unknown = self.unknown + 1 end
    return true
end
function Enemies:Add(unit)
    if not validToken(unit) then return false end
    return self:Set(unit, classify(unit))
end
function Enemies:Remove(unit)
    if not validToken(unit) then return false end
    return self:Set(unit, nil)
end
function Enemies:Update(unit)
    if not validToken(unit) or self.units[unit] == nil then return false end
    return self:Set(unit, classify(unit))
end
function Enemies:Refresh()
    for unit in pairs(self.units) do self:Update(unit) end
end
function Enemies:Rebuild()
    self:Clear()
    local plates = C_NamePlate.GetNamePlates()
    if not public(plates) or type(plates) ~= "table" then return end
    for _, plate in ipairs(plates) do
        if public(plate) and plate then
            local unit = plate.namePlateUnitToken
            if public(unit) and unit == nil then unit = plate.unitToken end
            self:Add(unit)
        end
    end
end
function Enemies:IsAOE()
    -- This is a lower bound of visible, publicly classifiable enemies.
    -- Unknown payloads never become guessed enemy counts.
    return self.count >= 3
end
