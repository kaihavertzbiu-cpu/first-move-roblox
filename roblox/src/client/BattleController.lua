local Shared=game:GetService("ReplicatedStorage"):WaitForChild("DeadlockShared")
local Config=require(script.Parent.UnitIdentity)
local Product=require(Shared.ProductConfig)
local Colors=require(script.Parent.PresentationConfig).Colors
local StrategicTable=require(script.Parent.TableController)
local Report=require(script.Parent.ReportController)
local Unit=require(script.Parent.UnitPresentation)
local Kit=require(script.Parent.InterfaceKit)
local Locale=require(script.Parent.LocaleController)
local Story=require(script.Parent.ReportStory)
local Tutorial=require(script.Parent.TutorialController)
local Director=require(script.Parent.PresentationDirector)
local Camera=require(script.Parent.CameraController)
local TweenService=game:GetService("TweenService")
local Feedback=require(script.Parent.PresentationConfig).TableFeedback
local CardStyle=require(script.Parent.PresentationConfig).BattleCard
local HitFeedback=require(script.Parent.PresentationConfig).HitFeedback
local GuiService=game:GetService("GuiService")
local UserInputService=game:GetService("UserInputService")
local defs={};for _,h in ipairs(Config.heroes) do defs[h.id]=h end
local Battle={}
local ui,view,remote,selection={},nil,nil,{}
local hint,pending="",false
local Network=require(script.Parent.PresentationConfig).Network
local slow,queued=false,false
local queueStarted,queueSerial=nil,0
local requestSerial=0
local exitRoute="Menu"
local detailsOpen,guideOpen=false,false
local logOpen=false
local function compact() return ui.root.AbsoluteSize.X<900 or ui.root.AbsoluteSize.X/math.max(ui.root.AbsoluteSize.Y,1)<1.5 end
local phases={Draft="建立阵容",LinkSetup="设置命线",CoreSelection="争夺先攻",SkillPhase="技能窗口",AttackSelect="承诺进攻",BlockSelect="预判格挡",DeathRattleChoice="残影亡语",GameOver="行动结束"}
local coreNames={cyan="新月 ◇",red="秩序 △",purple="荒芜 ○"}
local function ownership()
    if Director.resolving() then return "正在结算" end
    if view.training and view.training.complete then return "训练完成" end
    if view.training and view.training.feedback then return "查看结算" end
    if view.phase=="CoreSelection" then return view.coreLocked.A and "已锁定 · 等待揭示" or "轮到你 · 暗选能核" end
    return view.actor=="A" and "轮到你" or "等待对手"
end
local function name(id) return id and defs[id] and defs[id].name or "未选择" end
local function live(owner)
    local result={};for _,h in ipairs(view.rosters[owner]) do if h.alive then table.insert(result,h) end end;return result
end
local function selected(id)
    for _,side in ipairs({"A","B"}) do for _,h in ipairs(view.rosters[side]) do if h.id==id then return h end end end
end
local function doubleTargets()
    return view.phase=="SkillPhase" and selection.ally=="zhui_lie" and #live("B")>1
        or view.phase=="AttackSelect" and selection.useSkill and (selection.ally=="beng_yue" or selection.ally=="shuang_xing")
end
local render
local connecting
local function watchRequest(seconds)
    requestSerial+=1;local ticket=requestSerial
    task.delay(seconds,function()
        if ticket~=requestSerial or not pending or queued then return end
        slow=true;hint="回执较慢。先同步当前状态，确认行动是否已生效。"
        if view then render() else connecting(true) end
    end)
end
local function sync()
    if not view then return end
    slow=false;pending=true;hint="正在同步当前状态…"
    if view.phase=="GameOver" then remote:FireServer({command="Start",mode=view.mode,difficulty=view.difficulty})
    else remote:FireServer({command="Sync",sessionId=view.sessionId}) end
    watchRequest(Network.ActionTimeout);render()
end
local function send(kind,fields)
    if pending or not view or Director.resolving() then return end
    fields=fields or {};fields.kind=kind;fields.revision=view.revision
    pending=true;hint="正在提交…"
    remote:FireServer({command="Action",sessionId=view.sessionId,intent=fields})
    slow=false;watchRequest(Network.ActionTimeout)
    render()
end
local function choose(owner,id)
    if pending then return end
    detailsOpen=false;guideOpen=false
    if owner=="A" then
        if selection.ally~=id then
            selection.useSkill=false;selection.second=nil;selection.editSlot=nil
            if view.phase=="SkillPhase" then selection.target=nil end
        end
        selection.ally=id
    else
        if not doubleTargets() then selection.target=id;selection.second=nil
        else
            local slot=selection.editSlot or (selection.target and 2 or 1)
            local distinct=selection.ally~="beng_yue"
            if slot==1 then
                selection.target=id
                if distinct and selection.second==id then selection.second=nil end
            elseif not distinct or selection.target~=id then selection.second=id
            else selection.second=nil end
        end
        selection.editSlot=nil
    end
    hint="";render()
end
local function logText(event)
    if Locale.isEnglish() then return Story.event(event) end
    if event.kind=="Damage" then return name(event.target).." −"..event.amount.."  /  "..({Normal="普攻",Skill="技能",Bleeding="流血",Reflection="反伤",DeathRattle="亡语"})[event.damageType] end
    if event.kind=="Heal" then return name(event.target).." +"..event.amount.."  /  恢复" end
    if event.kind=="Death" then return name(event.target).." 阵亡" end
    if event.kind=="Block" then return name(event.target).." 格挡命中" end
    if event.kind=="Execute" then return name(event.target).." 被掠魂" end
    if event.kind=="LinkTrigger" then return "命线触发 → "..name(event.target) end
    if event.kind=="CoreReveal" then return "能核揭示  "..coreNames[event.A].." / "..coreNames[event.B] end
    if event.kind=="CoreTie" then return "能核相同，重新暗选" end
    if event.kind=="Skill" then return name(event.source).." · "..defs[event.source].skill.name end
    if event.kind=="Lock" then return name(event.target).." 已封锁" end
    if event.kind=="AttackCommitted" then return (event.owner=="A" and "你" or "对手").."已承诺进攻" end
    if event.kind=="RoundEnd" then return "第 "..event.round.." 回合结束" end
