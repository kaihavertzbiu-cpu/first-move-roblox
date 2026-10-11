local Colors=require(script.Parent.PresentationConfig).Colors
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("DeadlockShared")
local Config=require(script.Parent.UnitIdentity)
local names={};for _,h in ipairs(Config.heroes) do names[h.id]=h.name end
local Camera=require(script.Parent.CameraController)
local Timing=require(script.Parent.PresentationConfig).Report
local TweenService=game:GetService("TweenService")
local Story=require(script.Parent.ReportStory)
local Locale=require(script.Parent.LocaleController)
local Units=require(script.Parent.UnitPresentation)
local Report={}
local lastSession
local reading
function Report.capture()
    if not reading then return end
    if reading.list and reading.list.Parent then
        reading.scrolls[reading.mode..":"..tostring(reading.round or "all")]=reading.list.CanvasPosition.Y
    end
    if reading.body and reading.body.Parent then reading.bodyY=reading.body.CanvasPosition.Y end
    reading.frozen=true
end
function Report.render(ui,view,quit,actions)
    local key=view.sessionId or view
    if not reading or reading.key~=key then reading={key=key,mode="Highlights",scrolls={},bodyY=0,step=1} end
    local memory=reading
    memory.frozen=false
    local compact=ui.root.AbsoluteSize.X<760 and ui.root.AbsoluteSize.X/math.max(ui.root.AbsoluteSize.Y,1)<1.5
    local short=not compact and ui.root.AbsoluteSize.Y<540
    local shallow=short and ui.root.AbsoluteSize.Y<380
    local report=view.report
    local animate=lastSession~=view.sessionId and not Camera.Reduced
    lastSession=view.sessionId
    local function reveal(panel,delay,duration)
        if not animate then return end
        panel.GroupTransparency=1
        task.delay(delay,function() if panel.Parent then TweenService:Create(panel,TweenInfo.new(duration,Enum.EasingStyle.Quad),{GroupTransparency=0}):Play() end end)
    end
    local function count(label,final,delay)
        label:SetAttribute("FinalStat",final)
        if not animate then return end
        label.Text="0"
        task.delay(delay,function()
            if not label.Parent then return end
            local value=Instance.new("NumberValue")
            local connection=value.Changed:Connect(function(n) if label.Parent then label.Text=tostring(math.floor(n+.5)) end end)
            TweenService:Create(value,TweenInfo.new(Timing.CountTime,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=final}):Play()
            task.delay(Timing.CountTime,function() if label.Parent then label.Text=tostring(final) end;connection:Disconnect();value:Destroy() end)
        end)
    end
    local story=Story.build(view)
    local title=story.title
    local banner=ui.panel(ui.root,.035,.10,.93,compact and .23 or short and .25 or .23,.02)
    banner.Name="ReportBanner"
    if shallow then banner.Size=UDim2.new(.93,0,0,100) end
    local accent=view.winner=="A" and Colors.Cyan or view.winner=="B" and Colors.Amber or Colors.Muted
    local seal=ui.line(banner,.035,.02,.93,accent)
    seal.Size=UDim2.new(.93,0,0,2)
    local kicker=ui.text(banner,"AFTER ACTION / 行动战报",.035,.04,.68,.12,12,Colors.Cyan)
    local headline=ui.text(banner,title,.035,.17,.6,.39,compact and 30 or short and 24 or 42,Colors.Paper,Enum.Font.GothamBold)
    local ending=story.subtitle
    local reached=Locale.isEnglish()and "Ended in round "..view.round or "作战至第 "..view.round.." 回合"
    local subtitle=ui.text(banner,(compact or short)and reached or Locale.translate(ending).."  /  "..reached,.035,.58,compact and .53 or .66,.27,16,Colors.Muted)
    local returnButton=ui.button(banner,"返回指挥室",compact and .60 or .75,.57,compact and .365 or .215,.30,quit,true)
    returnButton:SetAttribute("ControlId","ReportReturn")
    returnButton:SetAttribute("AudioCue","back")
    if short then
        kicker.Position=UDim2.new(.035,0,0,4);kicker.Size=UDim2.new(.68,0,0,18)
        headline.Position=UDim2.new(.035,0,0,26);headline.Size=UDim2.new(.60,0,0,32)
        subtitle.Position=UDim2.new(.035,0,1,-28);subtitle.Size=UDim2.new(.66,0,0,24)
        returnButton.Position=UDim2.new(.75,0,1,-56);returnButton.Size=UDim2.new(.215,0,0,44)
        if report then local survivors=ui.text(banner,report.teams.A.survivors.." / 5  存活",.75,0,.215,0,13,Colors.Paper);survivors.Position=UDim2.new(.75,0,0,4);survivors.Size=UDim2.new(.215,0,0,18) end
    else
        ui.text(banner,compact and "RESOLVED" or "RESOLUTION CONFIRMED",compact and .60 or .75,.13,compact and .365 or .215,.12,11,accent)
        if report then ui.text(banner,report.teams.A.survivors.." / 5  存活",compact and .60 or .75,.29,compact and .365 or .215,.20,20,Colors.Paper,Enum.Font.GothamMedium) end
    end
    if actions and actions.again then
        local rematch=view.rematch
        local label=view.mode=="PvP" and (not rematch or not rematch.available) and "重新匹配" or view.mode=="PvP" and rematch.requested and "取消再战请求" or view.mode=="PvP" and rematch.opponentRequested and "接受再战" or view.mode=="PvP" and "邀请再战" or "再来一局"
        local again=ui.button(banner,actions.sync and "同步再战状态" or actions.pending and "正在提交…" or label,compact and .60 or .75,0,compact and .365 or .215,0,actions.sync or actions.again,true)
        again:SetAttribute("ControlId","ReportRematch")
        again:SetAttribute("AudioCue","confirm")
        again:SetAttribute("Disabled",actions.pending==true and not actions.sync);again.Selectable=not actions.pending or actions.sync~=nil
        if view.mode=="PvP" then
            subtitle.Text=(not rematch or not rematch.available) and "对手已离开 · 可重新匹配" or rematch.requested and "已邀请对手 · 双方同意后再战" or rematch.opponentRequested and "对手邀请再战 · 可接受或返回" or "双方同意后再战 · 下局交换选人侧"
        end
        for _,child in ipairs(banner:GetChildren()) do if child:IsA("TextLabel") then local source=child:GetAttribute("LocaleSource")or child.Text;if source=="RESOLVED"or source=="RESOLUTION CONFIRMED"or source:find(" / 5  存活",1,true)then child.Visible=false end end end
        if short then
            again.Position=UDim2.new(.59,0,1,-56);again.Size=UDim2.new(.18,0,0,44)
            returnButton.Position=UDim2.new(.79,0,1,-56);returnButton.Size=UDim2.new(.175,0,0,44)
            headline.Size=UDim2.new(.52,0,0,32);subtitle.Size=UDim2.new(.52,0,0,24)
        else
            again.Position=UDim2.new(compact and .60 or .75,0,1,-108);again.Size=UDim2.new(compact and .365 or .215,0,0,44)
            returnButton.Position=UDim2.new(compact and .60 or .75,0,1,-56);returnButton.Size=UDim2.new(compact and .365 or .215,0,0,44)
        end
    end
    reveal(banner,0,Timing.BannerTime)
    if not report then ui.text(ui.root,"战报尚未收到。",.06,.5,.8,.2,20,Colors.Paper);return end
    local strip=ui.panel(ui.root,.035,compact and .355 or short and .37 or .35,.93,compact and .205 or short and .18 or .11,.03)
    strip.Name="MetricStrip"
    reveal(strip,Timing.SectionGap,Timing.SectionTime)
    for i,metric in ipairs({{"有效伤害","damage"},{"有效恢复","healing"},{"格挡命中","blocks"},{"掠魂处决","executions"}}) do
        local x=.035+(compact and (i-1)%2*.48 or (i-1)*.245)
        local y=compact and math.floor((i-1)/2)*.5 or 0
        ui.text(strip,metric[1],x,y+.03,compact and .43 or .22,compact and .16 or .27,13,Colors.Muted)
        local number=ui.text(strip,tostring(report.teams.A[metric[2]]),x,y+(compact and .19 or .31),compact and .22 or .12,compact and .30 or .60,28,Colors.Paper,Enum.Font.GothamMedium)
        count(number,report.teams.A[metric[2]],Timing.SectionGap)
        ui.text(strip,"对手 "..report.teams.B[metric[2]],x+(compact and .22 or .10),y+(compact and .19 or .31),compact and .22 or .12,compact and .30 or .60,13,Colors.Muted)
    end
    local left=ui.panel(ui.root,.035,compact and .58 or short and .575 or .48,compact and .93 or .29,compact and .12 or short and .33 or .44,.04)
    left.Name="OverviewPanel"
    reveal(left,Timing.SectionGap*2,Timing.SectionTime)
    local overviewHeading=ui.text(left,view.reward and "本局收益" or "行动概览",.09,0,.82,0,14,Colors.Cyan)
    overviewHeading.Position=UDim2.new(.09,0,0,4);overviewHeading.Size=UDim2.new(.82,0,0,24)
    local summary="你存活 "..report.teams.A.survivors.." / 5  ·  剩余 "..report.teams.A.hp.." HP\n对手存活 "..report.teams.B.survivors.." / 5\n完整回合 "..report.completedRounds.." / "..report.finalRound
    if view.reward and view.reward.rating~=0 then summary="段位 "..string.format("%+d",view.reward.rating).." 分\n"..summary end
    if report.turningRound then summary..="\n阵亡最多轮：R"..report.turningRound.."（"..report.turningDeaths.." 名）" end
    local overview=ui.make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(.09,.22),Size=UDim2.fromScale(.82,.72),CanvasSize=UDim2.fromOffset(0,135),ScrollBarThickness=3,ScrollBarImageColor3=Colors.Cyan},left)
    overview.Name="OverviewList"
    overview.Position=UDim2.new(.09,0,0,32);overview.Size=UDim2.new(.82,0,1,-40)
    local summaryY=view.reward and 76 or 0
    if view.reward then
        for i,reward in ipairs({{"核晶",view.reward.credits,Colors.Amber},{"经验",view.reward.xp,Colors.Cyan}})do
            local x=(i-1)*.52
            local amount=ui.text(overview,tostring(reward[2]),x,0,.46,0,30,reward[3],Enum.Font.GothamBold)
            amount.Name=i==1 and "RewardCredits" or "RewardXP"
            amount.Position=UDim2.new(x,0,0,0);amount.Size=UDim2.new(.46,0,0,38)
            count(amount,reward[2],Timing.SectionGap*2)
            local caption=ui.text(overview,reward[1],x,0,.46,0,14,Colors.Muted)
            caption.Position=UDim2.new(x,0,0,40);caption.Size=UDim2.new(.46,0,0,24)
        end
        local separator=ui.line(overview,0,0,.96,Colors.Line)
        separator.Position=UDim2.fromOffset(0,68)
    end
    local t=ui.text(overview,summary,0,0,1,0,15,Colors.Paper);t.Position=UDim2.fromOffset(0,summaryY);t.Size=UDim2.new(1,-5,0,135);t.TextYAlignment=Enum.TextYAlignment.Top
    local function measureOverview()
        local bounds=game:GetService("TextService"):GetTextSize(t.ContentText,t.TextSize,t.Font,Vector2.new(math.max(overview.AbsoluteSize.X-5,1),100000))
        local height=math.ceil(bounds.Y)+8
        t.Size=UDim2.new(1,-5,0,height);overview.CanvasSize=UDim2.fromOffset(0,summaryY+height)
    end
    overview:GetPropertyChangedSignal("AbsoluteSize"):Connect(measureOverview)
    t:GetPropertyChangedSignal("TextSize"):Connect(measureOverview)
    task.defer(measureOverview)
    local right=ui.panel(ui.root,compact and .035 or .34,compact and .72 or short and .575 or .48,compact and .93 or .625,compact and .19 or short and .33 or .44,.04)
    right.Name="RoundReview"
    reveal(right,Timing.SectionGap*3,Timing.SectionTime)
    local list=ui.make("ScrollingFrame",{Name="ReviewList",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(.04,0,0,56),Size=UDim2.new(.92,0,1,-65),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollBarImageColor3=Colors.Cyan},right)
    local tabs={};local mode=memory.mode;local roundFilter=memory.round
    memory.list=list;memory.body=nil
    local restoring=true;local reviewTicket=0
    local function pageKey(page,round) return page..":"..tostring(round or "all") end
    list:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if not restoring and not memory.frozen and list.Parent then memory.scrolls[pageKey(mode,roundFilter)]=list.CanvasPosition.Y end
    end)
    local function review(nextMode,filterRound)
        if not restoring then memory.scrolls[pageKey(mode,roundFilter)]=list.CanvasPosition.Y end
        restoring=true;reviewTicket+=1;local ticket=reviewTicket
        mode=nextMode;roundFilter=filterRound;memory.mode=mode;memory.round=roundFilter
        local restoreY=memory.scrolls[pageKey(mode,roundFilter)] or 0
        list:ClearAllChildren();list.CanvasPosition=Vector2.zero
        ui.make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},list)
        local order=0
        local function row(value,size,color)
            order+=1;local t=ui.text(list,value,0,0,1,0,size,color)
            t.Size=UDim2.new(1,-8,0,0);t.AutomaticSize=Enum.AutomaticSize.Y;t.TextYAlignment=Enum.TextYAlignment.Top;t.LayoutOrder=order
        end
        if mode=="Highlights" then
            local closing=story.closing
            if #closing.steps>0 then
                order+=1
                local replay=ui.make("Frame",{Name="ClosingReplay",BorderSizePixel=0,BackgroundColor3=Colors.Panel,BackgroundTransparency=.15,Size=UDim2.new(1,-8,0,compact and 288 or short and 220 or 248),LayoutOrder=order},list)
                local content=ui.make("Frame",{Name="ReplayContent",BackgroundTransparency=1,Position=UDim2.new(0,10,0,6),Size=UDim2.new(1,-20,0,compact and 226 or short and 158 or 186)},replay)
                local previous,nextButton
                local function step(delta)
                    memory.step=math.clamp((memory.step or 1)+delta,1,#closing.steps)
                    local entry=closing.steps[memory.step]
                    local event=view.events[entry.index]
                    replay:SetAttribute("PublicEventIndex",entry.index);replay:SetAttribute("EventKind",entry.kind)
                    content:ClearAllChildren()
                    local label=ui.text(content,"R"..string.format("%02d",closing.round).." · "..string.format("%02d / %02d",memory.step,#closing.steps).." · 公开结算",0,0,1,0,12,Colors.Cyan)
                    label.Size=UDim2.new(1,0,0,24);label.TextWrapped=false
                    local owners={};for side,roster in pairs(view.rosters or {}) do for _,h in ipairs(roster) do owners[h.id]=side end end
                    for i,id in ipairs({event.source or false,event.target or false}) do
                        local x=(i-1)*.62
                        local card=ui.make("Frame",{Name=i==1 and "ReplaySource" or "ReplayTarget",BorderSizePixel=0,BackgroundColor3=Colors.Ink,Position=UDim2.new(x,0,0,30),Size=UDim2.new(.38,0,0,compact and 112 or 72)},content)
                        local side=owners[id];local color=side=="A" and Colors.Cyan or side=="B" and Colors.Amber or Colors.Muted
                        ui.line(card,0,0,1,color)
                        if id and Config.byId[id] then
                            Units.portrait(ui,card,id,compact and UDim2.new(.5,-26,0,4)or UDim2.fromOffset(0,4),UDim2.fromOffset(compact and 52 or 62,compact and 52 or 64),true)
                            local title=ui.text(card,names[id],0,0,1,0,18,Colors.Paper,Enum.Font.GothamBold)
                            title.Position=UDim2.fromOffset(65,12);title.Size=UDim2.new(1,-68,0,28);title.TextWrapped=false
                            if compact then title.Position=UDim2.fromOffset(4,58);title.Size=UDim2.new(1,-8,0,28);title.TextXAlignment=Enum.TextXAlignment.Center end
                            local owner=ui.text(card,side=="A" and "己方" or side=="B" and "对手" or "已揭示",0,0,1,0,12,color)
                            owner.Position=UDim2.fromOffset(65,44);owner.Size=UDim2.new(1,-68,0,24);owner.TextWrapped=false
                            if compact then owner.Position=UDim2.fromOffset(4,86);owner.Size=UDim2.new(1,-8,0,24);owner.TextXAlignment=Enum.TextXAlignment.Center end
                        else
                            local value=i==1 and (event.owner=="A" and "己方行动" or event.owner=="B" and "对手行动" or "结算确认") or event.kind=="AttackCommitted" and "尚未揭示" or "无需目标"
                            local title=ui.text(card,value,.06,0,.88,1,12,Colors.Muted);title.TextWrapped=true
                        end
                    end
                    local value=event.kind=="Damage" and "−"..tostring(event.effective or event.amount) or event.kind=="Heal" and "+"..tostring(event.amount) or ({Execute="处决",Death="阵亡",Block="格挡",LinkTrigger="命线",Lock="封锁",Skill="技能"})[event.kind] or "→"
                    if Locale.isEnglish()then value=({Execute="EXEC",Death="KO",Block="BLOCK",LinkTrigger="LINK",Lock="LOCK",Skill="CAST"})[event.kind]or value end
                    local impact=ui.text(content,value,.39,0,.22,0,(event.kind=="Damage" or event.kind=="Heal") and 29 or Locale.isEnglish()and 17 or 22,event.kind=="Heal" and Colors.Cyan or Colors.Paper,Enum.Font.GothamBold)
                    impact.Position=UDim2.new(.39,0,0,38);impact.Size=UDim2.new(.22,0,0,42);impact.TextXAlignment=Enum.TextXAlignment.Center;impact.TextWrapped=false
                    local cue=ui.text(content,"→",.39,0,.22,0,16,Colors.Muted);cue.Position=UDim2.new(.39,0,0,78);cue.Size=UDim2.new(.22,0,0,24);cue.TextXAlignment=Enum.TextXAlignment.Center;cue.TextWrapped=false
                    local caption=ui.text(content,entry.text,0,0,1,0,18,Colors.Paper)
                    caption.Name="ReplayFact";caption.Position=UDim2.fromOffset(0,compact and 150 or 110);caption.Size=UDim2.new(1,0,0,short and 44 or 66);caption.TextYAlignment=Enum.TextYAlignment.Top
                    previous:SetAttribute("Disabled",memory.step==1);previous.Selectable=memory.step>1
                    nextButton:SetAttribute("Disabled",memory.step==#closing.steps);nextButton.Selectable=memory.step<#closing.steps
                    for _,button in ipairs({previous,nextButton}) do
                        local disabled=button:GetAttribute("Disabled")
                        button.BackgroundTransparency=disabled and .5 or .15
                        for _,child in ipairs(button:GetChildren()) do if child:IsA("TextLabel") then child.TextColor3=disabled and Colors.Muted or Colors.Paper end end
                    end
                    if ui.fit then ui.fit() end
                end
                previous=ui.button(replay,"上一步",.035,0,.43,0,function() step(-1) end)
                previous.Position=UDim2.new(.035,0,1,-54);previous.Size=UDim2.new(.43,0,0,44);previous:SetAttribute("ControlId","ReportStepPrevious")
                nextButton=ui.button(replay,"下一步",.535,0,.43,0,function() step(1) end)
                nextButton.Position=UDim2.new(.535,0,1,-54);nextButton.Size=UDim2.new(.43,0,0,44);nextButton:SetAttribute("ControlId","ReportStepNext")
                step(0)
            end
            row(closing.summary,18,Colors.Paper)
            if closing.partial then row("早期起手已超出档案保留范围；以下为保留的公开结算。",14,Colors.Muted) end
            for i,step in ipairs(closing.steps) do
                order+=1
                local item=ui.make("Frame",{Name="ClosingStep",BackgroundTransparency=1,Size=UDim2.new(1,-8,0,0),AutomaticSize=Enum.AutomaticSize.Y,LayoutOrder=order},list)
                item:SetAttribute("PublicEventIndex",step.index)
                item:SetAttribute("EventKind",step.kind)
                local color=step.side=="A" and Colors.Cyan or step.side=="B" and Colors.Amber or Colors.Muted
                local mark=ui.make("Frame",{Name="TimelineMark",BorderSizePixel=0,BackgroundColor3=color,Position=UDim2.fromOffset(2,12),Size=UDim2.fromOffset(4,4)},item)
                if step.unit and Config.byId[step.unit] then Units.glyph(ui,item,step.unit,22,color,UDim2.fromOffset(15,3)) end
                local owner=step.side=="A" and "你" or step.side=="B" and "对手" or "系统"
                local label=ui.text(item,string.format("%02d",i).."  "..owner.." · "..step.text,0,0,1,0,16,Colors.Paper)
                label.Name="ClosingText";label.Position=UDim2.fromOffset(46,0);label.Size=UDim2.new(1,-46,0,0);label.AutomaticSize=Enum.AutomaticSize.Y;label.TextYAlignment=Enum.TextYAlignment.Top
                local padding=ui.make("UIPadding",{PaddingBottom=UDim.new(0,6)},item)
            end
            if #closing.steps==0 then row("该档案未保留终局事件，可查看逐回合汇总。",14,Colors.Muted) end
        elseif mode=="Events" then
            row(filterRound and "R"..string.format("%02d",filterRound).." · 按实际揭示顺序" or "按实际揭示顺序",14,Colors.Cyan)
            if view.events[1] and view.events[1].round>1 then row("早期事件已超出档案保留范围；回合汇总仍可查阅。",14,Colors.Muted) end
            local found=false
            for i,event in ipairs(view.events) do if not filterRound or event.round==filterRound then
                local value=Story.event(event)
                if value then found=true;row("R"..string.format("%02d",event.round).." · "..i.."  /  "..value,14,Colors.Paper) end
            end end
            if not found then row("这一回合没有保留的公开事件。",14,Colors.Muted) end
        else
            for _,round in ipairs(report.rounds) do
                local heading="R"..string.format("%02d",round.round).."  /  "..(round.initiative=="A" and "你先攻" or round.initiative=="B" and "对手先攻" or "未揭示")
                if round.ties>0 then heading..="  ·  同核 "..round.ties.." 次" end
                local fallen={};for _,h in ipairs(round.fallen) do table.insert(fallen,(h.owner=="A" and "你 · " or "对手 · ")..names[h.id]) end
                row(heading,15,Colors.Paper)
                row("有效伤害  "..round.teams.A.damage.." : "..round.teams.B.damage.."   /   恢复  "..round.teams.A.healing.." : "..round.teams.B.healing.."\n"..(#fallen>0 and "阵亡："..table.concat(fallen,"、") or "无单位阵亡"),14,Colors.Muted)
                local number=round.round
                local b=ui.button(list,"查看 R"..string.format("%02d",number).." 事件",0,0,1,0,function() review("Events",number) end)
                order+=1;b.LayoutOrder=order;b.Size=UDim2.new(1,-8,0,44);b:SetAttribute("ControlId","ReportRound:"..number)
            end
        end
        for key,tab in pairs(tabs) do
            tab:SetAttribute("Selected",key==mode)
            tab.BackgroundColor3=key==mode and Colors.Paper or Colors.Panel
            tab:SetAttribute("RestColor",tab.BackgroundColor3)
            for _,t in ipairs(tab:GetChildren()) do if t:IsA("TextLabel") then t.TextColor3=key==mode and Colors.Ink or Colors.Paper end end
        end
        if ui.fit then ui.fit() end
        task.defer(function()
            game:GetService("RunService").Heartbeat:Wait()
            if not list.Parent or ticket~=reviewTicket then return end
            list.CanvasPosition=Vector2.new(0,math.clamp(restoreY,0,math.max(0,list.AbsoluteCanvasSize.Y-list.AbsoluteSize.Y)))
            restoring=false
        end)
    end
    for i,tab in ipairs({{"Highlights","终局复盘","ReportHighlights"},{"Rounds","逐回合","ReportRounds"},{"Events","完整记录","ReportEvents"}}) do
        local width=compact and .285 or .24
        local key=tab[1];local b=ui.button(right,tab[2],.04+(i-1)*(compact and .315 or .26),.03,width,0,function() review(key) end)
        b.Size=UDim2.new(width,0,0,44);b:SetAttribute("ControlId",tab[3]);tabs[key]=b
    end
    if short or compact then
        local top=ui.root.AbsoluteSize.Y*.10+(shallow and 100 or banner.AbsoluteSize.Y)+10
        local metricHeight=compact and 125 or 60
        local reviewHeight=short and math.max(240,math.min(Timing.CompactReviewHeight,ui.root.AbsoluteSize.Y-top-8)) or Timing.CompactReviewHeight
        local body=ui.make("ScrollingFrame",{Name="ReportBody",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(.035,0,0,top),Size=UDim2.new(.93,0,1,-top-8),CanvasSize=UDim2.fromOffset(0,reviewHeight+metricHeight+172),ScrollBarThickness=3,ScrollBarImageColor3=Colors.Cyan},ui.root)
        right.Parent=body;right.Position=UDim2.fromOffset(0,0);right.Size=UDim2.new(1,-8,0,reviewHeight)
        strip.Parent=body;strip.Position=UDim2.fromOffset(0,reviewHeight+12);strip.Size=UDim2.new(1,-8,0,metricHeight)
        left.Parent=body;left.Position=UDim2.fromOffset(0,reviewHeight+metricHeight+24);left.Size=UDim2.new(1,-8,0,148)
        local bodyRestoring=true;local restoreBodyY=memory.bodyY
        memory.body=body
        body:GetPropertyChangedSignal("CanvasPosition"):Connect(function() if not bodyRestoring and not memory.frozen and body.Parent then memory.bodyY=body.CanvasPosition.Y end end)
        task.defer(function()
            game:GetService("RunService").Heartbeat:Wait()
            if not body.Parent then return end
            body.CanvasPosition=Vector2.new(0,math.clamp(restoreBodyY,0,math.max(0,body.AbsoluteCanvasSize.Y-body.AbsoluteSize.Y)))
            bodyRestoring=false
        end)
    end
    review(memory.mode,memory.round)
    if ui.fit then ui.fit() end
end
return Report
