---@diagnostic disable: undefined-field, duplicate-set-field, undefined-global, redundant-parameter, deprecated
GManager = LibStub("AceAddon-3.0"):NewAddon("GManager", "AceConsole-3.0")
local TIMER = LibStub("AceTimer-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local AceAddon = LibStub("AceAddon-3.0")
local EVENTS = AceAddon:NewAddon("EVENTS", "AceEvent-3.0")
local frameShown = false
local textStore
local gmessage
local keywords
local timerId
local spamTimerId
local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player")
GManager.db = {
    channelForSpam = 1,
    messageToSpam = "none",
    timerToSpam = 60
}

local PlayerCharacters = {}
local classCounts = {
    ["WARRIOR"] = 0,
    ["PALADIN"] = 0,
    ["HUNTER"] = 0,
    ["ROGUE"] = 0,
    ["PRIEST"] = 0,
    ["DEATHKNIGHT"] = 0,
    ["SHAMAN"] = 0,
    ["MAGE"] = 0,
    ["WARLOCK"] = 0,
    ["DRUID"] = 0
}
local function CountClasses()
    classCounts = {
        ["WARRIOR"] = 0,
        ["PALADIN"] = 0,
        ["HUNTER"] = 0,
        ["ROGUE"] = 0,
        ["PRIEST"] = 0,
        ["DEATHKNIGHT"] = 0,
        ["SHAMAN"] = 0,
        ["MAGE"] = 0,
        ["WARLOCK"] = 0,
        ["DRUID"] = 0
    }
    for i = 1, GetNumGuildMembers(true) do
        local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
        classCounts[class] = (classCounts[class] or 0) + 1
    end
end
local function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end
local function GuildNameToIndex(name)
    name = string.lower(name)
    for i = 1,GetNumGuildMembers(true) do
        if string.lower((GetGuildRosterInfo(i))) == name then
            return i
        end
    end
end
local function IsAlt(plrName)
    local PlayerIndex = GuildNameToIndex(plrName);
	local name,rank,rankindex,level,level,class,note,officernote,online,status,classFilename = GetGuildRosterInfo(PlayerIndex);
    local check = string.match(officernote,"%d+")
    if check == nil then return true
    else return false
    end
end
local function GetPlayerGuildRank(playerName)
    local playerInfo = {}
    local numGuildMembers = GetNumGuildMembers(true)

    for i = 1, numGuildMembers do
        local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
        if name == playerName then
            playerInfo[1] = classDisplayName
            playerInfo[2] = class
            playerInfo[3] = rankName
            break
        end
    end

    return playerInfo
end
local function GetClassColor(class)
    local classColor = RAID_CLASS_COLORS[class]
    if classColor then
        return string.format("ff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    else
        return "ffffffff"  -- Default to white if class color not found
    end
end
local function capitalize(str)
    return str:gsub("(%a)([%w_']*)", function(first, rest) return first:upper()..rest:lower() end)
end
local function FindChannelNumber(channelName)
    local numChannels = GetNumDisplayChannels()
    
    for i = 1, numChannels do
        local name, _, _, _, _, _, number = GetChannelDisplayInfo(i)
        if name == channelName then
            return number
        end
    end

    return nil  -- Channel not found
end
function TimerDone()
    SendChatMessage("Invite send to all 80 lvl online players", "GUILD")
    local guildSize = GetNumGuildMembers()
    for i = 1, guildSize do
        local playerName, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, level = GetGuildRosterInfo(i)
        InviteUnit(playerName)
        ConvertToRaid()
    end
end
function SendRecruitementMessage()
    local channelNumber = FindChannelNumber(channelForSpam)
    SendChatMessage(GManager.db.messageToSpam, "CHANNEL", nil, GManager.db.channelForSpam)
    spamTimerId = TIMER:ScheduleTimer(function()
        SendRecruitementMessage()
    end, GManager.db.timerToSpam)
end

function EVENTS:OnGuildChat(event, message, sender, _, _, _, _, _, _, _, _, _, guid)
    -- Your code to handle guild chat messages goes here
    if message == keywords then
        InviteUnit(sender)
        --print("Invite " .. sender)
    end
end
function EVENTS:OnWhisperReceived(event, message, sender, _, _, _, _, _, _, _, _, _, guid)
    -- Your code to handle guild chat messages goes here
    if message == keywords then
        InviteUnit(sender)
        --print("Invite " .. sender)
    end
end

-- invite player tab 
local function DrawGroup1(container)
    local desc = AceGUI:Create("Label")
    desc:SetText("Invite player to guild")
    desc:SetColor(1, 1, 0)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetJustifyH("CENTER")
    desc:SetFullWidth(true)
    container:AddChild(desc)
end
-- kick player tab
local function DrawGroup2(container)
    
    local list = AceGUI:Create("MultiLineEditBox")
    list:SetLabel("List of all characters")
    list:SetWidth(330)
    list.editBox:SetJustifyH("LEFT")
    list:SetFullWidth(true)
    list:SetFullHeight(true)
    list.frame:SetScript("OnKeyDown", function(self)
        -- Block any attempts to edit the text
        return true
    end)
    list.frame:SetScript("OnMouseDown", function(self)
        -- Block any attempts to set focus (clicking) on the edit box
        return true
    end)
    list:DisableButton(true)
    list:SetNumLines(17)

    local desc = AceGUI:Create("Label")
    desc:SetText("Kick player and his alts")
    desc:SetColor(1, 1, 0)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetJustifyH("CENTER")
    desc:SetFullWidth(true)
    container:AddChild(desc)

    local descc = AceGUI:Create("Label")
    descc:SetText("WARNING: DO NOT SHOW OFFLINE PLAYERS IN THE GUILD!")
    descc:SetColor(1, 0, 0)
    descc:SetFont("Fonts\\FRIZQT__.TTF", 14)
    descc:SetJustifyH("CENTER")
    descc:SetFullWidth(true)
    container:AddChild(descc)

    local editbox = AceGUI:Create("EditBox")
    editbox:SetLabel("Player name:")
    editbox:SetWidth(330)
    editbox:SetFullWidth(true)
    editbox:SetCallback("OnEnterPressed", function(widget, event, text) textStore = firstToUpper(text) end)
    container:AddChild(editbox)
    local button = AceGUI:Create("Button")
    button:SetText("Find Player")
    button:SetWidth(330)
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
        list:SetText("")
        PlayerCharacters = {}
        if IsAlt(textStore) == false then
            for i = 1, GetNumGuildMembers(true) do
                local name, _, _, _, _, _, note, officernote = GetGuildRosterInfo(i)
                if name == textStore or string.find(officernote, textStore) or string.find(note, textStore) then
                    local plrInfo = GetPlayerGuildRank(name)
                    table.insert(PlayerCharacters,name)
                    if list:GetText() == nil or list:GetText() == '' then
                        list:SetText(" |cff00ff00" .. name .. "|r " .. "|cff0070de" .. plrInfo[3] .. "|r " .. " |c" .. GetClassColor(plrInfo[2]).. plrInfo[1] .. "|r")
                    else
                        list:SetText(list:GetText() .. "\n".. " |cff00ff00" .. name .. "|r " .. "|cff0070de" .. plrInfo[3] .. "|r " .. " |c" .. GetClassColor(plrInfo[2]).. plrInfo[1] .. "|r")
                    end
                end
            end 
        else
            local PlayerIndex = GuildNameToIndex(textStore);
	        local name,rank,rankindex,level,level,class,note,officernote,online,status,classFilename = GetGuildRosterInfo(PlayerIndex);
            local MainCharacter = officernote
            for i = 1, GetNumGuildMembers(true) do
                local name, _, _, _, _, _, note, officernote = GetGuildRosterInfo(i)
                if name == MainCharacter or string.find(officernote, MainCharacter) or string.find(note, MainCharacter) then
                    local plrInfo = GetPlayerGuildRank(name)
                    table.insert(PlayerCharacters,name)
                    if list:GetText() == nil or list:GetText() == '' then
                        list:SetText(" |cff00ff00" .. name .. "|r " .. "|cff0070de" .. plrInfo[3] .. "|r " .. " |c" .. GetClassColor(plrInfo[2]).. plrInfo[1] .. "|r")
                    else
                        list:SetText(list:GetText() .. "\n".. " |cff00ff00" .. name .. "|r " .. "|cff0070de" .. plrInfo[3] .. "|r " .. " |c" .. GetClassColor(plrInfo[2]).. plrInfo[1] .. "|r")
                    end
                end
            end 
        end
        
        end)
    container:AddChild(button)
    container:AddChild(list)

    local buttonKick = AceGUI:Create("Button")
    buttonKick:SetText("Kick!")
    buttonKick:SetWidth(330)
    buttonKick:SetFullWidth(true)
    buttonKick:SetCallback("OnClick", function()
        for i = 1, GetNumGuildMembers(true) do
            local name, _, _, _, _, _, note, officernote = GetGuildRosterInfo(i)
            -- Check if the player's name or alt's name matches the provided playerName
            if name == textStore or string.find(officernote, textStore) or string.find(note, textStore) then
                -- Kick the player or alt
                GuildUninvite(name)
                SendChatMessage("Kicked "..name.." from the guild.", "GUILD")
            end
        end
        editbox:SetText("")
        list:SetText("")
        PlayerCharacters = {}
        end)
    container:AddChild(buttonKick)
end
-- mass invite to raid tab
local function DrawGroup3(container)
    local desc = AceGUI:Create("Label")
    desc:SetText("Mass invite guild members to raid")
    desc:SetColor(1, 1, 0)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetJustifyH("CENTER")
    desc:SetFullWidth(true)
    container:AddChild(desc)
    
    local editbox = AceGUI:Create("EditBox")
    editbox:SetLabel("Enter timer (in seconds):")
    editbox:SetWidth(330)
    editbox:SetFullWidth(true)
    editbox:SetCallback("OnEnterPressed", function(widget, event, text) textStore = tonumber(text) end)
    container:AddChild(editbox)

    local editbox2 = AceGUI:Create("EditBox")
    editbox2:SetLabel("Message in guild chat")
    editbox2:SetWidth(330)
    editbox2:SetFullWidth(true)
    editbox2:SetCallback("OnEnterPressed", function(widget, event, text) gmessage = text end)
    container:AddChild(editbox2)

    local editbox3 = AceGUI:Create("EditBox")
    editbox3:SetLabel("Words for autoinvite")
    editbox3:SetWidth(330)
    editbox3:SetFullWidth(true)
    editbox3:SetCallback("OnEnterPressed", function(widget, event, text) keywords = text end)
    container:AddChild(editbox3)

    local btnBeginTimer = AceGUI:Create("Button")
    btnBeginTimer:SetText("Start")
    btnBeginTimer:SetWidth(330)
    btnBeginTimer:SetFullWidth(true)
    btnBeginTimer:SetCallback("OnClick", function()
        if gmessage ~= nil then
            SendChatMessage(gmessage, "GUILD")
        end
        if keywords ~= nil then
            EVENTS:RegisterEvent("CHAT_MSG_GUILD", "OnGuildChat")
            EVENTS:RegisterEvent("CHAT_MSG_WHISPER", "OnWhisperReceived")
            SendChatMessage("Type " .. keywords .. " in guild chat or PM to get invited. Autoinvite will be send after " .. textStore .. " seconds. Leave your groups now!", "GUILD")
        end
        timerId = TIMER:ScheduleTimer(function()
            TimerDone()
        end, textStore)
        end)
    container:AddChild(btnBeginTimer)

    local btnStopTimer = AceGUI:Create("Button")
    btnStopTimer:SetText("Stop")
    btnStopTimer:SetWidth(330)
    btnStopTimer:SetFullWidth(true)
    btnStopTimer:SetCallback("OnClick", function()
            EVENTS:UnregisterEvent("CHAT_MSG_GUILD")
            EVENTS:UnregisterEvent("CHAT_MSG_WHISPER")
            TIMER:CancelTimer(timerId)
        end)
    container:AddChild(btnStopTimer)
end
-- guild info tab
local function DrawGroup4(container)
    local desc = AceGUI:Create("Label")
    desc:SetText("Guild Info")
    desc:SetColor(1, 1, 0)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetJustifyH("CENTER")
    desc:SetFullWidth(true)
    container:AddChild(desc)
    
    local head1 = AceGUI:Create("Heading")
    head1:SetText("Players")
    head1:SetFullWidth(true)
    head1:SetHeight(30)
    container:AddChild(head1)

    local desc2 = AceGUI:Create("Label")
    desc2:SetText("Total: " .. GetNumGuildMembers(true))
    desc2:SetColor(1, 1, 0)
    desc2:SetFont("Fonts\\FRIZQT__.TTF", 14)
    desc2:SetJustifyH("CENTER")
    desc2:SetFullWidth(true)
    container:AddChild(desc2)

    local desc3 = AceGUI:Create("Label")
    desc3:SetText("Online: " .. GetNumGuildMembers())
    desc3:SetColor(1, 1, 0)
    desc3:SetFont("Fonts\\FRIZQT__.TTF", 14)
    desc3:SetJustifyH("CENTER")
    desc3:SetFullWidth(true)
    container:AddChild(desc3)

    local head2 = AceGUI:Create("Heading")
    head2:SetText("Classes")
    head2:SetFullWidth(true)
    head2:SetHeight(30)
    container:AddChild(head2)

    CountClasses()

    local formattedClassCounts = {}
    for classz, count in pairs(classCounts) do
        formattedClassCounts[capitalize(classz)] = count
    end

    local simpleGroup = AceGUI:Create("SimpleGroup")
    simpleGroup:SetLayout("Flow")
    simpleGroup:SetFullWidth(true)
    -- Iterate over classCounts and create icon and label for each class
    for class, count in pairs(formattedClassCounts) do
        -- Create class icon
        local icon = AceGUI:Create("Icon")
        local iconPath = "Interface\\Icons\\ClassIcon_" .. class
        icon:SetImage("Interface\\Icons\\ClassIcon_" .. class)
        icon:SetWidth(10)
        icon:SetHeight(10)
    
        -- Get localized display name for the class
        local displayName = LOCALIZED_CLASS_NAMES_MALE[class] or class
    
        -- Create label for class count using localized display name
        local label = AceGUI:Create("Label")
        label:SetText(displayName .. ": " .. count)
    
        -- Add icon and label to the SimpleGroup
        simpleGroup:AddChildren(label)
    end
    container:AddChild(simpleGroup)
end
-- guild recruit tab
local function DrawGroup5(container)
    local desc = AceGUI:Create("Label")
    desc:SetText("Guild recruit")
    desc:SetColor(1, 1, 0)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetJustifyH("CENTER")
    desc:SetFullWidth(true)
    container:AddChild(desc)

    local editbox = AceGUI:Create("EditBox")
    editbox:SetLabel("Channel NUMBER")
    editbox:SetWidth(330)
    editbox:SetFullWidth(true)
    editbox:SetText(GManager.db.channelForSpam)
    editbox:SetCallback("OnEnterPressed", function(widget, event, text) GManager.db.channelForSpam = tonumber(text) end)
    container:AddChild(editbox)

    local editbox = AceGUI:Create("EditBox")
    editbox:SetLabel("Time in seconds (min 68 sec)")
    editbox:SetWidth(330)
    editbox:SetText(GManager.db.timerToSpam)
    editbox:SetFullWidth(true)
    editbox:SetCallback("OnEnterPressed", function(widget, event, text) GManager.db.timerToSpam = tonumber(text) end)
    container:AddChild(editbox)

    local messageBox = AceGUI:Create("MultiLineEditBox")
    messageBox:SetLabel("Message")
    messageBox:SetWidth(330)
    messageBox:SetText(GManager.db.messageToSpam)
    messageBox:SetFullWidth(true)
    messageBox:SetCallback("OnEnterPressed", function(widget, event, text) GManager.db.messageToSpam = text end)
    container:AddChild(messageBox)

    local btnBeginTimer = AceGUI:Create("Button")
    btnBeginTimer:SetText("Start spam")
    btnBeginTimer:SetWidth(330)
    btnBeginTimer:SetFullWidth(true)
    btnBeginTimer:SetCallback("OnClick", function()
        spamTimerId = TIMER:ScheduleTimer(function()
            SendRecruitementMessage()
        end, GManager.db.timerToSpam)
        end)
    container:AddChild(btnBeginTimer)

    local btnStopTimer = AceGUI:Create("Button")
    btnStopTimer:SetText("Stop spam")
    btnStopTimer:SetWidth(330)
    btnStopTimer:SetFullWidth(true)
    btnStopTimer:SetCallback("OnClick", function()
            TIMER:CancelTimer(spamTimerId)
        end)
    container:AddChild(btnStopTimer)

end
-- settings tab
local function DrawGroup6(container)
    local desc = AceGUI:Create("Label")
    desc:SetText("Settings")
    desc:SetColor(1, 1, 0)
    desc:SetFont("Fonts\\FRIZQT__.TTF", 18)
    desc:SetJustifyH("CENTER")
    desc:SetFullWidth(true)
    container:AddChild(desc)
end
-- Callback function for OnGroupSelected
local function SelectGroup(container, event, group)
    container:ReleaseChildren()
    if group == "tab1" then
        DrawGroup1(container)
    elseif group == "tab2" then
        DrawGroup2(container)
    elseif group == "tab3" then
        DrawGroup3(container)
    elseif group == "tab4" then
        DrawGroup4(container)
    elseif group == "tab5" then
        DrawGroup5(container)
    elseif group == "tab6" then
        DrawGroup6(container)
    end
end
-- Create the frame container
local function showFrame()
    if frameShown then
      return
    end
    frameShown = true
    local frame = AceGUI:Create("Frame")
    frame:SetHeight(500)
    frame:SetWidth(550)
    frame:SetTitle(guildName)
    frame:SetLayout("Fill")
    frame:SetCallback("OnClose",function(widget) AceGUI:Release(widget) frameShown = false end)
    local tab =  AceGUI:Create("TabGroup")
    tab:SetLayout("List")
    -- Setup which tabs to show
    tab:SetTabs({{text="Invite", value="tab1"}, {text="Kick", value="tab2"},{text="Mass Invite",value="tab3"},{text="Guild Info",value="tab4"},{text="Recruit",value="tab5"},{text="Settings",value="tab6"}})
    -- Register callback
    tab:SetCallback("OnGroupSelected", SelectGroup)
    -- Set initial Tab (this will fire the OnGroupSelected callback)
    tab:SelectTab("tab4")
    -- add to the frame container
    frame:AddChild(tab)
  end
-- MINIMAP BUTTON
local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("GManagerIcon", {
    type = "data source",
    text = "Guild Management System",
    icon = "Interface\\HELPFRAME\\HelpIcon-KnowledgeBase",
    OnClick = function(self, btn)
        -- OnClick code goes here
        showFrame()
    end,
    OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then return end
        tooltip:AddLine("Guild Management System")
    end,
    })
    local icon = LibStub("LibDBIcon-1.0", true)
    icon:Register("GManagerIcon", miniButton, GManagerDB)
-- MINIMAP BUTTON
function GManager:OnInitialize()
	-- Called when the addon is loaded
    
end
function GManager:OnEnable()
	-- Called when the addon is enabled
end
function GManager:OnDisable()
	-- Called when the addon is disabled
end
