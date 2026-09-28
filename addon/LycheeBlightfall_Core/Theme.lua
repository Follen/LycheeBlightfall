local _, ns = ...
local T = {}
ns.Theme = T
T.media = "Interface\\AddOns\\LycheeBlightfall_Core\\Media\\"
T.colors = { bg={.055,.055,.063}, field={.085,.085,.095}, hover={.115,.11,.12},
    red={.835,.235,.285}, hot={.95,.35,.4}, text={.94,.932,.91},
    muted={.71,.705,.69}, dim={.59,.58,.59}, border={.19,.18,.19} }
local C = T.colors
function T.Text(parent, size, color, value)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, size, "")
    text:SetTextColor(unpack(color or C.text)); text:SetJustifyH("LEFT")
    text:SetShadowOffset(0, 0); text:SetText(value or "")
    return text
end
-- Same corner asset and flat palette as Lychee Talent; no SDK dependency.
function T.Surface(parent, color, radius)
    local parts, r = {}, radius or 8
    local center = parent:CreateTexture(nil, "BACKGROUND")
    center:SetPoint("TOPLEFT", r, 0); center:SetPoint("BOTTOMRIGHT", -r, 0)
    parts[1] = center
    for _, side in ipairs({"LEFT", "RIGHT"}) do
        local strip = parent:CreateTexture(nil, "BACKGROUND")
        strip:SetPoint("TOP"..side, 0, -r); strip:SetPoint("BOTTOM"..side, 0, r); strip:SetWidth(r)
        parts[#parts+1] = strip
    end
    for _, corner in ipairs({{"TOPLEFT",0,1,0,1},{"TOPRIGHT",1,0,0,1},
        {"BOTTOMLEFT",0,1,1,0},{"BOTTOMRIGHT",1,0,1,0}}) do
        local texture = parent:CreateTexture(nil, "BACKGROUND")
        texture:SetSize(r, r); texture:SetPoint(corner[1]); texture:SetTexture(T.media.."corner.tga")
        texture:SetTexCoord(corner[2],corner[3],corner[4],corner[5]); parts[#parts+1] = texture
    end
    local surface = {}
    function surface:SetColor(tint)
        for i, texture in ipairs(parts) do
            if i <= 3 then texture:SetColorTexture(tint[1],tint[2],tint[3],1)
            else texture:SetVertexColor(tint[1],tint[2],tint[3],1) end
        end
    end
    function surface:SetShown(shown)
        for _, texture in ipairs(parts) do texture:SetShown(shown) end
    end
    surface:SetColor(color)
    return surface
end
function T.Button(parent, label, width, callback, primary)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(width, 34)
    button.label = T.Text(button, 15, C.text, label); button.label:SetPoint("CENTER")
    button.surface = T.Surface(button, primary and C.red or C.border, 6)
    function button:Paint()
        local enabled = self:IsEnabled()
        local color = not enabled and C.field or self.down and C.border
            or self.hovered and (primary and C.hot or C.hover) or (primary and C.red or C.border)
        self.surface:SetColor(color)
        self.label:SetTextColor(unpack(not enabled and C.dim or primary and {1,1,1} or C.text))
    end
    button:SetScript("OnEnter", function(self) self.hovered=true; self:Paint() end)
    button:SetScript("OnLeave", function(self) self.hovered=nil; self.down=nil; self:Paint() end)
    button:SetScript("OnMouseDown", function(self) self.down=self:IsEnabled(); self:Paint() end)
    button:SetScript("OnMouseUp", function(self) self.down=nil; self:Paint() end)
    button:SetScript("OnHide", function(self) self.hovered=nil; self.down=nil; self:Paint() end)
    button:SetScript("OnClick", function(self) if self:IsEnabled() then callback(self) end end)
    button:Paint()
    return button
end
