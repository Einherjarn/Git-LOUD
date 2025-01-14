--- File: lua/modules/ui/game/chat.lua
--- Author: Chris Blackwell
--- Summary: In game chat ui

local UIUtil = import('/lua/ui/uiutil.lua')

local LayoutHelpers = import('/lua/maui/layouthelpers.lua')

local Group = import('/lua/maui/group.lua').Group
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Text = import('/lua/maui/text.lua').Text
local Edit = import('/lua/maui/edit.lua').Edit
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap

local Window = import('/lua/maui/window.lua').Window
local BitmapCombo = import('/lua/ui/controls/combo.lua').BitmapCombo
local IntegerSlider = import('/lua/maui/slider.lua').IntegerSlider
local Prefs = import('/lua/user/prefs.lua')

local Tooltip = import('/lua/ui/game/tooltip.lua')
local UIMain = import('/lua/ui/uimain.lua')

local CHAT_INACTIVITY_TIMEOUT = 15  -- in seconds

local savedParent = false

local chatHistory = {}
local commandHistory = {}

local ChatTo = import('/lua/lazyvar.lua').Create()
local defOptions = { all_color = 1, allies_color = 2, priv_color = 3, link_color = 4, font_size = 14, fade_time = 15, win_alpha = 1}
local ChatOptions = Prefs.GetFromCurrentProfile("chatoptions") or defOptions

GUI = {
    bg = false,
    chatLines = {},
    chatContainer = false,
    config = false,
}

local chatColors = {'ffffffff', 'ffff4242', 'ffefff42','ff4fff42', 'ff42fff8', 'ff424fff', 'ffff42eb'}

local ToStrings = {
    to = {text = '<LOC chat_0000>to', caps = '<LOC chat_0001>To', colorkey = 'all_color'},
    allies = {text = '<LOC chat_0002>to allies:', caps = '<LOC chat_0003>To Allies:', colorkey = 'allies_color'},
    all = {text = '<LOC chat_0004>to all:', caps = '<LOC chat_0005>To All:', colorkey = 'all_color'},
    private = {text = '<LOC chat_0006>to you:', caps = '<LOC chat_0007>To You:', colorkey = 'priv_color'},
}

function SetLayout()
    import(UIUtil.GetLayoutFilename('chat')).SetLayout()
end

function CreateChatBackground()
    local location = {Top = function() return GetFrame(0).Bottom() - 393 end,
        Left = function() return GetFrame(0).Left() + 8 end,
        Right = function() return GetFrame(0).Left() + 430 end,
        Bottom = function() return GetFrame(0).Bottom() - 238 end}
    local bg = Window(GetFrame(0), '', nil, true, true, nil, nil, 'chat_window', location)
    bg.Depth:Set(200)
    
    bg.DragTL = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    bg.DragTR = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    bg.DragBL = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    bg.DragBR = Bitmap(bg, UIUtil.UIFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))
    
    local controlMap = {
        tl = {bg.DragTL},
        tr = {bg.DragTR},
        bl = {bg.DragBL},
        br = {bg.DragBR},
        mr = {bg.DragBR,bg.DragTR},
        ml = {bg.DragBL,bg.DragTL},
        tm = {bg.DragTL,bg.DragTR},
        bm = {bg.DragBL,bg.DragBR},
    }
    
    bg.RolloverHandler = function(control, event, xControl, yControl, cursor, controlID)
        if bg._lockSize then return end
        local styles = import('/lua/maui/window.lua').styles
        if not bg._sizeLock then
            if event.Type == 'MouseEnter' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.over)
                    end
                end
                GetCursor():SetTexture(styles.cursorFunc(cursor))
            elseif event.Type == 'MouseExit' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.up)
                    end
                end
                GetCursor():Reset()
            elseif event.Type == 'ButtonPress' then
                if controlMap[controlID] then
                    for _, control in controlMap[controlID] do
                        control:SetTexture(control.textures.down)
                    end
                end
                bg.StartSizing(event, xControl, yControl)
                bg._sizeLock = true
            end
        end
    end
    
    bg.OnResizeSet = function(control)
        bg.DragTL:SetTexture(bg.DragTL.textures.up)
        bg.DragTR:SetTexture(bg.DragTR.textures.up)
        bg.DragBL:SetTexture(bg.DragBL.textures.up)
        bg.DragBR:SetTexture(bg.DragBR.textures.up)
    end
    
    bg.DragTL.Left:Set(function() return bg.Left() - 26 end)
    bg.DragTL.Top:Set(function() return bg.Top() - 6 end)
    bg.DragTL.Depth:Set(220)
    bg.DragTL:DisableHitTest()
    
    bg.DragTR.Right:Set(function() return bg.Right() + 22 end)
    bg.DragTR.Top:Set(function() return bg.Top() - 8 end)
    bg.DragTR.Depth:Set(bg.DragTL.Depth)
    bg.DragTR:DisableHitTest()
    
    bg.DragBL.Left:Set(function() return bg.Left() - 26 end)
    bg.DragBL.Bottom:Set(function() return bg.Bottom() + 8 end)
    bg.DragBL.Depth:Set(bg.DragTL.Depth)
    bg.DragBL:DisableHitTest()
    
    bg.DragBR.Right:Set(function() return bg.Right() + 22 end)
    bg.DragBR.Bottom:Set(function() return bg.Bottom() + 8 end)
    bg.DragBR.Depth:Set(bg.DragTL.Depth)
    bg.DragBR:DisableHitTest()
    
    bg.ResetPositionBtn = Button(bg,
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_up.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_down.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_over.dds'),
        UIUtil.SkinnableFile('/game/menu-btns/default_btn_dis.dds'))
		
    LayoutHelpers.LeftOf(bg.ResetPositionBtn, bg._configBtn)
	
    bg.ResetPositionBtn.Depth:Set(function() return bg.Depth() + 10 end)
	
    bg.ResetPositionBtn.OnClick = function(self, modifiers) 
        for index, position in location do
            local i = index
            local pos = position
            bg[i]:Set(pos)
        end
        CreateChatLines()
        bg:SaveWindowLocation()
    end
    
    Tooltip.AddButtonTooltip(bg.ResetPositionBtn, 'chat_reset')    
    
    bg:SetMinimumResize(400, 160)
    return bg
end

