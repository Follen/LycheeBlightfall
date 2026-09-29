local _, ns = ...
local Display = {}
ns.Display = Display
local frame, text, ticker, target, lastText, moveTitle, finish, action

local function stopTicker()
    if ticker then ticker:Cancel(); ticker = nil end
end
local function render()
    local remaining = math.max(0, (target or GetTime()) - GetTime())
    local label = action == "reaper" and "准备收割" or "准备吞病"
    local value = remaining > 0 and string.format("%s |cffd53c49%.1fs|r", label, math.ceil(remaining * 10) / 10)
        or "|cffd53c49" .. label .. "|r"
    if value ~= lastText then text:SetText(value); lastText = value end
    if remaining == 0 then stopTicker() end
end
function Display:Create()
    if frame then return end
    frame = CreateFrame("Frame", "LycheeBlightfallPrompt", UIParent)
    frame:SetSize(420, 72)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:EnableMouse(false)
    moveTitle = ns.Theme.Text(frame, 14, ns.Theme.colors.muted, "拖动调整位置")
    moveTitle:SetPoint("TOPLEFT", 14, -12)
    moveTitle:SetShadowColor(0, 0, 0, 1)
    moveTitle:SetShadowOffset(1, -1)
    moveTitle:Hide()
    finish = ns.Theme.Button(frame, "完成", 80, function()
        Display:SetUnlocked(false)
        ns.SettingsUI:Refresh()
    end, true)
    finish:SetPoint("BOTTOMRIGHT", -12, 12)
    finish:Hide()
    text = frame:CreateFontString(nil, "OVERLAY")
    text:SetPoint("CENTER")
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(2, -2)
    frame:SetScript("OnDragStart", function(self) if Display.unlocked then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local px, py = UIParent:GetCenter()
        ns.db.x, ns.db.y = x - px, y - py
        Display:Apply()
    end)
    self:Apply()
    frame:Hide()
end
function Display:Apply()
    if not frame then return end
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", ns.db.x, ns.db.y)
    text:SetFont(STANDARD_TEXT_FONT, ns.db.fontSize, "OUTLINE")
end
function Display:Hide()
    stopTicker()
    target, lastText, action = nil, nil, nil
    if frame and not self.unlocked then frame:Hide() end
end
function Display:Show(at, nextAction)
    self:Create()
    if self.unlocked then return end
    target = at
    action = nextAction
    render()
    frame:Show()
    if target > GetTime() and not ticker then ticker = C_Timer.NewTicker(0.1, render) end
end
function Display:SetUnlocked(unlocked)
    self:Create()
    self.unlocked = unlocked
    stopTicker()
    frame:EnableMouse(unlocked)
    if unlocked then
        frame:SetHeight(136)
        moveTitle:Show()
        finish:Show()
        text:SetText("准备吞病 |cffd53c493.0s|r")
        lastText = nil
        frame:Show()
    else
        frame:SetHeight(72)
        moveTitle:Hide()
        finish:Hide()
        frame:Hide()
        if ns.Refresh then ns.Refresh() end
    end
end
