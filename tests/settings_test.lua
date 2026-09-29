-- Reproduce Blizzard DisplayLayout when switching from an already-visible
-- addon canvas. Frames start shown; assigning OnShow does not invoke it.
-- Source: Blizzard_SettingsPanel.lua:899-928, commit 09b9db7948abc9b9648dedaab51eb0cf3ee67b31.
local count = 0
local function eq(a,b,message)
    assert(a==b,message..": expected "..tostring(b)..", got "..tostring(a))
    count=count+1
end
local function scenario(canvasVisible, viewport)
    viewport=viewport or 640
    local frames, texts, selected, changes = {}, {}, nil, 0
    local methods = {}
    function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function methods:SetScript(name,fn) self.scripts[name]=fn end
    function methods:RegisterEvent(name) self.events=self.events or {}; self.events[name]=true end
    function methods:UnregisterEvent(name) if self.events then self.events[name]=nil end end
    function methods:Show()
        local was=self:IsVisible(); self.shown=true
        if not was and self:IsVisible() and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        local was=self.shown; self.shown=false
        if was and self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:SetParent(parent)
        local was=self:IsVisible(); self.parent=parent
        if not was and self:IsVisible() and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:SetText(value)
        self.text=value
        if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
    end
    function methods:GetText() return self.text end
    function methods:SetFocus() self.focused=true end
    function methods:ClearFocus() self.focused=false end
    function methods:HighlightText() self.highlighted=true end
    function methods:SetThumbTexture(thumb) self.thumb=thumb end
    function methods:SetMinMaxValues(low,high) self.low,self.high=low,high end
    function methods:SetSize(w,h) self.width,self.height=w,h end
    function methods:SetWidth(w) self.width=w end
    function methods:SetHeight(h) self.height=h end
    function methods:GetWidth()
        if self.name=="LycheeBlightfallSlider_dialogVolume" then return viewport-88 end
        return self.width or (self.kind=="Slider" and viewport-288 or viewport)
    end
    function methods:GetHeight() return self.height or 720 end
    function methods:IsEnabled() return self.enabled~=false end
    function methods:IsShown() return self.shown end
    function methods:SetShown(value) if value then self:Show() else self:Hide() end end
    function methods:GetCenter() return self.centerX or 0,self.centerY or 0 end
    function methods:SetFont(path,size,flags) self.fontSize=size end
    function methods:SetTextColor(...) self.textColor={...} end
    function methods:SetJustifyH(value) self.justify=value end
    function methods:SetFrameStrata(value) self.strata=value end
    function methods:SetColorTexture(...) self.color={...} end
    function methods:SetVertexColor(...) self.tint={...} end
    function methods:SetTexture(path) self.texture=path end
    function methods:SetTexCoord(...) self.texCoord={...} end
    function methods:SetPoint(...) self.points[#self.points+1]={...} end
    function methods:SetAllPoints(parent) self.allPoints=parent or self.parent end
    function methods:ClearAllPoints() self.points={} end
    function methods:SetChecked(value) self.checked=value end
    function methods:GetChecked() return self.checked end
    function methods:SetScrollChild(child) self.scrollChild=child end
    function methods:SetValue(value)
        self.value=value
        if self.thumb then
            self.thumb:ClearAllPoints()
            self.thumb:SetPoint("CENTER",self,"LEFT",self:GetWidth()*(value-self.low)/(self.high-self.low),0)
        end
        if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value) end
    end
    function methods:CreateFontString() local text=CreateFrame("FontString",nil,self); texts[#texts+1]=text; return text end
    function methods:CreateTexture() return CreateFrame("Texture",nil,self) end
    function methods:SetupMenu(fn) self.menu=fn end
    function methods:GenerateMenu()
        self.menu(self,{SetScrollMode=function() end,CreateRadio=function() end})
    end
    for _,name in ipairs({"SetValueStep","SetObeyStepOnDrag","SetShadowOffset",
        "SetMaxLines","SetOrientation","EnableMouse","SetAutoFocus","SetTextInsets","SetMaxLetters",
        "SetClampedToScreen","SetMovable","RegisterForDrag","StartMoving","StopMovingOrSizing","SetShadowColor"}) do
        methods[name]=function() end
    end
    function CreateFrame(kind,name,parent,template)
        local frame=setmetatable({kind=kind,name=name,parent=parent,template=template,
            shown=true,scripts={},points={}}, {__index=methods})
        frames[#frames+1]=frame
        if name then _G[name]=frame end
        return frame
    end
    UIParent=CreateFrame("Frame")
    UIParent:SetSize(1920,1080)
    SettingsPanel=CreateFrame("Frame",nil,UIParent)
    SettingsPanel:SetSize(viewport+26,768)
    function SettingsPanel:Close(skipBack)
        self.skipBack=skipBack
        if not self.pending then self:Hide() end
    end
    STANDARD_TEXT_FONT="test-font"
    UISpecialFrames={}; tinsert=table.insert
    GameTooltip={Hide=function() end,IsOwned=function() return false end}
    local systemVolume,cvarWrites=.45,0
    C_CVar={GetCVar=function(name)
        eq(name,"Sound_DialogVolume","read only system dialogue volume")
        return tostring(systemVolume)
    end,SetCVar=function(name,value)
        eq(name,"Sound_DialogVolume","write only system dialogue volume")
        systemVolume=value; cvarWrites=cvarWrites+1
        if selected and selected.layout.frame.events.CVAR_UPDATE then
            selected.layout.frame.scripts.OnEvent(selected.layout.frame,"CVAR_UPDATE",name,tostring(value))
        end
    end}
    local choices={}
    MenuUtil={CreateContextMenu=function(owner,generator)
        generator(owner,{SetScrollMode=function()end,CreateRadio=function(_,name,selected,callback)
            choices[#choices+1]={name=name,selected=selected,callback=callback}
        end})
    end}
    local canvas=CreateFrame("Frame",nil,SettingsPanel)
    canvas:SetSize(viewport+26,768)
    if not canvasVisible then canvas:Hide() end
    Settings={RegisterCanvasLayoutCategory=function(panel)
        local layout={frame=panel,anchors={}}
        function layout:AddAnchorPoint(p,x,y) self.anchors[#self.anchors+1]={p=p,x=x,y=y} end
        return {layout=layout},layout
    end,RegisterAddOnCategory=function(category) selected=category end}
    function HideUIPanel(panel) panel:Hide() end
    LycheeBlightfall={title="Test",eligible=true}
    local ns={db={enabled=true,textEnabled=true,soundEnabled=true,textLead=3,soundLead=3,
        fontSize=32,x=0,y=160,sound="default",reaperEnabled=true,reaperSound="reaper"},media={List=function() return {"default","another"} end},
        Display={Apply=function() end,SetUnlocked=function(self,value) self.unlocked=value end},
        PlayVoice=function() end,ResetSettings=function() end,
        ApplySettings=function() changes=changes+1 end}
    assert(loadfile("addon/LycheeBlightfall_Core/Theme.lua"))("Test",ns)
    assert(loadfile("addon/LycheeBlightfall_Core/About.lua"))("Test",ns)
    assert(loadfile("addon/LycheeBlightfall_Core/Settings.lua"))("Test",ns)
    ns.SettingsUI:Register()
    local panel=selected.layout.frame
    local initial=#frames
    ns.SettingsUI:Refresh()
    eq(#frames,initial,"talent status refresh does not eagerly build settings")
    -- Reproduce DisplayLayout's order, including its explicit OnRefresh callback.
    panel:SetParent(canvas)
    panel:ClearAllPoints()
    for _,anchor in ipairs(selected.layout.anchors) do panel:SetPoint(anchor.p,anchor.x,anchor.y) end
    if #selected.layout.anchors==0 then panel:SetAllPoints(canvas) end
    panel:Show()
    if panel.OnRefresh then panel.OnRefresh() end
    canvas:Show()
    local scroll
    for _,frame in ipairs(frames) do if frame.kind=="ScrollFrame" and frame.parent==panel then scroll=frame end end
    eq(not not scroll,true,"selected settings canvas must contain its controls")
    eq(scroll.scrollChild.width,scroll:GetWidth(),"scroll content follows the viewport width")
    eq(ns.db.textLead,3,"first display preserves saved values")
    eq(changes,0,"refresh does not reset the active combat cycle")
    local before=#frames
    panel:Hide(); panel:Show(); panel.OnRefresh()
    eq(#frames,before,"reopening does not duplicate widgets")
    local checks,sliders,dropdowns=0,0,0
    for _,frame in ipairs(frames) do
        if frame.kind=="CheckButton" then checks=checks+1 end
        if frame.kind=="Slider" then sliders=sliders+1 end
        if frame.kind=="DropdownButton" then dropdowns=dropdowns+1 end
    end
    eq(checks,4,"enable/reaper/text/voice toggles built")
    eq(sliders,4,"lead/font/system volume sliders built")
    local volume=LycheeBlightfallSlider_dialogVolume
    eq(volume.value,45,"volume starts from current system value")
    eq(cvarWrites,0,"opening settings does not change system volume")
    eq(volume.thumb.color[1],ns.Theme.colors.red[1],"volume thumb uses lychee red")
    volume:SetValue(0)
    eq(systemVolume,0,"zero can mute dialogue")
    volume:SetValue(100)
    eq(systemVolume,1,"maximum maps to full system volume")
    eq(changes,0,"volume changes do not reset or refresh combat tracking")
    eq(ns.db.dialogVolume,nil,"system volume is never duplicated in addon saved settings")
    systemVolume=.37
    panel.scripts.OnEvent(panel,"CVAR_UPDATE","Sound_DialogVolume","0.37")
    eq(volume.value,37,"external CVar update refreshes volume slider")
    eq(cvarWrites,2,"synchronization does not write the CVar back")
    panel:Hide()
    eq(panel.events.CVAR_UPDATE,nil,"hidden panel stops listening for CVars")
    systemVolume=.62
    panel:Show()
    eq(volume.value,62,"reopening rereads changes made while hidden")
    panel.OnDefault()
    eq(systemVolume,.62,"addon defaults leave global audio volume unchanged")
    eq(dropdowns,0,"sound selection uses a native context menu")
    if arg[1]=="--snapshot" and canvasVisible then
        assert(loadfile("tools/ui_snapshot.lua"))()(frames,"Analyze/ui-settings-"..viewport..".json")
    end
    local unlock,choose,avatar,chef
    local icons={}
    for _,frame in ipairs(frames) do
        if frame.aboutName then icons[frame.aboutName]=frame end
        if frame.label and frame.label.text=="解锁位置" then unlock=frame end
        if frame.label and frame.label.text=="更换" and not choose then choose=frame end
    end
    eq(icons["鸣谢"]~=nil and icons["荔枝启动器"]~=nil and icons["荔枝天赋"]~=nil,true,"three footer entrances")
    icons["鸣谢"].scripts.OnClick()
    local popup=LycheeBlightfallAboutPopup
    eq(popup:IsShown(),true,"credits opens")
    eq(UISpecialFrames[1],"LycheeBlightfallAboutPopup","Escape closes the popup")
    for _,frame in ipairs(frames) do
        if frame.texture and frame.texture:find("chef.tga",1,true) then avatar=frame end
        if frame.text=="小当家 Chef" then chef=frame end
    end
    eq(not not avatar,true,"provided avatar is in the credits")
    eq(not not chef,true,"exact acknowledgement name appears")
    local afterPopup=#frames
    if arg[1]=="--snapshot" and canvasVisible and viewport==640 then
        assert(loadfile("tools/ui_snapshot.lua"))()(frames,"Analyze/ui-credits.json")
    end
    popup.scripts.OnClick()
    eq(popup:IsShown(),false,"outside click closes popup")
    local expected={
        {"荔枝启动器","https://www.wclbox.com/share/AJKkdJtw8gt","https://url.cc.163.com/HoH0Od"},
        {"荔枝天赋","https://www.wclbox.com/share/AJu72Mjcmed","https://url.cc.163.com/w64q1s"},
    }
    for _,item in ipairs(expected) do
        icons[item[1]].scripts.OnClick()
        local fields={}
        for _,frame in ipairs(frames) do if frame.kind=="EditBox" then fields[#fields+1]=frame end end
        eq(#fields,2,"two platform links")
        eq(fields[1]:GetText(),item[2],"exact NewBeeBox link")
        eq(fields[2]:GetText(),item[3],"exact NetEase DD link")
        eq(fields[1].highlighted,true,"first URL is selected for copying")
        fields[2]:SetText("accidental edit")
        eq(fields[2]:GetText(),item[3],"download link remains read-only")
        if arg[1]=="--snapshot" and canvasVisible and viewport==640 and item[1]=="荔枝启动器" then
            assert(loadfile("tools/ui_snapshot.lua"))()(frames,"Analyze/ui-downloads.json")
        end
        fields[2].scripts.OnEscapePressed()
        eq(popup:IsShown(),false,"Escape in URL closes popup")
        eq(fields[1].focused,false,"closing clears URL focus")
    end
    eq(#frames,afterPopup,"popover and URL fields are reused")
    icons["鸣谢"].scripts.OnClick()
    panel:Hide()
    eq(popup:IsShown(),false,"leaving settings closes the popup")
    panel:Show()
    choose.scripts.OnClick(choose)
    eq(#choices,2,"SharedMedia choices include every registered sound")
    choices[2].callback()
    eq(ns.db.sound,"another","sound menu saves selected voice")
    SettingsPanel:Show(); SettingsPanel.pending=true
    unlock.scripts.OnClick(unlock)
    eq(ns.Display.unlocked,nil,"pending native settings do not unlock behind a dialog")
    SettingsPanel.pending=nil
    unlock.scripts.OnClick(unlock)
    eq(SettingsPanel:IsShown(),false,"unlock closes the native settings window")
    eq(SettingsPanel.skipBack,true,"unlock does not return to Escape menu")
    eq(ns.Display.unlocked,true,"unlock shows the mover")
    eq(unlock.label.text,"锁定位置","reopening settings offers locking")
    -- Run the actual mover, including its direct Done action and drag persistence.
    local displayTime, displayTimers=0,{}
    C_Timer={NewTicker=function(_,callback)
        local timer={callback=callback,Cancel=function(self) self.cancelled=true end}
        displayTimers[#displayTimers+1]=timer
        return timer
    end}
    function GetTime() return displayTime end
    ns.Refresh=function() end
    assert(loadfile("addon/LycheeBlightfall_Core/Display.lua"))("Test",ns)
    ns.Display:SetUnlocked(true)
    if arg[1]=="--snapshot" and canvasVisible and viewport==640 then
        assert(loadfile("tools/ui_snapshot.lua"))()(frames,"Analyze/ui-mover.json")
    end
    local mover=LycheeBlightfallPrompt
    mover.centerX,mover.centerY=110,220
    mover.scripts.OnDragStop(mover)
    eq(ns.db.x,110,"drag stores horizontal position")
    eq(ns.db.y,220,"drag stores vertical position")
    local done
    for _,frame in ipairs(frames) do if frame.parent==mover and frame.label and frame.label.text=="完成" then done=frame end end
    eq(not not done,true,"mover has an immediate finish button")
    done.scripts.OnClick(done)
    eq(ns.Display.unlocked,false,"Done locks the mover without reopening settings")
    eq(mover:IsShown(),false,"Done removes the positioning overlay")
    ns.Display:Show(3,"reaper")
    local prompt
    for _,object in ipairs(frames) do
        if object.parent==mover and object.kind=="FontString" and object.text:find("准备收割",1,true) then prompt=object end
    end
    eq(not not prompt,true,"actual display renders the reaper cue")
    ns.Display:Show(2)
    eq(prompt.text:find("准备吞病",1,true)==1,true,"same line returns to swallow without stale label")
    eq(#displayTimers,1,"retargeting reuses the same display ticker")
    displayTime=2
    displayTimers[1].callback()
    eq(displayTimers[1].cancelled,true,"zero countdown stops refreshing")
    eq(mover:IsShown(),true,"zero countdown keeps the action prompt visible")
    ns.Display:Show(2)
    eq(#displayTimers,1,"expired target cannot restart ticker")
    ns.Display:Show(4)
    eq(#displayTimers,2,"extended future target restarts ticker")
    ns.Display:Hide()
    eq(displayTimers[2].cancelled,true,"hiding cancels restarted ticker")
end
scenario(true)
scenario(false)
scenario(true,480)
print("Settings assertions passed: "..count)