function CreateChatLines()
    local function CreateChatLine()
        local line = Group(GUI.chatContainer)
        
        line.teamColor = Bitmap(line)
        line.teamColor:SetSolidColor('00000000')
        line.teamColor.Height:Set(line.Height)
        line.teamColor.Width:Set(line.Height)
        line.teamColor.Left:Set(line.Left)
        line.teamColor.Top:Set(line.Top)
        
        line.topBG = Bitmap(line)
        line.topBG:SetSolidColor('00000000')
        line.topBG.Height:Set(2)
        line.topBG.Left:Set(line.Left)
        line.topBG.Right:Set(line.Right)
        line.topBG.Bottom:Set(line.Top)
        
        line.leftBG = Bitmap(line)
        line.leftBG:SetSolidColor('00000000')
        line.leftBG.Width:Set(1)
        line.leftBG.Right:Set(line.Left)
        line.leftBG.Top:Set(line.topBG.Top)
        line.leftBG.Bottom:Set(line.Bottom)
        
        line.rightBG = Bitmap(line)
        line.rightBG:SetSolidColor('00000000')
        line.rightBG.Width:Set(1)
        line.rightBG.Left:Set(line.Right)
        line.rightBG.Top:Set(line.topBG.Top)
        line.rightBG.Bottom:Set(line.Bottom)

        line.factionIcon = Bitmap(line.teamColor)
        line.factionIcon:SetSolidColor('00000000')
        LayoutHelpers.FillParent(line.factionIcon, line.teamColor)
        
        line.name = UIUtil.CreateText(line, '', ChatOptions.font_size, "Arial Bold")
        line.name.Left:Set(function() return line.teamColor.Right() + 4 end)
        LayoutHelpers.AtVerticalCenterIn(line.name, line.teamColor)
        line.name.Depth:Set(function() return line.Depth() + 10 end)
        line.name:SetColor('ffffffff')
        line.name:DisableHitTest()
        
        line.nameBG = Bitmap(line.name)
        line.nameBG:SetSolidColor('00000000')
        line.nameBG.Depth:Set(function() return line.name.Depth() - 1 end)
        line.nameBG.Left:Set(line.teamColor.Right)
        line.nameBG.Right:Set(function() return line.name.Right() + 4 end)
        line.nameBG.Top:Set(line.teamColor.Top)
        line.nameBG.Bottom:Set(line.teamColor.Bottom)
		
        line.nameBG.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('aa000000')
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('00000000')
            elseif event.Type == 'ButtonPress' then
                if line.chatID then
                    if GUI.bg:IsHidden() then GUI.bg:Show() end
                    ChatTo:Set(line.chatID)
                    if GUI.chatEdit.edit then
                        GUI.chatEdit.edit:AcquireFocus()
                    end
                    if GUI.chatEdit.private then
                        GUI.chatEdit.private:SetCheck(true)
                    end
                end
            end
        end
        
        line.text = UIUtil.CreateText(line, '', ChatOptions.font_size, "Arial")
        line.text.Depth:Set(function() return line.Depth() + 10 end)
        line.text.Left:Set(function() return line.nameBG.Right() + 2 end)
        line.text.Right:Set(line.Right)
        line.text:SetClipToWidth(true)
        line.text:DisableHitTest()
        line.text:SetColor('ffc2f6ff')
        LayoutHelpers.AtVerticalCenterIn(line.text, line.teamColor)
        
        line.textBG = Bitmap(line)
        line.textBG.Depth:Set(function() return line.text.Depth() - 1 end)
        line.textBG.Left:Set(line.nameBG.Right)
        line.textBG.Top:Set(line.teamColor.Top)
        line.textBG.Right:Set(line.Right)
        line.textBG.Bottom:Set(line.teamColor.Bottom)
        line.textBG:Disable()
		
        line.textBG.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                for i, v in GUI.chatLines do
                    if v.EntryID == line.EntryID then
                        v.topBG.Right:Set(v.Right)
                        v.nameBG:SetSolidColor('00000000')
                        v.textBG:SetSolidColor('00000000')
                    end
                end
            elseif event.Type == 'MouseExit' then
                for i, v in GUI.chatLines do
                    if v.EntryID == line.EntryID then
                        if not v.IsTop then
                            v.topBG.Right:Set(v.teamColor.Right)
                        end
                        v.nameBG:SetSolidColor('00000000')
                        v.textBG:SetSolidColor('00000000')
                    end
                end
            elseif event.Type == 'ButtonPress' then
                if line.cameraData then
                    GetCamera('WorldCamera'):RestoreSettings(line.cameraData)
                end
            end
        end
        
        return line
    end
    if GUI.chatContainer then
        local curEntries = table.getsize(GUI.chatLines)
        local neededEntries = math.floor(GUI.chatContainer.Height() / (GUI.chatLines[1].Height() + 2))
        if curEntries - neededEntries == 0 then
            return
        elseif curEntries - neededEntries < 0 then
            for i = curEntries + 1, neededEntries do
                local index = i
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 2)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 4 end)
                GUI.chatLines[index].Right:Set(GUI.chatContainer.Right)
            end
        elseif curEntries - neededEntries > 0 then
            for i = neededEntries + 1, curEntries do
                if GUI.chatLines[i] then
                    GUI.chatLines[i]:Destroy()
                    GUI.chatLines[i] = nil
                end
            end
        end
    else
        local clientArea = GUI.bg:GetClientGroup()
        GUI.chatContainer = Group(clientArea)
        GUI.chatContainer.Left:Set(function() return clientArea.Left() + 10 end)
        GUI.chatContainer.Top:Set(function() return clientArea.Top() + 2 end)
        GUI.chatContainer.Right:Set(function() return clientArea.Right() - 38 end)
        GUI.chatContainer.Bottom:Set(function() return GUI.chatEdit.Top() - 10 end)
        
        SetupChatScroll()
        
        if not GUI.chatLines[1] then
            GUI.chatLines[1] = CreateChatLine()
            LayoutHelpers.AtLeftTopIn(GUI.chatLines[1], GUI.chatContainer, 0, 0)
            GUI.chatLines[1].Height:Set(function() return GUI.chatLines[1].name.Height() + 4 end)
            GUI.chatLines[1].Right:Set(GUI.chatContainer.Right)
        end
        local index = 1
        while GUI.chatLines[index].Bottom() + GUI.chatLines[1].Height() < GUI.chatContainer.Bottom() do
            index = index + 1
            if not GUI.chatLines[index] then
                GUI.chatLines[index] = CreateChatLine()
                LayoutHelpers.Below(GUI.chatLines[index], GUI.chatLines[index-1], 2)
                GUI.chatLines[index].Height:Set(function() return GUI.chatLines[index].name.Height() + 4 end)
                GUI.chatLines[index].Right:Set(GUI.chatContainer.Right)
            end
        end
    end
end

function OnNISBegin()
    CloseChat()
end

