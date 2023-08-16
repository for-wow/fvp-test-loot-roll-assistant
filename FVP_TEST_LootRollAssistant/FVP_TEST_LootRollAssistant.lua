local LRA = {} -- Loot Roll Assistant
 
LRA.Debug = true
 
local PickList = {[0] = 'Pass', [1] = 'Need', [2] = 'Greed'}
 
LRA.Init = CreateFrame('FRAME')
LRA.Init:RegisterEvent('PLAYER_LOGIN')
LRA.Init:SetScript('OnEvent', function()
    LRA_SETTINGS = LRA_SETTINGS or {['Assist'] = true, ['Button'] = true}
    SVC_LRA_ITEMS = SVC_LRA_ITEMS or {} -- todo rename
 
    LRA:UpdateState()
 
    LRA.Init = nil
end)
 
LRA.Info = CreateFrame('FRAME') -- leave for now, but then merge with LRA.Main
LRA.Info:RegisterEvent('START_LOOT_ROLL')
LRA.Info:SetScript('OnEvent', function() -- put it in a separate function
    local retOK, link, id, quality, class, subclass, isBoP = pcall(LRA.GetLootRollItemInfo, self, arg1)
    if retOK then
        LRA:AddonMsg(link .. ' : id="' .. id .. '" type="' .. class .. '" subtype="' .. subclass .. '" bind="' .. isBoP .. '"')
    else
        LRA:ErrorMsg(link)
    end
end)
 
LRA.Main = CreateFrame('FRAME')
--LRA.Main:RegisterEvent('START_LOOT_ROLL')
LRA.Main:SetScript('OnEvent', function() -- put it in a separate function
    local retOK, roll = pcall(LRA.GetRollPickByItem, self, arg1)
    if retOK and roll ~= -1 then
 
        if roll == 0 then
            LRA:DebugMsg('ID=' .. ({string.find(GetLootRollItemLink(arg1), "item:(%d+)")})[3] .. ' - Try Roll Pass')
        elseif roll == 1 then
            LRA:DebugMsg('ID=' .. ({string.find(GetLootRollItemLink(arg1), "item:(%d+)")})[3] .. ' - Try Roll Need')
        elseif roll == 2 then
            LRA:DebugMsg('ID=' .. ({string.find(GetLootRollItemLink(arg1), "item:(%d+)")})[3] .. ' - Try Roll Greed')
        else
            LRA:DebugMsg('ID=' .. ({string.find(GetLootRollItemLink(arg1), "item:(%d+)")})[3] .. ' - Try Roll UNKNOWN')
        end
 
        RollOnLoot(arg1, roll)
        return
    end
end)
 
CreateFrame('BUTTON', 'LRA_BtnAddon', Minimap)
LRA_BtnAddon:SetPoint('CENTER', Minimap, -64, -44)
LRA_BtnAddon:SetWidth(32)
LRA_BtnAddon:SetHeight(32)
LRA_BtnAddon:EnableMouse(true)
LRA_BtnAddon:SetMovable(true)
LRA_BtnAddon:RegisterForDrag("LeftButton")
LRA_BtnAddon:SetClampedToScreen(true)
LRA_BtnAddon:SetScript("OnDragStart", function() if IsShiftKeyDown() then this:StartMoving() end end)
LRA_BtnAddon:SetScript("OnDragStop",  function() this:StopMovingOrSizing() end)
LRA_BtnAddon:SetScript('OnEnter',     function() LRA:TooltipShow() end)
LRA_BtnAddon:SetScript('OnLeave',     function() LRA:TooltipHide() end)
LRA_BtnAddon:SetScript('OnClick',     function() LRA:AssistToggle() end)
 
LRA_BtnAddon.Tex = LRA_BtnAddon:CreateTexture(nil, 'ARTWORK')
LRA_BtnAddon.Tex:SetAllPoints(LRA_BtnAddon)


 
-- Returns: link (str), id (num), quality (num), class (str), subclass (str), isBoP (str)
function LRA:GetLootRollItemInfo(rollId)
    local link = GetLootRollItemLink(rollId)
    local id = ({string.find(link, "item:(%d+)")})[3]
    local _, _, quality, _, class, subclass = GetItemInfo(id) -- input parameter <link> - not working
    local isBoP = ({GetLootRollItemInfo(rollId)})[5]
 
    if isBoP then
        isBoP = 'BoP'
    else
        isBoP = 'not BoP'
    end
            
    return link, id, quality, class, subclass, isBoP