end
local function markResolution(event,hold,index)
    if not ui.root then return end
    local color=(event.kind=="Heal" or event.kind=="Block") and Colors.Cyan or event.kind=="LinkTrigger" and Feedback.LinkColor or event.kind=="Death" and Colors.Muted or event.kind=="Execute" and Colors.Paper or Colors.Amber
    for _,b in ipairs(ui.root:GetChildren()) do if b:IsA("TextButton") then
        local id=b:GetAttribute("ControlId") or ""
        if event.target and id:sub(-#event.target-1)==":"..event.target and Unit.react then Unit.react(b,event,hold,Camera.Reduced) end
        if id:match("^Hero:") and (id:sub(-#(event.target or "")-1)==":"..(event.target or "") or id:sub(-#(event.source or "")-1)==":"..(event.source or "")) then
            if event.kind=="Damage" and event.target and id:sub(-#event.target-1)==":"..event.target then
                local previous=b:FindFirstChild("DamageNumber");if previous then previous:Destroy() end
                local tier=event.impactTier or 1
                local number=ui.make("TextLabel",{Name="DamageNumber",BackgroundTransparency=1,
                    Text="−"..tostring(event.effective or event.amount or 0),Font=Enum.Font.GothamBold,
                    TextSize=HitFeedback.NumberSizes[tier],TextColor3=color,TextStrokeColor3=Colors.Ink,
                    TextStrokeTransparency=.1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.35),
                    Size=UDim2.new(1,0,0,48),ZIndex=20},b)
                local duration=Camera.Reduced and Feedback.ReducedTime or math.max(.3,hold)
                if not Camera.Reduced then
                    local tween=TweenService:Create(number,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
                        {Position=UDim2.fromScale(.5,.05),TextTransparency=1,TextStrokeTransparency=1})
                    tween:Play();number.Destroying:Connect(function()tween:Cancel()end)
                end
                task.delay(duration+Feedback.Tail,function()if number.Parent then number:Destroy()end end)
            end
            local old=b:FindFirstChild("ResolutionPulse");if old then old:Destroy() end
            local stroke=ui.make("UIStroke",{Name="ResolutionPulse",Color=color,Thickness=2,Transparency=.15},b)
            local time=Camera.Reduced and Feedback.ReducedTime or hold
            if not Camera.Reduced then
                local t=TweenService:Create(stroke,TweenInfo.new(time),{Transparency=1});t:Play()
                stroke.Destroying:Connect(function() t:Cancel() end)
            end
            task.delay(time+Feedback.Tail,function() if stroke.Parent then stroke:Destroy() end end)
        end
    end end
    local list=ui.root:FindFirstChild("RevealedEvents",true)
    if list then for _,row in ipairs(list:GetChildren()) do if row:IsA("TextLabel") then
        row.BackgroundTransparency=1;row.TextColor3=Colors.Paper
        if row:GetAttribute("EventIndex")==index then
            row.BackgroundColor3=Colors.Panel;row.BackgroundTransparency=.15;row.TextColor3=color
            list.CanvasPosition=Vector2.new(0,math.max(0,math.min(row.Position.Y.Offset,list.CanvasSize.Y.Offset-list.AbsoluteSize.Y)))
        end
    end end end
end
local function quit(destination)
    exitRoute=type(destination)=="string" and destination or "Menu"
    remote:FireServer({command="Quit",sessionId=view and view.sessionId})
    view=nil;pending=false;queued=false;queueStarted=nil;queueSerial+=1;requestSerial+=1;Director.reset();ui.route(exitRoute)
    StrategicTable.reset()
end
local function roster(owner,y)
    local list=view.rosters[owner]
    local small=compact();local origin=small and .035 or .35;local step=small and .188 or .081;local width=small and .176 or .077
    local short=small and ui.root.AbsoluteSize.Y<380
    local rowHeight=math.max(short and 60 or small and CardStyle.CompactHeight or CardStyle.MinimumHeight,ui.root.AbsoluteSize.Y*(small and .12 or .135))
    local rowY=short and (owner=="B" and 100 or 184) or y*ui.root.AbsoluteSize.Y
    local heading=ui.text(ui.root,owner=="A" and "YOUR FORMATION / 你的阵容" or "OPPONENT / 对手阵容",origin,0,small and .70 or .40,0,12,owner=="A" and Colors.Cyan or Colors.Amber)
    heading.Position=UDim2.new(origin,0,0,rowY-22);heading.Size=UDim2.new(small and .70 or .40,0,0,20)
    for i=1,5 do
        local actual=list[i];local h=actual and (Director.hero and Director.hero(actual) or actual)
        local targeting=view.actor=="A" and (view.phase=="AttackSelect" or view.phase=="DeathRattleChoice" or view.phase=="LinkSetup" or view.phase=="SkillPhase" and (selection.ally=="chi_guang" or selection.ally=="zhui_lie"))
        local marker=h and owner=="B" and targeting and (selection.target==h.id and selection.second==h.id and "①② " or selection.target==h.id and "① " or selection.second==h.id and "② " or "") or ""
        local label=h and (marker..name(h.id).."\n"..(h.alive and h.hp.." / "..h.maxHp or "阵亡")) or "—"
        local x=origin+(i-1)*step
        local b=ui.button(ui.root,label,x,y,width,small and .12 or .135,function() if h and h.alive then choose(owner,h.id) end end)
        b.Position=UDim2.new(x,0,0,rowY);b.Size=UDim2.new(width,0,0,rowHeight)
        if h then
            Unit.roster(ui,b,h,defs[h.id],owner,marker,selection.ally==h.id or selection.target==h.id or selection.second==h.id)
            if h.alive and view.phase~="Draft" then
                local states={}
                if h.cooldown>0 then table.insert(states,"CD "..h.cooldown) end
                if h.used then table.insert(states,"已耗尽") end
                if h.statuses.bleeding then table.insert(states,"流血") end
                if h.statuses.blocked then table.insert(states,"封锁") end
                if #states>0 then
                    if short then
                        ui.make("Frame",{Name="StatusIndicator",BorderSizePixel=0,BackgroundColor3=h.statuses.bleeding and Colors.Amber or Colors.Cyan,Position=UDim2.new(1,-7,0,4),Size=UDim2.fromOffset(3,3)},b)
                    else
                        local status=ui.text(ui.root,table.concat(states," · "),x,0,width,0,12,Colors.Muted)
                        status.Position=UDim2.new(x,0,0,rowY+rowHeight+3);status.Size=UDim2.new(width,0,0,20)
                    end
                end
            end
        else b.Selectable=false end
    end
end
local function actionRail()
    local p=ui.panel(ui.root,.035,.10,.285,.80,.04)
    p.Name="ActionRail"
    local small=compact()
    if small then p.Position=UDim2.fromScale(.035,detailsOpen and .19 or ui.root.AbsoluteSize.Y<540 and .68 or .77);p.Size=UDim2.fromScale(.93,detailsOpen and .71 or ui.root.AbsoluteSize.Y<540 and .23 or .15);p.ZIndex=detailsOpen and 10 or 1 end
    if small and not detailsOpen and ui.root.AbsoluteSize.Y<380 then p.Position=UDim2.new(.035,0,1,-57);p.Size=UDim2.new(.93,0,0,56) end
    if small and detailsOpen and ui.root.AbsoluteSize.Y<380 then p.Position=UDim2.fromScale(.035,.075);p.Size=UDim2.fromScale(.93,.88) end
    local progress=view.training and math.min(view.training.step,view.training.total or 3).."/"..(view.training.total or 3) or ""
    local roundHeading=ui.text(p,(view.mode=="Training" and "训练 "..progress.." / " or "R"..string.format("%02d",view.round).." / ")..ownership(),.08,.025,.84,.06,14,view.actor=="A" and Colors.Cyan or Colors.Amber)
    local title=phases[view.phase] or view.phase
    if view.actor~="A" and view.phase~="CoreSelection" then title="对手正在"..(view.phase=="BlockSelect" and "防守" or view.phase=="AttackSelect" and "进攻" or view.phase=="Draft" and "选人" or "行动") end
    if view.training then title=view.training.title end
    if Director.resolving() then title="正在结算" end
    if view.phase=="GameOver" then title=Director.resolving() and "战斗结算" or view.winner=="A" and "胜利" or view.winner=="B" and "失利" or "同归于尽" end
    local phaseHeading=ui.text(p,title,.08,.10,.84,.13,29,Colors.Paper,Enum.Font.GothamBold)
    local divider=ui.line(p,.08,.255,.84)
    local controls=ui.make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(.08,.29),Size=UDim2.new(.84,0,.71,-66),ScrollBarThickness=3,ScrollBarImageColor3=Colors.Cyan,CanvasSize=UDim2.fromOffset(0,0)},p)
    controls.Name="ActionDetails"
    if small and not detailsOpen then roundHeading.Visible=false;phaseHeading.Visible=false;divider.Visible=false;controls.Visible=false end
    if small and detailsOpen then
        roundHeading.Position=UDim2.new(.08,0,0,4);roundHeading.Size=UDim2.new(.84,0,0,24)
        phaseHeading.Position=UDim2.new(.08,0,0,30);phaseHeading.Size=UDim2.new(.84,0,0,40)
        divider.Position=UDim2.new(.08,0,0,74)
        controls.Position=UDim2.new(.08,0,0,84);controls.Size=UDim2.new(.84,0,1,-150)
    end
    local offset=0
    local optionIndex=0
    local function paragraph(value,size,height,color)
        local t=ui.text(controls,value,0,0,1,0,size or 16,color or Colors.Muted)
        t.TextYAlignment=Enum.TextYAlignment.Top
        local fontSize=Kit.textSize(size or 16,ui.root.AbsoluteSize.Y,(ui.fontScale and ui.fontScale()) or 1)
        local width=math.max(60,(small and ui.root.AbsoluteSize.X*.93 or ui.root.AbsoluteSize.X*.285)*.84-7)
        local measured=game:GetService("TextService"):GetTextSize(value,fontSize,t.Font,Vector2.new(width,100000)).Y+12
        local needed=math.max(28,measured)
        t.Position=UDim2.fromOffset(0,offset);t.Size=UDim2.new(1,-7,0,needed);offset+=needed
    end
    local function subject(id)
        local def=defs[id];if not def then return end
        local h=selected(id)
        local card=ui.make("Frame",{Name="DecisionUnit",BackgroundTransparency=1,Position=UDim2.fromOffset(0,offset),Size=UDim2.new(1,-7,0,82)},controls)
        card:SetAttribute("UnitId",id)
        if Unit.portrait then Unit.portrait(ui,card,id,UDim2.fromOffset(0,0),UDim2.fromOffset(72,72),not h or h.alive) end
        local heading=ui.text(card,def.name,0,0,1,0,21,Colors.Paper,Enum.Font.GothamBold)
        heading.Position=UDim2.fromOffset(82,2);heading.Size=UDim2.new(1,-82,0,30);heading.TextWrapped=false
        local values=ui.text(card,(h and h.hp or def.maxHp).."/"..def.maxHp.." HP · "..(h and h.atk or def.atk).." ATK",0,0,1,0,14,Colors.Muted)
        values.Position=UDim2.fromOffset(82,34);values.Size=UDim2.new(1,-82,0,24);values.TextWrapped=false
        local label=h and h.cooldown>0 and "冷却 "..h.cooldown.." 回合" or h and h.used and "限定技已使用" or def.role
        local status=ui.text(card,label,0,0,1,0,12,h and (h.cooldown>0 or h.used) and Colors.Amber or Colors.Cyan)
        status.Position=UDim2.fromOffset(82,58);status.Size=UDim2.new(1,-82,0,22);status.TextWrapped=false
        offset+=90
    end
    local function consequence(value)
        paragraph(value,14,nil,Colors.Amber)
    end
    local function option(label,fn,primary,available)
        local b=ui.button(controls,label,0,0,1,0,fn,primary)
        optionIndex+=1;b:SetAttribute("ControlId","Option:"..optionIndex)
        if view.phase=="SkillPhase" or view.phase=="BlockSelect" then b:SetAttribute("AudioCue","commit") end
        b.Position=UDim2.fromOffset(0,offset);b.Size=UDim2.new(1,-7,0,44);offset+=52
        local disabled=available==false or pending or Director.resolving()
        b:SetAttribute("Disabled",disabled);b.Selectable=not disabled
        if disabled then
            b.BackgroundColor3=Colors.Line;b.BackgroundTransparency=.45
            for _,child in ipairs(b:GetChildren()) do if child:IsA("TextLabel") then child.TextColor3=Colors.Muted end end
        end
    end
    local function targetOptions(two)
        for slot=1,two and 2 or 1 do
            local index=slot;local id
            if index==1 then id=selection.target else id=selection.second end
            local b=ui.button(controls,(index==1 and "① " or "② ")..name(id),0,0,1,0,function()
                if pending or Director.resolving() or view.actor~="A" then return end
                selection.editSlot=index;detailsOpen=false;guideOpen=false;render()
            end)
            b.Position=UDim2.new(two and (index-1)*.52 or 0,0,0,offset);b.Size=UDim2.new(two and .48 or 1,-7,0,44)
            b:SetAttribute("ControlId","TargetSlot:"..index)
            if id and defs[id] and Unit.portrait then
                for _,child in ipairs(b:GetChildren()) do if child:IsA("TextLabel") or child:IsA("UIPadding") then child:Destroy() end end
                Unit.portrait(ui,b,id,UDim2.fromOffset(4,3),UDim2.fromOffset(34,38),true)
                local title=ui.text(b,(index==1 and "① " or "② ")..name(id),0,0,1,0,14,Colors.Paper)
                title.Position=UDim2.fromOffset(43,0);title.Size=UDim2.new(1,-47,0,22);title.TextWrapped=false
                local target=selected(id)
                local health=ui.text(b,target and target.hp.."/"..target.maxHp.." HP" or "目标已选择",0,0,1,0,12,Colors.Muted)
                health.Position=UDim2.fromOffset(43,22);health.Size=UDim2.new(1,-47,0,22);health.TextWrapped=false
            end
            local disabled=pending or Director.resolving() or view.actor~="A"
            b:SetAttribute("Disabled",disabled);b.Selectable=not disabled
        end
        offset+=52
    end
    local label,commit,enabled
    local myTurn=view.actor=="A"
    if small and ui.root.AbsoluteSize.Y<380 and view.phase~="Draft" then
        for _,key in ipairs({"ally","target"}) do
            local id=selection[key]
            local h=selected(id)
            if h then
                local states={}
                if h.cooldown>0 then table.insert(states,"冷却 "..h.cooldown.." 回合") end
                if h.used then table.insert(states,"限定技已耗尽") end
                if h.statuses.bleeding then table.insert(states,"流血") end
                if h.statuses.blocked then table.insert(states,"封锁") end
                if #states>0 then paragraph(name(id).."："..table.concat(states," · "),14,nil,Colors.Paper) end
            end
        end
    end
    if view.phase=="GameOver" then paragraph("正在依次揭示最后的伤害与连锁。胜负已由服务器确认，演出结束后进入行动战报。",16,nil,Colors.Paper) end
    if view.training and view.phase~="AttackSelect" then paragraph(view.training.body,15,nil,Colors.Paper) end
    if view.training and (view.training.feedback or view.training.complete) then
        label=view.training.complete and "开始正式对局" or view.training.feedback=="success" and "练习技能" or "再试一次"
        enabled=true
        commit=function()
            if view.training.complete then quit("Setup")
            else send(view.training.feedback=="success" and "TrainingContinue" or "TrainingRetry") end
        end
    elseif view.phase=="Draft" then
        if selection.hero then
            local def=defs[selection.hero]
            subject(selection.hero)
            paragraph(def.skill.name.."\n"..def.skill.description,15,nil,Colors.Paper)
        else paragraph(myTurn and "点选单位查看能力，再确认入队。双方各选五名，不可重复选择。" or "观察对手已选阵容，准备你的下一手。",16) end
        label=selection.hero and "确认入队" or "先选一名单位";enabled=myTurn and selection.hero~=nil;commit=function() send("DraftPick",{heroId=selection.hero}) end
    elseif view.phase=="LinkSetup" then
        paragraph(myTurn and "选择一名己方其他单位，再选择敌方单位。己方目标阵亡时，敌方目标随之阵亡。只有你知道命线。" or "对手正在布置命线。它的目标尚未揭示。",16,125)
        paragraph(name(selection.ally).." → "..name(selection.target),17,60,Colors.Paper)
        label="绑定命线";enabled=myTurn and selection.ally and selection.ally~="ye_ban" and selection.target;commit=function() send("LinkConfirm",{allyId=selection.ally,enemyId=selection.target}) end
    elseif view.phase=="CoreSelection" then
        -- Decisions stay pinned above Confirm; only the explanation may scroll.
        if small and not detailsOpen then
            p.Position=UDim2.new(.035,0,1,-132);p.Size=UDim2.new(.93,0,0,124)
        end
        controls.Size=UDim2.new(.84,0,1,-controls.Position.Y.Offset-126)
        if not small then controls.Size=UDim2.new(.84,0,.71,-126) end
        local cycle=ui.make("Frame",{Name="CoreCycle",BackgroundTransparency=1,Position=UDim2.fromOffset(0,offset),Size=UDim2.new(1,-7,0,114)},controls)
        local nodes={{.50,.12,"秩序",Colors.Amber},{.83,.74,"新月",Colors.Cyan},{.17,.74,"荒芜",Feedback.LinkColor}}
        for i,node in ipairs(nodes) do
            local nextNode=nodes[i%3+1]
            local x=(node[1]+nextNode[1])/2;local y=(node[2]+nextNode[2])/2
            local label=ui.text(cycle,i==1 and "↘" or i==2 and "←" or "↗",x-.07,y-.08,.14,.25,22,Colors.Muted)
            label.TextXAlignment=Enum.TextXAlignment.Center;label.TextWrapped=false
            local t=ui.text(cycle,node[3],node[1]-.19,node[2]-.09,.38,.23,16,node[4],Enum.Font.GothamMedium)
            t.TextXAlignment=Enum.TextXAlignment.Center;t.TextWrapped=false
        end
        offset+=122
        paragraph("箭头表示克制。相同能核重新暗选，后攻方仍有一次行动。",15)
        for i,core in ipairs({"red","cyan","purple"}) do
            local b=ui.button(p,coreNames[core]:match("^%S+"),0,0,0,0,function() selection.core=core;render() end,selection.core==core)
            b.Position=UDim2.new(.08+(i-1)*.285,0,1,-112);b.Size=UDim2.new(.27,0,0,48)
            b:SetAttribute("ControlId","Core:"..core);b.Selectable=not view.coreLocked.A
            b:SetAttribute("Disabled",view.coreLocked.A)
            for _,child in ipairs(b:GetChildren()) do if child:IsA("TextLabel") then child.TextSize=14;child:SetAttribute("BaseTextSize",14) end end
        end
        label=view.coreLocked.A and "已锁定，等待揭示" or selection.core and "锁定能核" or "选择一种能核";enabled=not view.coreLocked.A and selection.core;commit=function() send("CoreLock",{core=selection.core}) end
    elseif view.phase=="SkillPhase" then
        local teaching=view.training and view.training.requiredCaster
        local h=selected(selection.ally)
        if h then
            if ui.root.AbsoluteSize.Y>=540 then subject(h.id) end
            local def=defs[h.id]
            local code=def.skill.code
            local windowSkill=code=="group_heal" or code=="stasis_lock" or code=="final_barrage" or code=="overload_explode"
            local legal=myTurn and h.cooldown==0 and not h.used and not h.statuses.blocked
            legal=legal and windowSkill
            if teaching and h.id~=teaching then legal=false end
            local targetOK=code=="group_heal" or code=="overload_explode" or selection.target~=nil
            if code=="final_barrage" and #live("B")>1 then targetOK=targetOK and selection.second~=nil and selection.second~=selection.target end
            if not teaching and legal then
                if code=="stasis_lock" or code=="final_barrage" then targetOptions(code=="final_barrage" and #live("B")>1) end
                option("跳过技能 · 进入攻击",function() send("SkillEnd") end,false,myTurn)
            end
            if ui.root.AbsoluteSize.Y<540 then subject(h.id) end
            paragraph(def.skill.name,18,36,Colors.Paper)
            if windowSkill then paragraph(code=="overload_explode" and "无需敌方目标：自毁后再选择亡语目标。" or code=="group_heal" and "无需敌方目标：恢复所有己方存活单位。" or "目标："..name(selection.target)..(selection.second and " / "..name(selection.second) or ""),14,52) end
            if not legal then
                local reason=teaching and h.id~=teaching and "这一步先选择"..name(teaching).."，练习恢复技能。" or not myTurn and "等待对手结束行动。" or h.used and "限定技本局已经用完。" or h.cooldown>0 and "技能冷却剩余 "..h.cooldown.." 回合。" or h.statuses.blocked and "技能窗口被封锁，仍可进入攻击。" or def.skill.isPassive and "被动能力会自动触发。" or "该能力在攻击阶段启用。"
                paragraph(reason,14,48)
            elseif not targetOK then paragraph("先选择技能目标；双目标技能还需选择②。",14,48) end
            paragraph(def.skill.description,15,120)
            if legal then consequence(code=="overload_explode" and "代价：残影立即阵亡，再手动选择亡语目标。" or def.skill.isGameLimited and "代价：限定技本局只能使用一次。" or def.skill.cooldown and def.skill.cooldown>0 and "代价：使用后冷却 "..def.skill.cooldown.." 回合。" or "技能生效后继续进入攻击阶段。") end
        else paragraph(teaching and "选择复苏，恢复己方受伤单位，无需敌方目标。" or myTurn and "可选择己方单位查看技能，也可直接进入攻击。技能效果会说明是否需要目标。" or "对手处于技能窗口。生命与冷却是已知信息。",16,52) end
        label="进入攻击阶段";enabled=myTurn;commit=function() send("SkillEnd") end
        if h and not teaching then
            local def=defs[h.id];local code=def.skill.code
            local ready=myTurn and h.cooldown==0 and not h.used and not h.statuses.blocked
            local windowSkill=code=="group_heal" or code=="stasis_lock" or code=="final_barrage" or code=="overload_explode"
            if ready and windowSkill then
                local targeted=code=="stasis_lock" or code=="final_barrage"
                enabled=not targeted or selection.target~=nil
                if code=="final_barrage" and #live("B")>1 then enabled=enabled and selection.second~=nil and selection.second~=selection.target end
                label=targeted and not selection.target and "选择①目标" or not enabled and "选择②目标" or code=="overload_explode" and "自毁 · 终响" or "释放 "..def.skill.name
                commit=function() send("SkillCast",{casterId=h.id,targetId=targeted and selection.target or nil,secondTargetId=targeted and selection.second or nil}) end
            end
        end
        if teaching then label=selection.ally==teaching and "释放 "..defs[teaching].skill.name or "先选择"..name(teaching);enabled=myTurn and selection.ally==teaching;commit=function() send("SkillCast",{casterId=teaching}) end end
    elseif view.phase=="AttackSelect" then
        local h=selected(selection.ally)
        if h then
            if ui.root.AbsoluteSize.Y>=540 then subject(h.id) end
            local def=defs[h.id]
            local double=selection.useSkill and (h.id=="shuang_xing" or h.id=="beng_yue")
            local available=h.cooldown==0 and def.skill.type=="active_attack_phase" and (h.id~="shuang_xing" or #live("B")>1)
            local function attackSkillOption() option(def.skill.name.." · "..(selection.useSkill and "已启用" or "未启用"),function() selection.useSkill=not selection.useSkill;selection.second=nil;selection.editSlot=nil;render() end) end
            if available then attackSkillOption() end
            targetOptions(double)
            if ui.root.AbsoluteSize.Y<540 then subject(h.id) end
            if view.training then paragraph(view.training.attackBody or view.training.body,15,nil,Colors.Paper) end
            if available then
                consequence(selection.useSkill and "代价：技能攻击后冷却 "..def.skill.cooldown.." 回合。" or "当前为普通攻击；技能尚未启用。")
            end
            if double then paragraph(h.id=="beng_yue" and "点击第二目标；再次点击同一目标可连击。" or "裂轨射击需要两个不同目标。",14,56) end
            if h.id=="shuang_xing" and #live("B")==1 then paragraph("敌方只剩一名单位，裂轨射击需要两个不同目标；本次使用普攻。",14) end
            if available then paragraph(def.skill.description,15,110) end
            enabled=myTurn and selection.target and (not double or selection.second)
            if h.id=="shuang_xing" and double and selection.target==selection.second then enabled=false end
            commit=function() send("AttackCommit",{attackerId=h.id,targets=double and {selection.target,selection.second} or {selection.target},useSkill=selection.useSkill==true}) end
        else paragraph(view.training and (view.training.attackBody or view.training.body) or "选择进攻单位与目标；对手随后暗选格挡。",16,36) end
        label=not selection.ally and "先选进攻单位" or not selection.target and "选择攻击目标" or doubleTargets() and not selection.second and "选择第二目标" or "承诺进攻"
    elseif view.phase=="BlockSelect" then
        paragraph(myTurn and "敌方攻击已经承诺，目标仍未知。选择一名己方单位，让它保护自己。低语的攻击无法格挡。" or "你已承诺进攻。等待对手选择格挡，随后揭示结算。",16,115)
        if myTurn then
            if selection.ally then subject(selection.ally) else paragraph("选择要保护的己方单位。",18,60,Colors.Paper) end
            option("放弃格挡",function() send("BlockCommit") end,false,true)
        end
        label=selection.ally and "确认格挡" or "先选格挡单位";enabled=myTurn and selection.ally;commit=function() send("BlockCommit",{blockerId=selection.ally}) end
    elseif view.phase=="DeathRattleChoice" then
        paragraph(myTurn and "残影已经阵亡，但亡语尚未结算。选择一名存活敌方单位，造成 15 点不可格挡直伤。" or "残影的亡语正在选目标。剩余结算会在选择后继续。",16,115)
        paragraph("亡语 → "..name(selection.target),18,60,Colors.Paper)
        label="释放亡语";enabled=myTurn and selection.target;commit=function() send("DeathRattleTarget",{targetId=selection.target}) end
    end
    if hint~="" then paragraph(hint,14,52,Colors.Amber) end
    controls.CanvasSize=UDim2.fromOffset(0,offset)
    if not myTurn and view.phase~="CoreSelection" and not view.training then label="等待对手…";enabled=false;commit=nil end
    if slow then label="同步状态";enabled=true;commit=sync end
    local allowed=enabled and (slow or not pending and not Director.resolving()) and true or false
    if Director.resolving() and not slow then label="结算中…" end
    local b=ui.button(p,label or "等待对手",.08,0,.84,0,function() if allowed and commit then commit() end end,true)
    b.AnchorPoint=Vector2.new(0,1);b.Position=UDim2.new(.08,0,1,-12);b.Size=UDim2.new(.84,0,0,44)
    b:SetAttribute("ControlId",slow and "SyncState" or "PrimaryAction");b.Selectable=allowed
    b:SetAttribute("AudioCue","commit")
    b:SetAttribute("Disabled",not allowed)
    if not allowed then b.BackgroundColor3=Colors.Line end
    if small then
        b.Position=UDim2.new(.45,0,1,-12);b.Size=UDim2.new(.52,0,0,44)
        local drawer=ui.button(p,detailsOpen and "收起详情" or "行动详情",.03,0,.38,0,function() detailsOpen=not detailsOpen;guideOpen=false;render() end)
        drawer.Position=UDim2.new(.03,0,1,-56);drawer.Size=UDim2.new(.38,0,0,44);drawer:SetAttribute("ControlId","ActionDrawer")
    end
end
render=function()
    if not ui.root or not view then return end
    local focused=GuiService.SelectedObject
    local focusId=focused and focused:IsDescendantOf(ui.root) and (focused:GetAttribute("ControlId") or focused.Name)
    local function restoreFocus()
        if ui.menuActive and ui.menuActive() then
            for _,button in ipairs(ui.root:GetDescendants()) do if button:IsA("TextButton") then button.Selectable=false end end
            return
        end
        if not UserInputService.GamepadEnabled then return end
        local fallback
        for _,button in ipairs(ui.root:GetDescendants()) do if button:IsA("TextButton") and button.Selectable then
            fallback=fallback or button
            if (button:GetAttribute("ControlId") or button.Name)==focusId then GuiService.SelectedObject=button;return end
        end end
        GuiService.SelectedObject=fallback
    end
    StrategicTable.update(view,selection)
    if Report.capture then Report.capture() end
    ui.root:ClearAllChildren();ui.root:SetAttribute("Screen","Battle")
    ui.chrome()
    if view.phase=="GameOver" and not Director.resolving() then Report.render(ui,view,quit,{again=function() Battle.again() end,pending=pending,sync=slow and sync or nil});restoreFocus();return end
    actionRail()
    local small=compact()
    if small then
        local heading=ui.text(ui.root,selection.editSlot and ("轮到你 · 选择"..(selection.editSlot==1 and "①" or "②").."目标") or ownership().." · "..(view.training and "攻防训练" or phases[view.phase] or view.phase)..(view.phase=="Draft" and " · "..#view.rosters.A.."/5" or ""),.035,.075,.50,.06,16,Colors.Paper,Enum.Font.GothamMedium)
        heading.Name="OwnershipHeading"
        if ui.root.AbsoluteSize.Y<380 then heading.Position=UDim2.new(.035,0,0,26);heading.Size=UDim2.new(.50,0,0,24) end
    end
    if view.phase=="Draft" then
        ui.text(ui.root,"UNIT POOL / 单位池",small and .035 or .35,.14,.40,.05,14,Colors.Cyan)
        local taken={};for _,side in ipairs({"A","B"}) do for _,h in ipairs(view.rosters[side]) do taken[h.id]=side end end
        for i,def in ipairs(Config.heroes) do
            local columns=small and ui.root.AbsoluteSize.Y<540 and 4 or 3
            local col=(i-1)%columns;local row=math.floor((i-1)/columns)
            local sub=taken[def.id] and (taken[def.id]=="A" and "己方已选" or "对手已选") or def.atk.." ATK · "..def.maxHp.." HP"
            local x=small and .035+col*(.94/columns) or .35+col*.137
            local y=small and .21+row*(ui.root.AbsoluteSize.Y<540 and .145 or .12) or .20+row*.145
            local b=ui.button(ui.root,def.name.."\n"..sub,x,y,small and .94/columns-.012 or .128,small and ui.root.AbsoluteSize.Y<540 and .13 or small and .10 or .12,function() if not taken[def.id] and view.actor=="A" then selection.hero=def.id;detailsOpen=small;render() end end)
            if small and ui.root.AbsoluteSize.Y<380 then b.Position=UDim2.new(x,0,0,78+row*54);b.Size=UDim2.new(.94/columns-.012,0,0,50) end
            Unit.draft(ui,b,def,taken[def.id],selection.hero==def.id)
            if taken[def.id] then b.BackgroundTransparency=.65 end
            if selection.hero==def.id then b.BackgroundColor3=Color3.fromRGB(52,81,86) end
        end
        local count=ui.text(ui.root,"你："..#view.rosters.A.." / 5     对手："..#view.rosters.B.." / 5",small and .035 or .35,small and ui.root.AbsoluteSize.Y<540 and .635 or small and .70 or .82,.60,.04,15,Colors.Paper)
        if small and ui.root.AbsoluteSize.Y<380 then count.Visible=false end
    else roster("B",small and .19 or .15);roster("A",small and ui.root.AbsoluteSize.Y<540 and .46 or small and .60 or .73) end
    local history=ui.panel(ui.root,.79,.10,.18,.73,.10)
    history.Name="ContextPanel"
    if logOpen and not small then history.Position=UDim2.fromScale(.465,.10);history.Size=UDim2.fromScale(.505,.73);history.ZIndex=20 end
    if small then history.Position=UDim2.fromScale(.035,.19);history.Size=UDim2.fromScale(.93,.71);history.ZIndex=20;history.Visible=guideOpen end
    ui.text(history,logOpen and "BATTLE LOG / 对局日志" or Tutorial.Enabled and "FIELD GUIDE / 作战指导" or "REVEALED / 已揭示",.09,.025,.83,.065,12,Colors.Cyan)
    local guideToggle=ui.button(history,logOpen and "收起日志" or "展开对局日志",.09,.11,.84,0,function() if logOpen then logOpen=false;if small then guideOpen=false end else logOpen=true end;render() end)
    guideToggle.Size=UDim2.new(.84,0,0,44);guideToggle:SetAttribute("ControlId","GuideToggle")
    for _,child in ipairs(guideToggle:GetChildren()) do if child:IsA("TextLabel") then child.TextSize=14 end end
    local showGuide=Tutorial.Enabled and not logOpen
    if showGuide then Tutorial.render(ui,history,view,selection);ui.text(history,"对局日志",.09,.64,.84,.05,12,Colors.Cyan) end
    local list=ui.make("ScrollingFrame",{Name="RevealedEvents",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(.09,showGuide and .71 or .24),Size=UDim2.fromScale(.84,showGuide and .26 or .73),ScrollBarThickness=3,ScrollBarImageColor3=Colors.Cyan,CanvasSize=UDim2.fromOffset(0,0)},history)
    local lines={}
    for i,event in ipairs(view.events) do local value=logText(event);if value then table.insert(lines,{value="R"..event.round.."  "..value,index=i,id=event.source or event.target}) end end
    local start=logOpen and 1 or math.max(1,#lines-29);local row=0
    for i=start,#lines do
        local indent=defs[lines[i].id] and 25 or 0
        if indent>0 then Unit.glyph(ui,list,lines[i].id,18,Colors.Muted,UDim2.fromOffset(0,row+5)) end
        local t=ui.text(list,lines[i].value,0,0,1,0,14,Colors.Paper);t:SetAttribute("EventIndex",lines[i].index)
        local fontSize=Kit.textSize(14,ui.root.AbsoluteSize.Y,(ui.fontScale and ui.fontScale()) or 1)
        local width=math.max(60,history.AbsoluteSize.X*.84-indent-6)
        local height=math.max(40,game:GetService("TextService"):GetTextSize(t.ContentText,fontSize,t.Font,Vector2.new(width,100000)).Y+12)
        t.Position=UDim2.fromOffset(indent,row);t.Size=UDim2.new(1,-indent-6,0,height);row+=height+8
    end
    list.CanvasSize=UDim2.fromOffset(0,row);list.CanvasPosition=Vector2.new(0,math.max(0,row-list.AbsoluteSize.Y))
    local exit=ui.button(ui.root,"局内设置",.79,.84,.18,.065,function() if ui.openMenu then ui.openMenu() end end);exit:SetAttribute("ControlId","SessionMenu")
    if small then
        exit.Position=UDim2.fromScale(.565,.075);exit.Size=UDim2.new(.19,0,0,44)
        local guide=ui.button(ui.root,"日志",.775,.075,.19,0,function() guideOpen=not guideOpen;logOpen=guideOpen;detailsOpen=false;render() end);guide.Size=UDim2.new(.19,0,0,44);guide:SetAttribute("ControlId","GuidePanel")
        if ui.root.AbsoluteSize.Y<380 then
            exit.Position=UDim2.new(.565,0,0,26);guide.Position=UDim2.new(.775,0,0,26)
            for _,t in ipairs(ui.root:GetChildren()) do if t:IsA("TextLabel") and t.Position.Y.Scale>=.93 then t.Visible=false end end
        end
    end
    if ui.fit then ui.fit() end
    restoreFocus()
end
connecting=function(delayed)
    local focused=GuiService.SelectedObject
    local focusId=focused and focused:IsDescendantOf(ui.root) and focused:GetAttribute("ControlId")
    ui.root:ClearAllChildren();ui.root:SetAttribute("Screen","Connecting");ui.chrome()
    local p=ui.panel(ui.root,.035,.12,.48,.77,.04);p.Name="ConnectionPanel"
    ui.text(p,"ESTABLISHING LINK / 连接指挥室",.07,.04,.86,.08,12,Colors.Cyan)
    ui.text(p,delayed and "连接时间比预期更长" or "正在连接战略桌…",.07,.20,.86,.18,26,Colors.Paper)
    local explanation=ui.make("ScrollingFrame",{Name="ConnectionExplanation",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(.07,.42),Size=UDim2.new(.86,0,.58,delayed and -120 or -68),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=Colors.Cyan},p)
    local note=ui.text(explanation,delayed and "可以重新请求当前行动，或返回指挥室。已建立的对局会继续使用同一会话。" or "正在确认服务器状态。",0,0,1,0,16,Colors.Muted)
    note.Size=UDim2.new(1,-8,0,0);note.AutomaticSize=Enum.AutomaticSize.Y;note.TextYAlignment=Enum.TextYAlignment.Top
    local retry
    if delayed then retry=ui.button(p,"重新连接",.07,0,.86,0,function() Battle.start() end,true);retry.Position=UDim2.new(.07,0,1,-108);retry.Size=UDim2.new(.86,0,0,44);retry:SetAttribute("ControlId","Reconnect") end
    local back=ui.button(p,"返回指挥室",.07,0,.86,0,quit);back.Position=UDim2.new(.07,0,1,-56);back.Size=UDim2.new(.86,0,0,44);back:SetAttribute("ControlId","Quit")
    if ui.reflow then ui.reflow(ui.root,"Connecting") end
    if ui.fit then ui.fit() end
    if UserInputService.GamepadEnabled then GuiService.SelectedObject=focusId=="Quit" and back or retry or back end
end
local function waiting()
    local focused=GuiService.SelectedObject
    local focusId=focused and focused:IsDescendantOf(ui.root) and focused:GetAttribute("ControlId")
    queueSerial+=1;local ticket=queueSerial
    ui.root:ClearAllChildren();ui.root:SetAttribute("Screen","Waiting");ui.chrome()
    local p=ui.panel(ui.root,.035,.12,.48,.77,.04);p.Name="WaitingPanel"
    if ui.reflow then ui.reflow(ui.root,"Waiting") end
    local columns=ui.root.AbsoluteSize.X>=600
    local eyebrow=ui.text(p,"HEAD TO HEAD / 双人对峙",.07,0,.86,0,12,Colors.Cyan)
    eyebrow.Position=UDim2.new(.07,0,0,4);eyebrow.Size=UDim2.new(.86,0,0,22)
    local title=ui.text(p,"等待对手加入",.07,0,.86,0,26,Colors.Paper)
    title.Position=UDim2.new(.07,0,0,30);title.Size=UDim2.new(.86,0,0,42)
    local elapsed=ui.text(p,"",.07,0,.86,0,16,Colors.Cyan);elapsed.Name="QueueElapsed"
    elapsed.Position=UDim2.new(.07,0,0,76);elapsed.Size=UDim2.new(.86,0,0,28)
    local body=ui.make("ScrollingFrame",{Name="QueueExplanation",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(.07,0,0,112),Size=UDim2.new(.86,0,1,columns and -176 or -228),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=Colors.Cyan},p)
    local note=ui.text(body,"",0,0,1,0,16,Colors.Muted);note.Name="QueueGuidance"
    note.Size=UDim2.new(1,-8,0,0);note.AutomaticSize=Enum.AutomaticSize.Y;note.TextYAlignment=Enum.TextYAlignment.Top
    local practice=ui.button(p,"改为 AI 练习",.07,0,columns and .42 or .86,0,function()
        if not queued then return end
        -- One request: the server removes the queue entry or retains an already paired PvP session.
        queued=false;queueStarted=nil;queueSerial+=1;pending=true;slow=false
        Battle.Mode="AI";Battle.Difficulty="Standard"
        remote:FireServer({command="Start",mode="AI",difficulty="Standard"})
        watchRequest(Network.StartTimeout);connecting(false)
    end,true)
    practice.Position=UDim2.new(.07,0,1,columns and -56 or -108);practice.Size=UDim2.new(columns and .42 or .86,0,0,44);practice:SetAttribute("ControlId","QueuePractice")
    local back=ui.button(p,"取消等待",columns and .51 or .07,0,columns and .42 or .86,0,function() if queued then quit() end end)
    back.Position=UDim2.new(columns and .51 or .07,0,1,-56);back.Size=UDim2.new(columns and .42 or .86,0,0,44);back:SetAttribute("ControlId","Quit")
    if ui.fit then ui.fit() end
    local function tick()
        if ticket~=queueSerial or not queued or not elapsed.Parent then return end
        local seconds=math.max(0,math.floor(os.clock()-(queueStarted or os.clock())))
        elapsed.Text=string.format("已等待 %02d:%02d",math.floor(seconds/60),seconds%60)
        note.Text=seconds>=Network.QueueHintAfter and "暂时还没有对手加入。可继续等待，或改为 AI 练习。\n\n双人模式仅匹配同一服务器的玩家；好友需要进入同一服务器。改为练习会退出当前等待。" or "正在匹配同一服务器的下一位双人玩家。\n\n好友需要进入同一服务器。也可改为 AI 练习，不必一直等待。"
        task.delay(Network.QueueTick,tick)
    end
    tick()
    if UserInputService.GamepadEnabled then GuiService.SelectedObject=focusId=="Quit" and back or practice end
end
function Battle.init(context)
    ui=context
    if Director.bind then Director.bind(ui.root) end
    local panelFactory=context.panel
    ui.panel=function(parent,x,y,w,h,alpha) return panelFactory(parent,x,y,w,h,alpha,true) end
    local remotes=game:GetService("ReplicatedStorage"):WaitForChild("DeadlockRemotes")
    remote=remotes:WaitForChild("Intent")
    remotes.State.OnClientEvent:Connect(function(message)
        if message.queued then
            queueStarted=queueStarted or os.clock()
            queued=true;requestSerial+=1;view=nil;pending=true;waiting()
            return
        end
        if message.startError then view=nil;pending=false;queued=false;queueStarted=nil;queueSerial+=1;requestSerial+=1;Director.reset();ui.route("Setup");return end
        if message.closed then view=nil;pending=false;queued=false;queueStarted=nil;queueSerial+=1;requestSerial+=1;Director.reset();StrategicTable.reset();if message.abandoned then ui.route("Abandoned") else ui.route(exitRoute) end;exitRoute="Menu";return end
        if not message.view then return end
        if not view or ((message.ack or message.started) and not message.error) or (message.synced and view.phase~="CoreSelection" and view.revision~=message.view.revision) or view.phase~=message.view.phase or view.actor~=message.view.actor then selection={} end
        view=message.view
        local session=view.sessionId
        Director.update(view,function() if view and view.sessionId==session then render() end end,markResolution)
        queued=false;queueStarted=nil;queueSerial+=1;if message.ack or message.started or message.error or message.synced then pending=false;slow=false;requestSerial+=1 end
        if message.ack or message.started then detailsOpen=message.view.mode=="Training";guideOpen=false end
        if view.phase=="GameOver" and ui.closeMenu then ui.closeMenu() end
        hint=message.error=="TrainingSkillRequired" and "这一步需要先选择复苏，释放修复脉冲。" or message.error and "提交未生效，请重新选择。" or ""
        render()
    end)
end
function Battle.start()
    pending=true;view=nil;hint="";slow=false;queued=false
    remote:FireServer({command="Start",mode=Battle.Mode or "AI",difficulty=Battle.Difficulty or "Standard"})
    watchRequest(Network.StartTimeout);connecting(false)
end
function Battle.refresh() if view then render() elseif queued then waiting() elseif pending then connecting(slow) end end
function Battle.again()
    if not view or view.phase~="GameOver" or pending then return end
    if view.mode=="PvP" then
        if not view.rematch or not view.rematch.available then quit("Setup");return end
        pending=true;remote:FireServer({command="Restart",sessionId=view.sessionId,accept=not view.rematch.requested});watchRequest(Network.ActionTimeout);render();return
    end
    if view.mode~="AI" then quit("Setup");return end
    local id=view.sessionId;view=nil;pending=true;slow=false;queued=false;Director.reset();StrategicTable.reset()
    remote:FireServer({command="Restart",sessionId=id});watchRequest(Network.StartTimeout);connecting(false)
end
function Battle.active() return view~=nil or pending end
function Battle.inProgress() return pending or (view~=nil and view.phase~="GameOver") end
function Battle.quit() quit() end
return Battle