function SetupChatScroll()
    GUI.chatContainer.top = 1
    GUI.chatContainer.scroll = UIUtil.CreateVertScrollbarFor(GUI.chatContainer)
    
    local numLines = function() return table.getsize(GUI.chatLines) end
    GUI.chatContainer.prevtabsize = 0
    GUI.chatContainer.prevsize = 0
    
    local function IsValidEntry(entryData)
        local result = true
        if entryData.camera then
            result = ChatOptions.links
        else
            result = ChatOptions[entryData.armyID]
        end
        return result
    end
    
    local function DataSize()
        if GUI.chatContainer.prevtabsize != table.getn(chatHistory) then
            local size = 0
            for i, v in chatHistory do
                if IsValidEntry(v) then
                    size = size + table.getn(v.wrappedtext)
                end
            end
            GUI.chatContainer.prevtabsize = table.getn(chatHistory)
            GUI.chatContainer.prevsize = size
        end
        return GUI.chatContainer.prevsize
    end
    
    -- called when the scrollbar for the control requires data to size itself
    -- GetScrollValues must return 4 values in this order:
    -- rangeMin, rangeMax, visibleMin, visibleMax
    -- aixs can be "Vert" or "Horz"
    GUI.chatContainer.GetScrollValues = function(self, axis)
        local size = DataSize()
        --LOG(size, ":", self.top, ":", math.min(self.top + numLines(), size))
        return 1, size, self.top, math.min(self.top + numLines(), size)
    end

    -- called when the scrollbar wants to scroll a specific number of lines (negative indicates scroll up)
    GUI.chatContainer.ScrollLines = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta))
    end

    -- called when the scrollbar wants to scroll a specific number of pages (negative indicates scroll up)
    GUI.chatContainer.ScrollPages = function(self, axis, delta)
        self:ScrollSetTop(axis, self.top + math.floor(delta) * numLines())
    end

    -- called when the scrollbar wants to set a new visible top line
    GUI.chatContainer.ScrollSetTop = function(self, axis, top)
        top = math.floor(top)
        if top == self.top then return end
        local size = DataSize()
        self.top = math.max(math.min(size - numLines()+1, top), 1)
        self:CalcVisible()
    end

    -- called to determine if the control is scrollable on a particular access. Must return true or false.
    GUI.chatContainer.IsScrollable = function(self, axis)
        return true
    end
    
    GUI.chatContainer.ScrollToBottom = function(self)
        --LOG(DataSize())
        GUI.chatContainer:ScrollSetTop(nil, DataSize())
    end
    
    -- determines what controls should be visible or not
    GUI.chatContainer.CalcVisible = function(self)
	
        GUI.bg.curTime = 0
		
        local index = 1
        local tempTop = self.top
        local curEntry = 1
        local curTop = 1
        local tempsize = 0
		
        for i, v in chatHistory do
		
            if IsValidEntry(v) then
                if tempsize + table.getsize(v.wrappedtext) < tempTop then
                    tempsize = tempsize + table.getsize(v.wrappedtext)
                else
                    curEntry = i
                    for h, x in v.wrappedtext do
                        if h + tempsize == tempTop then
                            curTop = h
                            break
                        end
                    end
                    break
                end
            end
			
        end
		
        while GUI.chatLines[index] do
		
            if not chatHistory[curEntry].wrappedtext[curTop] then
			
                if chatHistory[curEntry].new then chatHistory[curEntry].new = nil end
				
                curTop = 1
                curEntry = curEntry + 1
				
                while chatHistory[curEntry] and not IsValidEntry(chatHistory[curEntry]) do
                    curEntry = curEntry + 1
                end
            end
			
            if chatHistory[curEntry] then
                local Index = index
                if curTop == 1 then
                    GUI.chatLines[index].name:SetText(chatHistory[curEntry].name)
                    if chatHistory[curEntry].armyID == GetFocusArmy() then
                        GUI.chatLines[index].nameBG:Disable()
                    else
                        GUI.chatLines[index].nameBG:Enable()
                    end
                    GUI.chatLines[index].text:SetText(chatHistory[curEntry].wrappedtext[curTop] or "")
                    GUI.chatLines[index].teamColor:SetSolidColor(chatHistory[curEntry].color)
                    GUI.chatLines[index].factionIcon:SetTexture(UIUtil.UIFile(import('/lua/factions.lua').Factions[chatHistory[curEntry].faction].Icon))
                    GUI.chatLines[index].topBG.Right:Set(GUI.chatLines[index].Right)
                    GUI.chatLines[index].IsTop = true
                    GUI.chatLines[index].chatID = chatHistory[curEntry].armyID
                    if chatHistory[curEntry].camera and not GUI.chatLines[index].camIcon then
                        GUI.chatLines[index].camIcon = Bitmap(GUI.chatLines[index].textBG, UIUtil.UIFile('/game/camera-btn/pinned_btn_up.dds'))
                        GUI.chatLines[index].camIcon.Height:Set(16)
                        GUI.chatLines[index].camIcon.Width:Set(20)
                        LayoutHelpers.AtVerticalCenterIn(GUI.chatLines[index].camIcon, GUI.chatLines[index].teamColor)
                        GUI.chatLines[index].camIcon.Left:Set(function() return GUI.chatLines[Index].name.Right() + 4 end)
                        GUI.chatLines[index].text.Left:Set(function() return GUI.chatLines[Index].camIcon.Right() + 4 end)
                    elseif not chatHistory[curEntry].camera and GUI.chatLines[index].camIcon then
                        GUI.chatLines[index].camIcon:Destroy()
                        GUI.chatLines[index].camIcon = false
                        GUI.chatLines[index].text.Left:Set(function() return GUI.chatLines[Index].nameBG.Right() + 2 end)
                    end
                else
                    GUI.chatLines[index].topBG.Right:Set(GUI.chatLines[index].teamColor.Right)
                    GUI.chatLines[index].nameBG:Disable()
                    GUI.chatLines[index].name:SetText('')
                    GUI.chatLines[index].text:SetText(chatHistory[curEntry].wrappedtext[curTop] or "")
                    GUI.chatLines[index].teamColor:SetSolidColor('00000000')
                    GUI.chatLines[index].factionIcon:SetSolidColor('00000000')
                    GUI.chatLines[index].IsTop = false
                    if GUI.chatLines[index].camIcon then
                        GUI.chatLines[index].camIcon:Destroy()
                        GUI.chatLines[index].camIcon = false
                        GUI.chatLines[index].text.Left:Set(function() return GUI.chatLines[Index].nameBG.Right() + 2 end)
                    end
                end
                if chatHistory[curEntry].camera then
                    GUI.chatLines[index].cameraData = chatHistory[curEntry].camera
                    GUI.chatLines[index].textBG:Enable()
                    GUI.chatLines[index].text:SetColor(chatColors[ChatOptions.link_color])
                else
                    GUI.chatLines[index].textBG:Disable()
                    GUI.chatLines[index].text:SetColor('ffc2f6ff')
                    GUI.chatLines[index].text:SetColor(chatColors[ChatOptions[chatHistory[curEntry].tokey]])
                end
                if not GUI.bg:IsHidden() then
                    GUI.chatLines[index].rightBG:Show()
                    GUI.chatLines[index].leftBG:Show()
                end
                GUI.chatLines[index].textBG:SetSolidColor('00000000')
                GUI.chatLines[index].nameBG:SetSolidColor('00000000')
                GUI.chatLines[index].EntryID = curEntry
                if chatHistory[curEntry].new and GUI.bg:IsHidden() then 
                    GUI.chatLines[index]:Show()
                    GUI.chatLines[index].topBG:Hide()
                    GUI.chatLines[index].rightBG:Hide()
                    GUI.chatLines[index].leftBG:Hide()
                    if GUI.chatLines[index].name:GetText() == '' then
                        GUI.chatLines[index].teamColor:Hide()
                    end
                    GUI.chatLines[index].time = 0
                    GUI.chatLines[index].OnFrame = function(self, delta)
                        self.time = self.time + delta
                        if self.time > ChatOptions.fade_time then
                            if GUI.bg:IsHidden() then
                                self:Hide()
                            end
                            self:SetNeedsFrameUpdate(false)
                        end
                    end
                    GUI.chatLines[index]:SetNeedsFrameUpdate(true)
                end
            else
                GUI.chatLines[index].nameBG:Disable()
                GUI.chatLines[index].name:SetText('')
                GUI.chatLines[index].text:SetText('')
                GUI.chatLines[index].teamColor:SetSolidColor('00000000')
                GUI.chatLines[index].textBG:SetSolidColor('00000000')
                GUI.chatLines[index].nameBG:SetSolidColor('00000000')
                GUI.chatLines[index].topBG:SetSolidColor('00000000')
                GUI.chatLines[index].leftBG:SetSolidColor('00000000')
                GUI.chatLines[index].rightBG:SetSolidColor('00000000')
            end
            GUI.chatLines[index]:SetAlpha(ChatOptions.win_alpha, true)
            curTop = curTop + 1
            index = index + 1
        end
    end
