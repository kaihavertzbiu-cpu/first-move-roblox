local Kit=require(script.Parent.InterfaceKit)
local Preferences=require(script.Parent.PreferencesView)
local Audio=require(script.Parent.AudioController)
local GuiService=game:GetService("GuiService")
local C=require(script.Parent.PresentationConfig).Colors
local Menu={};local layer,context,focusId,layout;local coveredControls={}
function Menu.active() return layer~=nil end
function Menu.reflow() if layer and layout then layout() end end
local function dismiss()
    local selected=GuiService.SelectedObject
    if selected and selected:IsDescendantOf(layer) then GuiService.SelectedObject=nil end
    layer:Destroy();layer=nil;layout=nil
    for button,selectable in pairs(coveredControls) do if button.Parent then button.Selectable=selectable end end
    coveredControls={}
end
function Menu.close(refresh)
    if not layer then return end
    dismiss()
    if refresh~=false and context and context.resume then context.resume() end
    if focusId and context and context.root then for _,b in ipairs(context.root:GetDescendants()) do if b:IsA("TextButton") and b.Selectable and b:GetAttribute("ControlId")==focusId then GuiService.SelectedObject=b;break end end end
end
function Menu.open(c)
    if layer then Menu.close();return end
    context=c;local selected=GuiService.SelectedObject;focusId=selected and selected:GetAttribute("ControlId")
    for _,button in ipairs(c.root:GetDescendants()) do if button:IsA("TextButton") then coveredControls[button]=button.Selectable;button.Selectable=false end end
    layer=Kit.make("Frame",{Name="SessionMenu",Size=c.root.Size,Position=c.root.Position,BackgroundColor3=C.Ink,BackgroundTransparency=.12,BorderSizePixel=0,Active=true,ZIndex=50},c.root.Parent)
    -- A modal catches pointer input while the live match keeps receiving updates.
    local backdrop=Kit.make("TextButton",{Name="Backdrop",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Modal=true,Selectable=false,ZIndex=50},layer)
    local p=Kit.panel(layer,.5,.5,.92,.88,0,true);p.Name="MenuPanel";p.AnchorPoint=Vector2.new(.5,.5);p.ZIndex=51
    local function draw(confirm)
        p:ClearAllChildren()
        local eyebrow=Kit.text(p,"SESSION CONTROL",0,0,1,0,12,C.Cyan);eyebrow.Name="Eyebrow"
        local title=Kit.text(p,confirm and "退出这场行动？" or "局内设置",0,0,1,0,28,C.Paper,Enum.Font.GothamBold);title.Name="Heading"
        local note=confirm and "未结束的行动不会计入战绩。双人对峙中，对手也会收到取消提示。" or "对局仍在进行。返回后显示最新状态。"
        local description=Kit.text(p,note,0,0,1,0,14,C.Muted);description.Name="Description";description.TextYAlignment=Enum.TextYAlignment.Top
        local holder,hint
        if not confirm then
            holder=Kit.make("Frame",{Name="SettingsArea",BackgroundTransparency=1},p)
            Preferences.render(holder,c.getPreferences,function(key,value) c.changePreference(key,value);Kit.fit(p,c.scale()) end,c.scale)
        else hint=Kit.text(p,"你可以先返回对局，继续完成当前行动。",0,0,1,0,17,C.Paper);hint.Name="ConfirmationHint";hint.TextYAlignment=Enum.TextYAlignment.Top end
        local divider=Kit.make("Frame",{Name="ColumnDivider",BackgroundColor3=C.Line,BorderSizePixel=0},p)
        local resume=Kit.button(p,confirm and "继续对局" or "返回对局",0,0,1,0,Menu.close,true);resume.Name="Resume";resume:SetAttribute("ControlId","SessionResume")
        local exit=Kit.button(p,confirm and "确认退出" or "退出行动",0,0,1,0,function() if confirm then dismiss();c.quit() else draw(true) end end)
        exit.Name=confirm and "ConfirmQuit" or "Quit";exit:SetAttribute("ControlId",confirm and "SessionConfirmQuit" or "SessionQuit")
        layout=function()
            layer.Size=c.root.Size;layer.Position=c.root.Position
            local size=c.root.AbsoluteSize
            local wide=size.Y<540 and size.X>=640 and size.X>size.Y
            local w=math.min(size.X*.92,wide and 760 or 550);local h=math.min(size.Y*.88,640)
            p.Size=UDim2.fromOffset(w,h);p:SetAttribute("LandscapeColumns",wide)
            local margin=wide and 20 or 18;local contentWidth=wide and w*.42-margin or w-margin*2
            eyebrow.Position=UDim2.fromOffset(margin,16);eyebrow.Size=UDim2.fromOffset(contentWidth,24)
            title.Position=UDim2.fromOffset(margin,44);title.Size=UDim2.fromOffset(contentWidth,44)
            description.Position=UDim2.fromOffset(margin,96);description.Size=UDim2.fromOffset(contentWidth,wide and (confirm and h-112 or h-212) or 52)
            divider.Visible=wide;divider.Position=UDim2.fromOffset(w*.44,18);divider.Size=UDim2.fromOffset(1,h-36)
            local actionX=wide and (confirm and w*.48 or margin) or margin
            local actionWidth=wide and (confirm and w*.52-margin or contentWidth) or contentWidth
            resume.Position=UDim2.fromOffset(actionX,h-108);resume.Size=UDim2.fromOffset(actionWidth,44)
            exit.Position=UDim2.fromOffset(actionX,h-56);exit.Size=UDim2.fromOffset(actionWidth,44)
            if holder then
                holder.Position=UDim2.fromOffset(wide and w*.48 or margin,wide and 18 or 156)
                holder.Size=UDim2.fromOffset(wide and w*.52-margin or contentWidth,wide and h-36 or h-280)
            end
            if hint then
                hint.Position=UDim2.fromOffset(wide and w*.48 or margin,wide and 24 or 160)
                hint.Size=UDim2.fromOffset(wide and w*.52-margin or contentWidth,wide and h-148 or h-280)
            end
            Kit.fit(p,c.scale())
        end
        layout();GuiService.SelectedObject=resume
    end
    draw(false);Audio.Play("select")
end
return Menu
