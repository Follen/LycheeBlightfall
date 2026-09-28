local _, class = UnitClass("player")
if class ~= "DEATHKNIGHT" then return end

local app = { title = "|cffd53c49荔枝|r邪DK吞病" }
_G.LycheeBlightfall = app
local frame = CreateFrame("Frame")
local pending = false
local function refresh()
    pending = false
    local spec = C_SpecializationInfo.GetSpecialization()
    local eligible = spec and C_SpecializationInfo.GetSpecializationInfo(spec) == 252
        and C_ClassTalents.GetActiveHeroTalentSpec() == 31
        and C_SpellBook.IsSpellKnown(1271974)
    app.eligible = not not eligible
    if eligible and not app.SetEligible then
        local ok, reason = C_AddOns.LoadAddOn("LycheeBlightfall_Core")
        if not ok then
            if not app.loadError then
                print(app.title .. "：核心加载失败（" .. tostring(reason) .. "）。请安装压缩包中的两个文件夹。")
                app.loadError = true
            end
            return
        end
    end
    if app.SetEligible then app.SetEligible(app.eligible) end
end
local function queueRefresh()
    if pending then return end
    pending = true
    C_Timer.After(0, refresh)
end
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
frame:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED")
frame:SetScript("OnEvent", queueRefresh)