end

function FindClients(id)
    local t = GetArmiesTable()
    local focus = t.focusArmy
    local result = {}
    if focus == -1 then
        for index,client in GetSessionClients() do
            if table.getn(client.authorizedCommandSources) == 0 then
                table.insert(result, index)
            end
        end
    else
        local srcs = {}
        for army,info in t.armiesTable do
            if id then
                if army == id then
                    for k,cmdsrc in info.authorizedCommandSources do
                        srcs[cmdsrc] = true
                    end
                    break
                end
            else
                if IsAlly(focus, army) then
                    for k,cmdsrc in info.authorizedCommandSources do
                        srcs[cmdsrc] = true
                    end
                end
            end
        end
        for index,client in GetSessionClients() do
            for k,cmdsrc in client.authorizedCommandSources do
                if srcs[cmdsrc] then
                    table.insert(result, index)
                    break
                end
            end
        end
    end
    return result
end

function CreateChatEdit()

    local parent = GUI.bg:GetClientGroup()
    local group = Group(parent)
    
    group.Bottom:Set(parent.Bottom)
    group.Right:Set(parent.Right)
    group.Left:Set(parent.Left)
    group.Top:Set(function() return group.Bottom() - group.Height() end)
    
    local toText = UIUtil.CreateText(group, '', 14, 'Arial')
    toText.Bottom:Set(function() return group.Bottom() - 1 end)
    toText.Left:Set(function() return group.Left() + 35 end)
    
    ChatTo.OnDirty = function(self)
        if ToStrings[self()] then
            toText:SetText(LOC(ToStrings[self()].caps))
        else
            toText:SetText(LOCF('%s %s:', ToStrings['to'].caps, GetArmyData(self()).nickname))
        end
    end
    
    group.edit = Edit(group)
    group.edit.Left:Set(function() return toText.Right() + 5 end)
    group.edit.Right:Set(function() return group.Right() - 38 end)
    group.edit.Depth:Set(function() return GUI.bg:GetClientGroup().Depth() + 200 end)
    group.edit.Bottom:Set(function() return group.Bottom() - 1 end)
    group.edit.Height:Set(function() return group.edit:GetFontHeight() end)
    UIUtil.SetupEditStd(group.edit, "ff00ff00", nil, "ffffffff", UIUtil.highlightColor, UIUtil.bodyFont, 14, 200)
    group.edit:SetDropShadow(true)
    group.edit:ShowBackground(false)
    
    group.edit:SetText('')
    
    group.Height:Set(function() return group.edit.Height() end)
    
    local function CreateTestBtn(text)
        local btn = UIUtil.CreateCheckboxStd(group, '/dialogs/toggle_btn/toggle')
        btn.Depth:Set(function() return group.Depth() + 10 end)
        btn.OnClick = function(self, modifiers)
            if self._checkState == "unchecked" then
                self:ToggleCheck()
            end
        end
        btn.txt = UIUtil.CreateText(btn, text, 12, UIUtil.bodyFont)
        LayoutHelpers.AtCenterIn(btn.txt, btn)
        btn.txt:SetColor('ffffffff')
        btn.txt:DisableHitTest()
        return btn
    end
    
    group.camData = UIUtil.CreateCheckbox(group,
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_up.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_down.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_over.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'),
        UIUtil.SkinnableFile('/game/camera-btn/pinned_btn_dis.dds'))
    
    LayoutHelpers.AtRightIn(group.camData, group, 5)
    LayoutHelpers.AtVerticalCenterIn(group.camData, group.edit, -1)
    
    group.chatBubble = Button(group,
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_up.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_down.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_over.dds'),
        UIUtil.UIFile('/game/chat-box_btn/radio_btn_dis.dds'))
    group.chatBubble.OnClick = function(self, modifiers)
        if not self.list then
            self.list = CreateChatList(self)
            LayoutHelpers.Above(self.list, self, 15)
            LayoutHelpers.AtLeftIn(self.list, self, 15)
        else
            self.list:Destroy()
            self.list = nil
        end
    end
    
    toText.HandleEvent = function(self, event)
        if event.Type == 'ButtonPress' then
            group.chatBubble:OnClick(event.Modifiers)
        end
    end
    
    LayoutHelpers.AtLeftIn(group.chatBubble, group, 3)
    LayoutHelpers.AtVerticalCenterIn(group.chatBubble, group.edit)
    
    group.edit.OnNonTextKeyPressed = function(self, charcode, event)
        GUI.bg.curTime = 0
        local function RecallCommand(entryNumber)
            self:SetText(commandHistory[self.recallEntry].text)
            if commandHistory[self.recallEntry].camera then
                self.tempCam = commandHistory[self.recallEntry].camera
                group.camData:Disable()
                group.camData:SetCheck(true)
            else
                self.tempCam = nil
                group.camData:Enable()
                group.camData:SetCheck(false)
            end
        end
        if charcode == UIUtil.VK_NEXT then
            local mod = 10
            if event.Modifiers.Shift then
                mod = 1
            end
            ChatPageDown(mod)
            return true
        elseif charcode == UIUtil.VK_PRIOR then
            local mod = 10
            if event.Modifiers.Shift then
                mod = 1
            end
            ChatPageUp(mod)
            return true
        elseif charcode == UIUtil.VK_UP then
            if table.getsize(commandHistory) > 0 then
                if self.recallEntry then
                    self.recallEntry = math.max(self.recallEntry-1, 1)
                else
                    self.recallEntry = table.getsize(commandHistory)
                end
                RecallCommand(self.recallEntry)
            end
        elseif charcode == UIUtil.VK_DOWN then
            if table.getsize(commandHistory) > 0 then
                if self.recallEntry then
                    self.recallEntry = math.min(self.recallEntry+1, table.getsize(commandHistory))
                    RecallCommand(self.recallEntry)
                    if self.recallEntry == table.getsize(commandHistory) then
                        self.recallEntry = nil
                    end
                else
                    self:SetText('')
                end
            end
        else
            return true
        end
    end
    
    group.edit.OnCharPressed = function(self, charcode)
        local charLim = self:GetMaxChars()
        if charcode == 9 then
            return true
        end
        GUI.bg.curTime = 0
        if STR_Utf8Len(self:GetText()) >= charLim then
            local sound = Sound({Cue = 'UI_Menu_Error_01', Bank = 'Interface',})
            PlaySound(sound)
        end
    end
    
    group.edit.OnEnterPressed = function(self, text)
	
        GUI.bg.curTime = 0
		
        if group.camData:IsDisabled() then
            group.camData:Enable()
        end
		
        if text == "" then
            ToggleChat()
        else
            local gnBegin, gnEnd = string.find(text, "%s+")
            if gnBegin and (gnBegin == 1 and gnEnd == string.len(text)) then
                return
            end
            if import('/lua/ui/game/taunt.lua').CheckForAndHandleTaunt(text) then
                return
            end

            msg = { to = ChatTo(), Chat = true }
			
            if self.tempCam then
                msg.camera = self.tempCam
            elseif group.camData:IsChecked() then
                msg.camera = GetCamera('WorldCamera'):SaveSettings()
            end
			
            msg.text = text
			
			LOG("*AI DEBUG Sending Message "..repr(msg))
			
            if ChatTo() == 'allies' then
			
                SessionSendChatMessage(FindClients(), msg)
				
            elseif type(ChatTo()) == 'number' then
			
                SessionSendChatMessage(FindClients(ChatTo()), msg)
				
				-- the combination of these two should trigger a response from the AI
				-- in the ReceiveChat function
                msg.echo = true
				msg.echosender = GetArmyData(GetFocusArmy()).nickname
				
                ReceiveChat(GetArmyData(ChatTo()).nickname, msg)
            else
                SessionSendChatMessage(msg)
            end
			
			--LOG("*AI DEBUG Inserting into COMMANDHISTORY "..repr(msg))
            --table.insert(commandHistory, msg)
			
            self.recallEntry = nil
            self.tempCam = nil
        end
    end
    
    ChatTo:Set('all')
    group.edit:AcquireFocus()
    
    return group