end
 
function LRA:GetRollPickByItem(rollId)
    local pick = SVC_LRA_ITEMS[tonumber(({string.find(GetLootRollItemLink(rollId), "item:(%d+)")})[3])]
    if pick ~= 0 and pick ~= 1 and pick ~= 2 then
        return -1
    else
        return pick
    end
end
 
function LRA:UpdateState()
    if LRA_SETTINGS.Assist then
        LRA.Main:RegisterEvent('START_LOOT_ROLL')
        LRA_BtnAddon.Tex:SetTexture('Interface\\AddOns\\V+RollAssistant\\Btn-Assist-On')
        LRA:AddonMsg('Enable roll assist')
    else
        LRA.Main:UnregisterEvent('START_LOOT_ROLL')
        LRA_BtnAddon.Tex:SetTexture('Interface\\AddOns\\V+RollAssistant\\Btn-Assist-Off')
        LRA:AddonMsg('Disable roll assist')
    end
    
    if LRA_SETTINGS.Button then
        LRA_BtnAddon:Show()
    else
        LRA_BtnAddon:Hide()
    end
end
 
function LRA:TooltipShow()
    GameTooltip:SetOwner(LRA_BtnAddon, 'ANCHOR_LEFT')
    GameTooltip:ClearLines()
    GameTooltip:AddLine('V+RollAssistant')
    if LRA_SETTINGS.Assist then
        GameTooltip:AddLine('Assist: on')
    else
        GameTooltip:AddLine('Assist: |cFFFF0000off|r')
    end
    GameTooltip:Show()
end
 
function LRA:TooltipHide()
    GameTooltip:Hide()
end
 
function LRA:Call_AssistToggle() -- for pcall
    LRA_SETTINGS.Assist = not LRA_SETTINGS.Assist
end
 
function LRA:AssistToggle()
    local done, res = pcall(LRA.Call_AssistToggle, self)
    if done then
        LRA:UpdateState()
        LRA:TooltipShow()
    else
        LRA:ErrorMsg('Failed toggle assist status. ' .. res)
    end
end
 
function LRA:AddonMsg(str)
    DEFAULT_CHAT_FRAME:AddMessage('V+RollAssistant: ' .. str)
end
 
function LRA:ErrorMsg(str)
    DEFAULT_CHAT_FRAME:AddMessage('|cFFFF0000V+RollAssistant Error: ' .. str .. '|r')
end
 
function LRA:DebugMsg(str)
    if LRA.Debug then
        DEFAULT_CHAT_FRAME:AddMessage('V+RollAssistant Debug: ' .. str)
    end
