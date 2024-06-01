local CORE, addonTable = "GManager", {}

local function Rooster(container)
    local desc = AceGUI:Create("Label")
    desc:SetText("Rooster")
    desc:SetColor(1, 1, 0)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetJustifyH("CENTER")
    desc:SetFullWidth(true)
    container:AddChild(desc)
end