end

function ChatPageUp(mod)
    if GUI.bg:IsHidden() then
        ForkThread(function() ToggleChat() end)
    else
        local newTop = GUI.chatContainer.top - mod
        GUI.chatContainer:ScrollSetTop(nil, newTop)
    end
end

function ChatPageDown(mod)
    local oldTop = GUI.chatContainer.top
    local newTop = GUI.chatContainer.top + mod
    GUI.chatContainer:ScrollSetTop(nil, newTop)
    if GUI.bg:IsHidden() or oldTop == GUI.chatContainer.top then
        ForkThread(function() ToggleChat() end)
    end
end

function GetHumanPlayerCount()
    local armies = GetArmiesTable()
    local count = false
    for i, v in armies.armiesTable do
        if v.human and i != armies.focusArmy then
            if not count then 
                count = 1
            else
                count = count + 1
            end
        end
    end
    return count
end

function CreateChatList(parent)
    local armies = GetArmiesTable()
    local container = Group(GUI.chatEdit)
    container:DisableHitTest()
    container.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    container.entries = {}
    local function CreatePlayerEntry(data)
        local text = UIUtil.CreateText(container, data.nickname, 12, "Arial")
        text:SetColor('ffffffff')
        text:DisableHitTest()
        
        text.BG = Bitmap(text)
        text.BG:SetSolidColor('ff000000')
        text.BG.Depth:Set(function() return text.Depth() - 1 end)
        text.BG.Left:Set(function() return text.Left() - 6 end)
        text.BG.Top:Set(function() return text.Top() - 1 end)
        text.BG.Width:Set(function() return container.Width() + 8 end)
        text.BG.Bottom:Set(function() return text.Bottom() + 1 end)
        
        text.BG.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                self:SetSolidColor('ff666666')
            elseif event.Type == 'MouseExit' then
                self:SetSolidColor('ff000000')
            elseif event.Type == 'ButtonPress' then
                ChatTo:Set(data.armyID)
                container:Destroy()
                parent.list = nil
                GUI.chatEdit.edit:Enable()
                GUI.chatEdit.edit:AcquireFocus()
            end
            GUI.bg.curTime = 0
        end
        return text
    end
    
    local entries = {
        {nickname = ToStrings.all.caps, armyID = 'all'},
        {nickname = ToStrings.allies.caps, armyID = 'allies'},
    }
    
    for armyID, armyData in armies.armiesTable do
        if armyID != armies.focusArmy and not armyData.civilian then 	-- allow chatlist to have AI's 	--and armyData.human then
            table.insert(entries, {nickname = armyData.nickname, armyID = armyID})
        end
    end
    
    local maxWidth = 0
    local height = 0
    for index, data in entries do
        local i = index
        table.insert(container.entries, CreatePlayerEntry(data))
        if container.entries[i].Width() > maxWidth then
            maxWidth = container.entries[i].Width() + 8
        end
        height = height + container.entries[i].Height()
        if i > 1 then
            LayoutHelpers.Above(container.entries[i], container.entries[i-1])
        else
            LayoutHelpers.AtLeftIn(container.entries[i], container)
            LayoutHelpers.AtBottomIn(container.entries[i], container)
        end
    end
    container.Width:Set(maxWidth)
    container.Height:Set(height)
    
    container.LTBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ul.dds'))
    container.LTBG:DisableHitTest()
    container.LTBG.Right:Set(container.Left)
    container.LTBG.Bottom:Set(container.Top)
    
    container.RTBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ur.dds'))
    container.RTBG:DisableHitTest()
    container.RTBG.Left:Set(container.Right)
    container.RTBG.Bottom:Set(container.Top)
    
    container.RBBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lr.dds'))
    container.RBBG:DisableHitTest()
    container.RBBG.Left:Set(container.Right)
    container.RBBG.Top:Set(container.Bottom)
    
    container.RLBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_ll.dds'))
    container.RLBG:DisableHitTest()
    container.RLBG.Right:Set(container.Left)
    container.RLBG.Top:Set(container.Bottom)
    
    container.LBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_l.dds'))
    container.LBG:DisableHitTest()
    container.LBG.Right:Set(container.Left)
    container.LBG.Top:Set(container.Top)
    container.LBG.Bottom:Set(container.Bottom)
    
    container.RBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_vert_r.dds'))
    container.RBG:DisableHitTest()
    container.RBG.Left:Set(container.Right)
    container.RBG.Top:Set(container.Top)
    container.RBG.Bottom:Set(container.Bottom)
    
    container.TBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_horz_um.dds'))
    container.TBG:DisableHitTest()
    container.TBG.Left:Set(container.Left)
    container.TBG.Right:Set(container.Right)
    container.TBG.Bottom:Set(container.Top)
    
    container.BBG = Bitmap(container, UIUtil.UIFile('/game/chat_brd/drop-box_brd_lm.dds'))
    container.BBG:DisableHitTest()
    container.BBG.Left:Set(container.Left)
    container.BBG.Right:Set(container.Right)
    container.BBG.Top:Set(container.Bottom)
    
    function DestroySelf()
        parent:OnClick()
    end
    
    UIMain.AddOnMouseClickedFunc(DestroySelf)
    
    container.OnDestroy = function(self)
        UIMain.RemoveOnMouseClickedFunc(DestroySelf)
    end
    
    return container
end

function SetupChatLayout(mapGroup)
    savedParent = mapGroup
    CreateChat()
    import('/lua/ui/game/gamemain.lua').RegisterChatFunc(ReceiveChat, 'Chat')
end