end

 
SLASH_LRA_CMD1 = '/lra'
function SlashCmdList.LRA_CMD(msg)
    if msg == '' then
        LRA:AddonMsg('Commands:')
        DEFAULT_CHAT_FRAME:AddMessage('/lra assist <param> - Toggle roll assist value.')
        DEFAULT_CHAT_FRAME:AddMessage('     param: "on" - Enable roll assist, "off" - Disable roll assist')
        DEFAULT_CHAT_FRAME:AddMessage('/lra button <param> - Toggle visibility addon button near the minimap.')
        DEFAULT_CHAT_FRAME:AddMessage('     param: "on" - Show addon button, "off" - Hide addon button')
        DEFAULT_CHAT_FRAME:AddMessage('/lra debug <param> - Toggle debug information output.')
        DEFAULT_CHAT_FRAME:AddMessage('     param: "on" - Show debug information, "off" - Hide debug information')
        DEFAULT_CHAT_FRAME:AddMessage('/lra iget - Display the table of loot options for given item IDs.')
        DEFAULT_CHAT_FRAME:AddMessage('/lra iset <item id> <param> - Set roll pick value for an item id.')
        DEFAULT_CHAT_FRAME:AddMessage('     param: "n" - Roll Need, "g" - Roll Greed, "p" - Roll Pass')
        DEFAULT_CHAT_FRAME:AddMessage('/lra idel <item id> - Del roll pick value for an item id.')
    else
        local param = LRA:StrSplit(msg)
        if param[1] == 'assist' then
            if param[2] == 'on' then
                LRA_SETTINGS.Assist = true
                LRA:UpdateState()
            elseif param[2] == 'off' then
                LRA_SETTINGS.Assist = false
                LRA:UpdateState()
            else
                LRA:ErrorMsg('Invalid command format. Type "/lra" to display a list of commands.')
            end
          elseif param[1] == 'button' then
            if param[2] == 'on' then
                LRA_SETTINGS.Button = true
                LRA_BtnAddon:Show()
                LRA:AddonMsg('Show addon button')
            elseif param[2] == 'off' then
                LRA_SETTINGS.Button = false
                LRA_BtnAddon:Hide()
                LRA:AddonMsg('Hide addon button')
            else
                LRA:ErrorMsg('Invalid command format. Type "/lra" to display a list of commands.')
            end
        elseif param[1] == 'debug' then
            if param[2] == 'on' then
                LRA.Debug = true
                LRA:AddonMsg('Show debug information')
            elseif param[2] == 'off' then
                LRA.Debug = false
                LRA:AddonMsg('Hide debug information')
            else
                LRA:ErrorMsg('Invalid command format. Type "/lra" to display a list of commands.')
            end
        elseif param[1] == 'iget' then
            LRA:GetItems()
        elseif param[1] == 'iset' then
            if param[3] == 'n' then
                local retOK, retRes = pcall(LRA.SetItem, self, param[2], 1) -- https://stackoverflow.com/questions/732607
                if retOK and retRes then
                    LRA:AddonMsg('Set item id = ' .. param[2] .. ' pick = ' .. PickList[1])
                else
                    LRA:ErrorMsg('Set item id = ' .. param[2] .. ' pick = ' .. param[3])
                end
            elseif param[3] == 'g' then
                local retOK, retRes = pcall(LRA.SetItem, self, param[2], 2)
                if retOK and retRes then
                    LRA:AddonMsg('Set item id = ' .. param[2] .. ' pick = ' .. PickList[2])
                else
                    LRA:ErrorMsg('Set item id = ' .. param[2] .. ' pick = ' .. param[3])
                end
            elseif param[3] == 'p' then
                local retOK, retRes = pcall(LRA.SetItem, self, param[2], 0)
                if retOK and retRes then
                    LRA:AddonMsg('Set item id = ' .. param[2] .. ' pick = ' .. PickList[0])
                else
                    LRA:ErrorMsg('Set item id = ' .. param[2] .. ' pick = ' .. param[3])
                end
            else
                LRA:ErrorMsg('Invalid command format. Type "/lra" to display a list of commands.')
            end
        elseif param[1] == 'idel' then
            local retOK = pcall(LRA.DelItem, self, param[2])
            if retOK then
                LRA:AddonMsg('Removed item id = ' .. param[2])
            else
                LRA:ErrorMsg('Removed item - ERROR')
            end
        else
            LRA:ErrorMsg('Invalid command format. Type "/lra" to display a list of commands.')
        end
    end
end
 
function LRA:StrSplit(str)
    local res = {}
    for v in string.gfind(str, "[^ ]+") do
        tinsert(res, v)
    end
    return res
end
 
function LRA:GetItems()
    LRA:AddonMsg('Items list:')
    for k, v in pairs(SVC_LRA_ITEMS) do
        DEFAULT_CHAT_FRAME:AddMessage('item id = ' .. k .. ' pick = ' .. PickList[v])
    end
end
 
function LRA:SetItem(itemId, rollPick) -- for pcall
    pick = tonumber(rollPick)
    if pick ~= 0 and pick ~= 1 and pick ~= 2 then
        LRA:ErrorMsg('Invalid pick = ' .. pick)
        return false
    else
        SVC_LRA_ITEMS[tonumber(itemId)] = pick
        return true
    end
end
 
function LRA:DelItem(itemId) -- for pcall
    SVC_LRA_ITEMS[tonumber(itemId)] = nil
end
