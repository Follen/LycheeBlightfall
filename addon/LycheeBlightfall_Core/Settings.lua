local _, ns = ...
local UI, T = {}, ns.Theme
ns.SettingsUI = UI
local C = T.colors
local panel, content, refreshers = nil, nil, {}
local refreshAudioVolume

local function changed()
    ns.ApplySettings()
    UI:Refresh()
end
local function row(y, height, kind)
    local frame = CreateFrame(kind or "Frame", nil, content)
    frame:SetPoint("TOPLEFT", 24, -y)
    frame:SetPoint("TOPRIGHT", -24, -y)
    frame:SetHeight(height)
    frame.surface = T.Surface(frame, C.field, 8)
    return frame
end
local function toggle(y, title, key)
    local control = row(y, 48, "CheckButton")
    local label = T.Text(control, 16, C.text, title)
    label:SetPoint("LEFT", 14, 0)
    local mark = control:CreateTexture(nil, "ARTWORK")
    mark:SetSize(22,22); mark:SetPoint("RIGHT", -14, 0)
    mark:SetTexture(T.media.."choice-checkbox.tga")
    function control:Paint()
        local state = self:GetChecked() and 2 or self.hovered and 1 or 0
        mark:SetTexCoord(state/4,(state+1)/4,0,1)
        self.surface:SetColor(self.hovered and C.hover or C.field)
    end
    control:SetScript("OnEnter", function(self) self.hovered=true; self:Paint() end)
    control:SetScript("OnLeave", function(self) self.hovered=nil; self:Paint() end)
    control:SetScript("OnHide", function(self) self.hovered=nil; self:Paint() end)
    control:SetScript("OnClick", function(self) ns.db[key]=self:GetChecked()==true; changed() end)
    refreshers[#refreshers+1] = function() control:SetChecked(ns.db[key]); control:Paint() end
end
local function slider(y, title, key, low, high, step, suffix, binding)
    local read = binding and binding.read or function() return ns.db[key] end
    local write = binding and binding.write or function(value) ns.db[key]=value; changed() end
    local subtitle = binding and binding.subtitle
    local thumbColor = binding and C.red or C.text
    local host = row(y, subtitle and 96 or 56)
    local label = T.Text(host, 16, C.text, title)
    if subtitle then
        label:SetPoint("TOPLEFT",14,-12)
        local hint = T.Text(host,13,C.muted,subtitle)
        hint:SetPoint("TOPLEFT",14,-36); hint:SetPoint("TOPRIGHT",-14,-36)
    else label:SetPoint("LEFT",14,0) end
    local valueText = T.Text(host, 16, C.text, "")
    if subtitle then valueText:SetPoint("TOPRIGHT",-14,-12)
    else valueText:SetPoint("RIGHT",-14,0) end
    valueText:SetJustifyH("RIGHT"); valueText:SetWidth(70)
    local control = CreateFrame("Slider", "LycheeBlightfallSlider_"..key, host)
    if subtitle then
        control:SetPoint("BOTTOMLEFT",20,10); control:SetPoint("BOTTOMRIGHT",-20,10)
    else control:SetPoint("LEFT",142,0); control:SetPoint("RIGHT",-98,0) end
    control:SetHeight(24)
    control:SetOrientation("HORIZONTAL"); control:SetMinMaxValues(low,high)
    control:SetValueStep(step); control:SetObeyStepOnDrag(true)
    local track = control:CreateTexture(nil,"BACKGROUND")
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(3); track:SetColorTexture(unpack(C.border))
    local progress = control:CreateTexture(nil,"ARTWORK")
    progress:SetPoint("LEFT"); progress:SetHeight(3); progress:SetColorTexture(unpack(C.red))
    local thumb = control:CreateTexture(nil,"OVERLAY")
    thumb:SetSize(12,20); thumb:SetColorTexture(unpack(thumbColor)); control:SetThumbTexture(thumb)
    local refreshing=false
    local function paint(value)
        valueText:SetText(string.format(step<1 and "%.1f" or "%.0f",value)..suffix)
        progress:SetWidth(math.max(.01,control:GetWidth()*(value-low)/(high-low)))
    end
    control:SetScript("OnValueChanged",function(_,value)
        value=math.floor(value/step+.5)*step
        paint(value)
        if not refreshing and math.floor(read()/step+.5)*step~=value then write(value) end
    end)
    control:SetScript("OnSizeChanged",function() paint(read()) end)
    control:SetScript("OnEnter",function() thumb:SetColorTexture(unpack(C.hot)) end)
    control:SetScript("OnLeave",function() thumb:SetColorTexture(unpack(thumbColor)) end)
    local function refresh()
        refreshing=true; control:SetValue(read()); paint(read()); refreshing=false
    end
    refreshers[#refreshers+1]=refresh
    return refresh
end

function UI:TogglePosition()
    if ns.Display.unlocked then ns.Display:SetUnlocked(false); self:Refresh(); return end
    -- Close through Blizzard, without returning to the Escape menu. If native
    -- settings still need confirmation, do not put the mover behind that dialog.
    if SettingsPanel and SettingsPanel:IsShown() then
        SettingsPanel:Close(true)
        if SettingsPanel:IsShown() then return end
    end
    ns.Display:SetUnlocked(true)
    self:Refresh()
end

local function build()
    if panel.built then return end
    local backdrop = panel:CreateTexture(nil,"BACKGROUND")
    backdrop:SetAllPoints(); backdrop:SetColorTexture(unpack(C.bg))
    local scroll = CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",0,-4); scroll:SetPoint("BOTTOMRIGHT",-26,68)
    content=CreateFrame("Frame",nil,scroll)
    content:SetSize(640,904); scroll:SetScrollChild(content)
    local function resize()
        local width=scroll:GetWidth()
        if width and width>0 then content:SetWidth(width) end
    end
    scroll:SetScript("OnSizeChanged",resize); resize()

    local logo=content:CreateTexture(nil,"ARTWORK")
    logo:SetSize(54,54); logo:SetPoint("TOPLEFT",20,-17)
    logo:SetTexture("Interface\\AddOns\\LycheeBlightfall\\Media\\lychee-logo.tga")
    local title=T.Text(content,26,C.text,"[荔枝]智能吞病收割提醒"); title:SetPoint("TOPLEFT",86,-24)
    local status=T.Text(content,14,C.muted,""); status:SetPoint("TOPLEFT",86,-57)
    refreshers[#refreshers+1]=function()
        status:SetText(not LycheeBlightfall.eligible and "当前天赋不支持" or ns.db.enabled and "萨莱因邪 DK" or "提醒已暂停")
    end
    toggle(94,"启用提醒","enabled")
    toggle(150,"收割提醒","reaperEnabled")
    toggle(222,"文字提示","textEnabled")
    local preview=row(278,92)
    local sample=T.Text(preview,28,C.text,"")
    sample:SetPoint("LEFT",14,0)
    local move=T.Button(preview,"解锁位置",104,function() UI:TogglePosition() end,true)
    move:SetPoint("TOPRIGHT",-12,-10)
    local reset=T.Button(preview,"重置位置",104,function()
        ns.db.x,ns.db.y=0,160; ns.Display:Apply()
    end)
    reset:SetPoint("TOPRIGHT",-12,-50); reset:SetHeight(30)
    refreshers[#refreshers+1]=function()
        sample:SetText(string.format("准备吞病 |cffd53c49%.1fs|r",ns.db.textLead))
        move.label:SetText(ns.Display.unlocked and "锁定位置" or "解锁位置")
    end
    slider(378,"提前显示","textLead",0,10,.5," 秒")
    slider(442,"文字大小","fontSize",18,60,1,"")
    toggle(522,"语音提醒","soundEnabled")
    refreshAudioVolume=slider(578,"音频音量","dialogVolume",0,100,1,"%",{
        subtitle="这将改变系统对话音量",
        read=function()
            local value=tonumber(C_CVar.GetCVar("Sound_DialogVolume")) or 0
            return math.max(0,math.min(1,value))*100
        end,
        write=function(value) C_CVar.SetCVar("Sound_DialogVolume",value/100) end,
    })
    slider(682,"提前播报","soundLead",0,10,.5," 秒")
    local function soundRow(y, title, key, action)
        local sound=row(y,64)
        local soundTitle=T.Text(sound,16,C.text,title); soundTitle:SetPoint("TOPLEFT",14,-10)
        local selection=T.Text(sound,14,C.muted,"")
        selection:SetPoint("TOPLEFT",14,-36); selection:SetPoint("TOPRIGHT",-170,-36); selection:SetMaxLines(1)
        local choose=T.Button(sound,"更换",64,function(owner)
            MenuUtil.CreateContextMenu(owner,function(_,root)
                root:SetScrollMode(250)
                for _,name in ipairs(ns.media:List("sound")) do
                    local choice=name
                    root:CreateRadio(choice,function() return ns.db[key]==choice end,function()
                        ns.db[key]=choice; changed()
                    end)
                end
            end)
        end)
        choose:SetPoint("RIGHT",-88,0)
        local audition=T.Button(sound,"试听",64,function() ns.PlayVoice(true,action) end)
        audition:SetPoint("RIGHT",-12,0)
        refreshers[#refreshers+1]=function() selection:SetText(ns.db[key]) end
        sound:EnableMouse(true)
        sound:SetScript("OnEnter",function()
            GameTooltip:SetOwner(sound,"ANCHOR_TOP"); GameTooltip:SetText(ns.db[key]); GameTooltip:Show()
        end)
        sound:SetScript("OnLeave",function() GameTooltip:Hide() end)
        sound:SetScript("OnHide",function() if GameTooltip:IsOwned(sound) then GameTooltip:Hide() end end)
    end
    soundRow(746,"吞病提示音","sound")
    soundRow(818,"收割提示音","reaperSound","reaper")

    ns.About:CreateFooter(panel)
    panel.built=true
end

function UI:Refresh(ensureBuilt)
    if not panel then return end
    if not panel.built then if not ensureBuilt then return end; build() end
    for _,refresh in ipairs(refreshers) do refresh() end
end
function UI:Register()
    panel=CreateFrame("Frame","LycheeBlightfallOptionsPanel",UIParent)
    panel:Hide(); panel.name=LycheeBlightfall.title
    panel:SetScript("OnShow",function() panel:RegisterEvent("CVAR_UPDATE"); self:Refresh(true) end)
    panel:SetScript("OnHide",function() panel:UnregisterEvent("CVAR_UPDATE"); ns.About:Close() end)
    -- Read the CVar again instead of relying on event payload names or values.
    -- Listen only while this settings page is open; no polling or combat reset.
    panel:SetScript("OnEvent",function() if refreshAudioVolume then refreshAudioVolume() end end)
    panel.OnDefault=function() ns.ResetSettings(); self:Refresh() end
    panel.OnRefresh=function() self:Refresh(true) end
    local category=Settings.RegisterCanvasLayoutCategory(panel,panel.name)
    Settings.RegisterAddOnCategory(category)
end
