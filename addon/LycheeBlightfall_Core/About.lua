local _, ns = ...
local T, About = ns.Theme, {}
ns.About = About
local C = T.colors
local entries = {
    {name="鸣谢", icon="thanks.tga"},
    {name="荔枝启动器", icon="launcher.tga", links={
        "https://www.wclbox.com/share/AJKkdJtw8gt", "https://url.cc.163.com/HoH0Od"}},
    {name="荔枝天赋", icon="talent.tga", links={
        "https://www.wclbox.com/share/AJu72Mjcmed", "https://url.cc.163.com/w64q1s"}},
}
local overlay, popup, heading, credits, downloads, fields, active

function About:Close()
    if overlay then overlay:Hide() end
end

local function buildPopup(panel, footer)
    overlay=CreateFrame("Button","LycheeBlightfallAboutPopup",panel)
    overlay:Hide(); overlay:SetAllPoints(UIParent); overlay:SetFrameStrata("DIALOG")
    overlay:SetScript("OnClick",function() About:Close() end)
    tinsert(UISpecialFrames,"LycheeBlightfallAboutPopup")
    popup=CreateFrame("Frame",nil,overlay)
    popup:SetSize(368,256); popup:SetPoint("BOTTOMLEFT",footer,"TOPLEFT",0,8)
    popup:SetClampedToScreen(true); popup:EnableMouse(true)
    T.Surface(popup,C.border,10)
    local inner=CreateFrame("Frame",nil,popup)
    inner:SetPoint("TOPLEFT",1,-1); inner:SetPoint("BOTTOMRIGHT",-1,1)
    T.Surface(inner,C.bg,9)
    heading=T.Text(inner,19,C.text,""); heading:SetPoint("TOPLEFT",19,-18)
    local close=T.Button(inner,"×",28,function() About:Close() end)
    close:SetPoint("TOPRIGHT",-12,-12); close:SetHeight(28)
    credits=CreateFrame("Frame",nil,inner); credits:SetAllPoints()
    local avatar=credits:CreateTexture(nil,"ARTWORK")
    avatar:SetSize(56,56); avatar:SetPoint("TOPLEFT",19,-56); avatar:SetTexture(T.media.."chef.tga")
    local chef=T.Text(credits,18,C.text,"小当家 Chef"); chef:SetPoint("LEFT",avatar,"RIGHT",14,0)
    downloads=CreateFrame("Frame",nil,inner); downloads:SetAllPoints()
    fields={}
    for i,label in ipairs({"新手盒子","网易 DD"}) do
        local y=58+(i-1)*76
        local title=T.Text(downloads,14,C.muted,label); title:SetPoint("TOPLEFT",19,-y)
        local box=CreateFrame("EditBox",nil,downloads)
        box:SetPoint("TOPLEFT",19,-y-23); box:SetPoint("TOPRIGHT",-19,-y-23); box:SetHeight(32)
        box:SetFont(STANDARD_TEXT_FONT,13,""); box:SetTextColor(unpack(C.text))
        box:SetAutoFocus(false); box:SetTextInsets(8,8,0,0); box:SetMaxLetters(200)
        T.Surface(box,C.field,5)
        box:SetScript("OnTextChanged",function(self)
            if self.url and self:GetText()~=self.url then self:SetText(self.url); self:HighlightText() end
        end)
        box:SetScript("OnEditFocusGained",function(self) self:HighlightText() end)
        box:SetScript("OnMouseUp",function(self) self:HighlightText() end)
        box:SetScript("OnEscapePressed",function() About:Close() end)
        box:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
        fields[i]=box
    end
    local hint=T.Text(downloads,12,C.dim,"Ctrl+C 复制链接"); hint:SetPoint("BOTTOMLEFT",19,16)
    overlay:SetScript("OnHide",function()
        active=nil
        for _,box in ipairs(fields) do box:ClearFocus() end
    end)
end

function About:CreateFooter(panel)
    local footer=CreateFrame("Frame",nil,panel)
    footer:SetPoint("BOTTOMLEFT",24,10); footer:SetPoint("BOTTOMRIGHT",-24,10); footer:SetHeight(40)
    for i,entry in ipairs(entries) do
        local item=entry
        local button=CreateFrame("Button",nil,footer)
        button:SetSize(40,40); button:SetPoint("LEFT",(i-1)*48,0)
        button.aboutName=item.name
        local surface=T.Surface(button,C.bg,6)
        local icon=button:CreateTexture(nil,"ARTWORK")
        icon:SetSize(40,40); icon:SetPoint("CENTER"); icon:SetTexture(T.media..item.icon)
        icon:SetTexCoord(.1,.9,.1,.9)
        button:SetScript("OnEnter",function(self)
            surface:SetColor(C.hover)
            GameTooltip:SetOwner(self,"ANCHOR_TOP"); GameTooltip:SetText(item.name); GameTooltip:Show()
        end)
        local function leave() surface:SetColor(C.bg); GameTooltip:Hide() end
        button:SetScript("OnLeave",leave); button:SetScript("OnHide",leave)
        button:SetScript("OnClick",function()
            GameTooltip:Hide()
            if not overlay then buildPopup(panel,footer) end
            if active==item then About:Close(); return end
            active=item; heading:SetText(item.name)
            credits:SetShown(not item.links); downloads:SetShown(item.links~=nil)
            popup:SetHeight(item.links and 256 or 130)
            if item.links then
                for index,box in ipairs(fields) do box.url=item.links[index]; box:SetText(box.url) end
            end
            overlay:Show()
            if item.links then fields[1]:SetFocus(); fields[1]:HighlightText() end
        end)
    end
end