function CreateChat()
    if GUI.bg then
        GUI.bg.OnClose()
    end
    GUI.bg = CreateChatBackground()
    GUI.chatEdit = CreateChatEdit()
    GUI.bg.OnResize = function(self, x, y, firstFrame)
        if firstFrame then
            self:SetNeedsFrameUpdate(false)
        end
        CreateChatLines()
        GUI.chatContainer:CalcVisible()
    end
    GUI.bg.OnResizeSet = function(self)
        if not self:IsPinned() then
            self:SetNeedsFrameUpdate(true)
        end
        RewrapLog()
        CreateChatLines()
        GUI.chatContainer:CalcVisible()
        GUI.chatEdit.edit:AcquireFocus()
    end
    GUI.bg.OnMove = function(self, x, y, firstFrame)
        if firstFrame then
            self:SetNeedsFrameUpdate(false)
        end
    end
    GUI.bg.OnMoveSet = function(self)
        GUI.chatEdit.edit:AcquireFocus()
        if not self:IsPinned() then
            self:SetNeedsFrameUpdate(true)
        end
    end
    GUI.bg.OnMouseWheel = function(self, rotation)
        local newTop = GUI.chatContainer.top - math.floor(rotation / 100)
        GUI.chatContainer:ScrollSetTop(nil, newTop)
    end
    GUI.bg.OnClose = function(self)
        ToggleChat()
    end
    GUI.bg.OnOptionsSet = function(self)
        GUI.chatContainer:Destroy()
        GUI.chatContainer = false
        for i, v in GUI.chatLines do
            v:Destroy()
        end
        GUI.bg:SetAlpha(ChatOptions.win_alpha, true)
        GUI.chatLines = {}
        CreateChatLines()
        RewrapLog()
        GUI.chatContainer:CalcVisible()
        GUI.chatEdit.edit:AcquireFocus()
        if not GUI.bg.pinned then
            GUI.bg.curTime = 0
            GUI.bg:SetNeedsFrameUpdate(true)
        end
    end
    GUI.bg.OnHideWindow = function(self, hidden)
        if not hidden then
            for i, v in GUI.chatLines do
                v:SetNeedsFrameUpdate(false)
            end
        end
    end
    GUI.bg.curTime = 0
    GUI.bg.pinned = false
    GUI.bg.OnFrame = function(self, delta)
        self.curTime = self.curTime + delta
        if self.curTime > ChatOptions.fade_time then
            ToggleChat()
        end
    end
    GUI.bg.OnPinCheck = function(self, checked)
        GUI.bg.pinned = checked
        GUI.bg:SetNeedsFrameUpdate(not checked)
        GUI.bg.curTime = 0
        GUI.chatEdit.edit:AcquireFocus()
        if checked then
            Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pinned')
        else
            Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pin')
        end
    end
    GUI.bg.OnConfigClick = function(self, checked)
        if GUI.config then GUI.config:Destroy() GUI.config = false return end
        CreateConfigWindow()
        GUI.bg:SetNeedsFrameUpdate(false)
        
    end
	
	-- this sets up the players you are allowed to receive chats from
	-- originally set to only allow humans - this blocked AI chat functions
	-- credit Sorian
    for i, v in GetArmiesTable().armiesTable do
        if not v.civilian then
            ChatOptions[i] = true
        end
    end
	
    GUI.bg:SetAlpha(ChatOptions.win_alpha, true)
    Tooltip.AddButtonTooltip(GUI.bg._closeBtn, 'chat_close')
    GUI.bg.OldHandleEvent = GUI.bg.HandleEvent
	
    GUI.bg.HandleEvent = function(self, event)
        if event.Type == "WheelRotation" and self:IsHidden() then
            import('/lua/ui/game/worldview.lua').ForwardMouseWheelInput(event)
            return true
        else
            return GUI.bg.OldHandleEvent(self, event)
        end
    end
    
    Tooltip.AddCheckboxTooltip(GUI.bg._pinBtn, 'chat_pin')
    Tooltip.AddControlTooltip(GUI.bg._configBtn, 'chat_config')
    Tooltip.AddControlTooltip(GUI.bg._closeBtn, 'chat_close')
    Tooltip.AddCheckboxTooltip(GUI.chatEdit.camData, 'chat_camera')
    
    ChatOptions['links'] = ChatOptions.links or true
    CreateChatLines()
    RewrapLog()
    GUI.chatContainer:CalcVisible()
    ToggleChat()
end

function RewrapLog()

    local tempSize = 0
	
    for i, v in chatHistory do
        v.wrappedtext = WrapText(v)
        tempSize = tempSize + table.getsize(v.wrappedtext)
    end
	
    GUI.chatContainer.prevtabsize = 0
    GUI.chatContainer.prevsize = 0
    GUI.chatContainer:ScrollSetTop(nil, tempSize)
end

function WrapText(data)
    return import('/lua/maui/text.lua').WrapText(data.text, 
        function(line)
            if line == 1 then
                return GUI.chatLines[1].Right() - (GUI.chatLines[1].teamColor.Right() + GUI.chatLines[1].name:GetStringAdvance(data.name) + 4)
            else
                return GUI.chatLines[1].Right() - GUI.chatContainer.scroll.Width() - 24
            end
        end, 
        function(text) 
            return GUI.chatLines[1].text:GetStringAdvance(text) 
        end)
end

function GetArmyData(army)
    local armies = GetArmiesTable()
    local result = nil
    if type(army) == 'number' then
        if armies.armiesTable[army] then
            result = armies.armiesTable[army]
        end
    elseif type(army) == 'string' then
        for i, v in armies.armiesTable do
            if v.nickname == army then
                result = v
                result.ArmyID = i
                break
            end
        end
    end
    return result
end

function ReceiveChat(sender, msg)

	local function trim(s)
		return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
	end

	if msg.aisender then
		sender = msg.aisender
	else
		sender = sender or "nil sender"
	end
	
	--LOG("*AI DEBUG Receiving Chat from "..repr(sender).." Msg is "..repr(msg))
	
    if msg.ConsoleOutput then
        print(LOCF("%s %s", sender, msg.ConsoleOutput))
        return
    end
	
    if not msg.Chat then return end
	
    if type(msg) == 'string' then
        msg = { text = msg }
    elseif type(msg) != 'table' then
        msg = { text = repr(msg) }
    end
	
    local armyData = GetArmyData(sender)
	
    local towho = LOC(ToStrings[msg.to].text) or LOC(ToStrings['private'].text)
	
    local tokey = ToStrings[msg.to].colorkey or ToStrings['private'].colorkey
	
	if msg.aisender then
		sender = trim(string.gsub(sender,'%b()', '' ))
	end	
	
    local name = sender .. ' ' .. towho
	
    if msg.echo then
        name = string.format("%s %s:", LOC(ToStrings.to.caps), sender)
    end
	
    local tempText = WrapText({text = msg.text, name = name})
	
    -- if text wrap produces no lines (ie text is all white space) then add a blank line
    if table.getn(tempText) == 0 then
        tempText = {""}
    end

	if not msg.aisender and not msg.echo then
	
		import('/lua/aichatsorian.lua').ProcessAIChat(msg.to, armyData.ArmyID, msg.text)
		
	elseif msg.echo and msg.echosender then
	
		local fromData = GetArmyData(msg.echosender)
		import('/lua/aichatsorian.lua').ProcessAIChat(msg.to, fromData.ArmyID, msg.text)
		
	end
	
    local entry = {name = name,
					tokey = tokey,
					color = armyData.color,
					armyID = armyData.ArmyID,
					faction = (armyData.faction or 0)+1,
					text = msg.text,
					wrappedtext = tempText,
					new = true
	}
	
    if msg.camera then
        entry.camera = msg.camera
    end
	
	if table.getsize(chatHistory) >= 24 then
		table.remove(chatHistory, 1)
	end
	
    table.insert(chatHistory, entry)
	
    if ChatOptions[entry.armyID] then
	
        if table.getsize(chatHistory) == 1 then
            GUI.chatContainer:CalcVisible()
        else
            GUI.chatContainer:ScrollToBottom()
        end
		
    end
end

function CloseChat()
    if not GUI.bg:IsHidden() then
        ToggleChat()
    end
    if GUI.config then
        GUI.config:Destroy()
        GUI.config = nil
    end
end

function ToggleChat()
    if GUI.bg:IsHidden() then
        if GetFocusArmy() != -1 then
            GUI.bg:Show()
            GUI.chatEdit.edit:AcquireFocus()
            if not GUI.bg.pinned then
                GUI.bg:SetNeedsFrameUpdate(true)
                GUI.bg.curTime = 0
            end
            for i, v in GUI.chatLines do
                v:SetNeedsFrameUpdate(false)
                v:Show()
                v.OnFrame = nil
            end
        end
    else
        GUI.bg:Hide()
        GUI.chatEdit.edit:AbandonFocus()
        GUI.bg:SetNeedsFrameUpdate(false)
    end
end

function ActivateChat(modifiers)
    if GetFocusArmy() != -1 then
        if type(ChatTo()) != 'number' then
            if modifiers.Shift then
                ChatTo:Set('allies')
            else
                ChatTo:Set('all')
            end
        end
        ToggleChat()
    end
end

function CreateConfigWindow()
    import('/lua/ui/game/multifunction.lua').CloseMapDialog()
    local windowTextures = {
        tl = UIUtil.SkinnableFile('/game/panel/panel_brd_ul.dds'),
        tr = UIUtil.SkinnableFile('/game/panel/panel_brd_ur.dds'),
        tm = UIUtil.SkinnableFile('/game/panel/panel_brd_horz_um.dds'),
        ml = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_l.dds'),
        m = UIUtil.SkinnableFile('/game/panel/panel_brd_m.dds'),
        mr = UIUtil.SkinnableFile('/game/panel/panel_brd_vert_r.dds'),
        bl = UIUtil.SkinnableFile('/game/panel/panel_brd_ll.dds'),
        bm = UIUtil.SkinnableFile('/game/panel/panel_brd_lm.dds'),
        br = UIUtil.SkinnableFile('/game/panel/panel_brd_lr.dds'),
        borderColor = 'ff415055',
    }
    GUI.config = Window(GetFrame(0), '<LOC chat_0008>Chat Options', nil, nil, nil, true, true, 'chat_config', nil, windowTextures)
    GUI.config.Depth:Set(GetFrame(0):GetTopmostDepth() + 1)
    Tooltip.AddButtonTooltip(GUI.config._closeBtn, 'chat_close')
    GUI.config.Top:Set(function() return GetFrame(0).Bottom() - 700 end)
    GUI.config.Width:Set(300)
    LayoutHelpers.AtHorizontalCenterIn(GUI.config, GetFrame(0))
    LayoutHelpers.ResetRight(GUI.config)
    
    GUI.config.DragTL = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ul_btn_up.dds'))
    GUI.config.DragTR = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ur_btn_up.dds'))
    GUI.config.DragBL = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-ll_btn_up.dds'))
    GUI.config.DragBR = Bitmap(GUI.config, UIUtil.SkinnableFile('/game/drag-handle/drag-handle-lr_btn_up.dds'))
    
    LayoutHelpers.AtLeftTopIn(GUI.config.DragTL, GUI.config, -24, -8)
    
    LayoutHelpers.AtRightTopIn(GUI.config.DragTR, GUI.config, -22, -8)
    
    LayoutHelpers.AtLeftIn(GUI.config.DragBL, GUI.config, -24)
    LayoutHelpers.AtBottomIn(GUI.config.DragBL, GUI.config, -8)
    
    LayoutHelpers.AtRightIn(GUI.config.DragBR, GUI.config, -22)
    LayoutHelpers.AtBottomIn(GUI.config.DragBR, GUI.config, -8)
    
    GUI.config.DragTL.Depth:Set(function() return GUI.config.Depth() + 10 end)
    GUI.config.DragTR.Depth:Set(GUI.config.DragTL.Depth)
    GUI.config.DragBL.Depth:Set(GUI.config.DragTL.Depth)
    GUI.config.DragBR.Depth:Set(GUI.config.DragTL.Depth)
    
    GUI.config.DragTL:DisableHitTest()
    GUI.config.DragTR:DisableHitTest()
    GUI.config.DragBL:DisableHitTest()
    GUI.config.DragBR:DisableHitTest()
    
    GUI.config.OnClose = function(self)
        GUI.config:Destroy()
        GUI.config = false
    end
    
    local options = {
        filters = {{type = 'filter', name = '<LOC _Links>Links', key = 'links', tooltip = 'chat_filter'}},
        winOptions = {
                {type = 'color', name = '<LOC _All>', key = 'all_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Allies>', key = 'allies_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Private>', key = 'priv_color', tooltip = 'chat_color'},
                {type = 'color', name = '<LOC _Links>', key = 'link_color', tooltip = 'chat_color'},
                {type = 'splitter'},
                {type = 'slider', name = '<LOC chat_0009>Chat Font Size', key = 'font_size', tooltip = 'chat_fontsize', min = 10, max = 18, inc = 2},
                {type = 'slider', name = '<LOC chat_0010>Window Fade Time', key = 'fade_time', tooltip = 'chat_fadetime', min = 5, max = 45, inc = 1},
                {type = 'slider', name = '<LOC chat_0011>Window Alpha', key = 'win_alpha', tooltip = 'chat_alpha', min = 35, max = 100, inc = 1},
        },
    }
        
    local optionGroup = Group(GUI.config:GetClientGroup())
    LayoutHelpers.FillParent(optionGroup, GUI.config:GetClientGroup())
    optionGroup.options = {}
    local tempOptions = {}
    
    local function UpdateOption(key, value)
        if key == 'win_alpha' then
            value = value / 100
        end
        tempOptions[key] = value
    end
    
    local function CreateSplitter()
        local splitter = Bitmap(optionGroup)
        splitter:SetSolidColor('ff000000')
        splitter.Left:Set(optionGroup.Left)
        splitter.Right:Set(optionGroup.Right)
        splitter.Height:Set(2)
        return splitter
    end
    
    local function CreateEntry(data)
        local group = Group(optionGroup)
        if data.type == 'filter' then
            group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
            group.check = UIUtil.CreateCheckboxStd(group, '/dialogs/check-box_btn/radio')
            LayoutHelpers.AtLeftTopIn(group.check, group)
            LayoutHelpers.RightOf(group.name, group.check)
            LayoutHelpers.AtVerticalCenterIn(group.name, group.check)
            group.check.key = data.key
            group.Height:Set(group.check.Height)
            group.Width:Set(function() return group.check.Width() + group.name.Width() end)
            group.check.OnCheck = function(self, checked)
                UpdateOption(self.key, checked)
            end
            if ChatOptions[data.key] then
                group.check:SetCheck(ChatOptions[data.key], true)
            end
        elseif data.type == 'color' then
            group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
            local defValue = ChatOptions[data.key] or 1
            group.color = BitmapCombo(group, chatColors, defValue, true, nil, "UI_Tab_Rollover_01", "UI_Tab_Click_01")
            LayoutHelpers.AtLeftTopIn(group.color, group)
            LayoutHelpers.RightOf(group.name, group.color, 5)
            LayoutHelpers.AtVerticalCenterIn(group.name, group.color)
            group.color.Width:Set(55)
            group.color.key = data.key
            group.Height:Set(group.color.Height)
            group.Width:Set(group.color.Width)
            group.color.OnClick = function(self, index)
                UpdateOption(self.key, index)
            end
        elseif data.type == 'slider' then
            group.name = UIUtil.CreateText(group, data.name, 14, "Arial")
            LayoutHelpers.AtLeftTopIn(group.name, group)
            group.slider = IntegerSlider(group, false, 
                data.min, data.max, 
                data.inc, UIUtil.SkinnableFile('/slider02/slider_btn_up.dds'), 
                UIUtil.SkinnableFile('/slider02/slider_btn_over.dds'), UIUtil.SkinnableFile('/slider02/slider_btn_down.dds'), 
                UIUtil.SkinnableFile('/dialogs/options-02/slider-back_bmp.dds'))
            LayoutHelpers.Below(group.slider, group.name)
            group.slider.key = data.key
            group.Height:Set(function() return group.name.Height() + group.slider.Height() end)
            group.slider.OnValueSet = function(self, newValue)
                UpdateOption(self.key, newValue)
            end
            group.value = UIUtil.CreateText(group, '', 14, "Arial")
            LayoutHelpers.RightOf(group.value, group.slider)
            group.slider.OnValueChanged = function(self, newValue)
                group.value:SetText(string.format('%3d', newValue))
            end
            local defValue = ChatOptions[data.key] or 1
            if data.key == 'win_alpha' then
                defValue = defValue * 100
            end
            group.slider:SetValue(defValue)
            group.Width:Set(200)
        elseif data.type == 'splitter' then
            group.split = CreateSplitter()
            LayoutHelpers.AtTopIn(group.split, group)
            group.Width:Set(group.split.Width)
            group.Height:Set(group.split.Height)
        end
        if data.type != 'splitter' then
            Tooltip.AddControlTooltip(group, data.tooltip or 'chat_filter')
        end
        return group
    end
    
    local armyData = GetArmiesTable()
	
    for i, v in armyData.armiesTable do
        if not v.civilian then
            table.insert(options.filters, {type = 'filter', name = v.nickname, key = i})
        end
    end
    
    local filterTitle = UIUtil.CreateText(optionGroup, '<LOC chat_0012>Message Filters', 14, "Arial Bold")
	
    LayoutHelpers.AtLeftTopIn(filterTitle, optionGroup, 5, 5)
    Tooltip.AddControlTooltip(filterTitle, 'chat_filter')
	
    local index = 1
	
    for i, v in options.filters do
        optionGroup.options[index] = CreateEntry(v)
        optionGroup.options[index].Left:Set(filterTitle.Left)
        optionGroup.options[index].Right:Set(optionGroup.Right)
        if index == 1 then
            LayoutHelpers.Below(optionGroup.options[index], filterTitle, 5)
        else
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], -2)
        end
        index = index + 1
    end
    local splitIndex = index
    local splitter = CreateSplitter()
    splitter.Top:Set(function() return optionGroup.options[splitIndex-1].Bottom() + 5 end)
    
    local WindowTitle = UIUtil.CreateText(optionGroup, '<LOC chat_0013>Message Colors', 14, "Arial Bold")
    LayoutHelpers.Below(WindowTitle, splitter, 5)
    WindowTitle.Left:Set(filterTitle.Left)
    Tooltip.AddControlTooltip(WindowTitle, 'chat_color')
    
    local firstOption = true
    local optionIndex = 1
    for i, v in options.winOptions do
        optionGroup.options[index] = CreateEntry(v)
        optionGroup.options[index].Data = v
        if firstOption then
            LayoutHelpers.Below(optionGroup.options[index], WindowTitle, 5)
            optionGroup.options[index].Right:Set(function() return filterTitle.Left() + (optionGroup.Width() / 2) end)
            firstOption = false
        elseif v.type == 'color' then
            optionGroup.options[index].Right:Set(function() return filterTitle.Left() + (optionGroup.Width() / 2) end)
            if math.mod(optionIndex, 2) == 1 then
                LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-2], 2)
            else
                LayoutHelpers.RightOf(optionGroup.options[index], optionGroup.options[index-1])
            end
        else
            LayoutHelpers.Below(optionGroup.options[index], optionGroup.options[index-1], 4)
            LayoutHelpers.AtHorizontalCenterIn(optionGroup.options[index], optionGroup)
        end
        optionIndex = optionIndex + 1
        index = index + 1
    end
    
    local resetBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Reset>', 16)
    LayoutHelpers.Below(resetBtn, optionGroup.options[index-1], 4)
    LayoutHelpers.AtHorizontalCenterIn(resetBtn, optionGroup)
    resetBtn.OnClick = function(self)
        for option, value in defOptions do
            for i, control in optionGroup.options do
                if control.Data.key == option then
                    if control.Data.type == 'slider' then
                        if control.Data.key == 'win_alpha' then
                            value = value * 100
                        end
                        control.slider:SetValue(value)
                    elseif control.Data.type == 'color' then
                        control.color:SetItem(value)
                    end
                    UpdateOption(option, value)
                    break
                end
            end
        end
    end
    
    local okBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Ok>', 16)
    LayoutHelpers.Below(okBtn, resetBtn, 4)
    LayoutHelpers.AtLeftIn(okBtn, optionGroup)
    okBtn.OnClick = function(self)
        ChatOptions = table.merged(ChatOptions, tempOptions)
        Prefs.SetToCurrentProfile("chatoptions", ChatOptions)
        GUI.bg:OnOptionsSet()
        GUI.config:Destroy()
        GUI.config = false
    end
    
    local cancelBtn = UIUtil.CreateButtonStd(optionGroup, '/widgets02/small', '<LOC _Cancel>', 16)
    LayoutHelpers.Below(cancelBtn, resetBtn, 4)
    LayoutHelpers.AtRightIn(cancelBtn, optionGroup)
    LayoutHelpers.ResetLeft(cancelBtn)
    cancelBtn.OnClick = function(self)
        GUI.config:Destroy()
        GUI.config = false
    end
    
    
    GUI.config.Bottom:Set(function() return okBtn.Bottom() + 5 end)
end

function CloseChatConfig()
    if GUI.config then
        GUI.config:Destroy()
        GUI.config = nil
    end
end