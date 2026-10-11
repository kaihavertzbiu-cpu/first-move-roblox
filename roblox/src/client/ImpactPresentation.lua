-- HUD-only cinematic accents. The strategic table never carries names or numbers.
local TweenService=game:GetService("TweenService")
local Config=require(script.Parent.PresentationConfig)
local Identity=require(script.Parent.UnitIdentity)
local Portrait=require(script.Parent.UnitPortrait)
local Locale=require(script.Parent.LocaleController)
local C,I=Config.Colors,Config.Impact
local Impact={Counts={}}
local root,group,layer;local rootConnection;local tweens={};local serial=0
local function make(cls,props,parent)
    local o=Instance.new(cls);for key,value in pairs(props) do o[key]=value end;o.Parent=parent
    if o:IsA("TextLabel")then Locale.bind(o)end
    return o
end
local function animate(o,time,goal)
    local t=TweenService:Create(o,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal);table.insert(tweens,t);t:Play()
end
function Impact.reset()
    serial+=1;for _,t in ipairs(tweens) do t:Cancel() end;tweens={}
    if group then group:Destroy();group=nil end
    if root then local heading=root:FindFirstChild("OwnershipHeading");if heading then heading.Visible=true end end
end
function Impact.bind(value)
    Impact.reset()
    if rootConnection then rootConnection:Disconnect() end
    if layer then layer:Destroy() end
    root=value
    layer=make("Frame",{Name="CinematicLayer",BackgroundTransparency=1,Position=root.Position,Size=root.Size,AnchorPoint=root.AnchorPoint,ZIndex=40,Active=false},root.Parent)
    rootConnection=root.Destroying:Connect(function() Impact.reset();if layer then layer:Destroy();layer=nil end;root=nil end)
end
local function glyph(parent,id,color,size)
    local def=Identity.byId[id];if not def then return end
    local icon=make("Frame",{Name="UnitInsignia",BackgroundTransparency=1,Position=UDim2.fromOffset(14,17),Size=UDim2.fromOffset(size,size),ZIndex=42},parent)
    for _,path in ipairs(def.paths) do for i=1,#path-1 do
        local a,b=path[i],path[i+1];local dx,dy=(b[1]-a[1])*size,(b[2]-a[2])*size
        make("Frame",{BorderSizePixel=0,BackgroundColor3=color,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((a[1]+b[1])*size/2,(a[2]+b[2])*size/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),2),Rotation=math.deg(math.atan2(dy,dx)),ZIndex=42},icon)
    end end
end
local function emblem(parent,winner,color)
    local icon=make("Frame",{Name="OutcomeEmblem",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,I.EmblemTop),Size=UDim2.fromOffset(I.EmblemSize,I.EmblemSize),ZIndex=42},parent)
    icon:SetAttribute("Winner",winner or "Draw")
    for _,path in ipairs(I.Emblems[winner] or I.Emblems.Draw) do for i=1,#path-1 do
        local a,b=path[i],path[i+1];local dx,dy=(b[1]-a[1])*I.EmblemSize,(b[2]-a[2])*I.EmblemSize
        make("Frame",{BorderSizePixel=0,BackgroundColor3=color,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((a[1]+b[1])*I.EmblemSize/2,(a[2]+b[2])*I.EmblemSize/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),2),Rotation=math.deg(math.atan2(dy,dx)),ZIndex=42},icon)
    end end
end
local function show(title,detail,color,id,hold,reduced,outcome,winner)
    if not root or not root.Parent then return end
    Impact.reset();local ticket=serial
    layer.Position=root.Position;layer.Size=root.Size;layer.AnchorPoint=root.AnchorPoint
    local w,h=root.AbsoluteSize.X,root.AbsoluteSize.Y
    local compact=w<900 or w/math.max(h,1)<1.5
    local short=compact and h<380 and not outcome
    local cinematic=id~=nil and not short and w>=540 and h>=380
    local width=short and math.floor(w*.5) or math.min(cinematic and I.PortraitWidth or outcome and 560 or I.Width,w*(compact and .90 or .66))
    if Locale.isEnglish()and not id and not outcome then
        local en=Locale.translate(title);title=({["命线击破"]="LIFELINE KO",["双重击破"]="DOUBLE KO",["三重击破"]="TRIPLE KO",["连续击破"]="CHAIN KO",["击破"]="ELIMINATION",["阵亡"]="UNIT LOST",["处决"]="EXECUTION"})[title]or en
    end
    local height=outcome and I.OutcomeHeight or short and I.CompactHeight or cinematic and I.PortraitHeight or I.Height
    local x=short and .035 or compact and .5 or .55
    local y=short and 26 or outcome and math.max(8,(h-height)*.42) or cinematic and math.max(16,(h-height)*.46) or h*.38
    group=make("CanvasGroup",{Name="ImpactPresentation",BorderSizePixel=0,BackgroundColor3=C.Ink,BackgroundTransparency=.06,GroupTransparency=reduced and 0 or 1,AnchorPoint=Vector2.new(short and 0 or .5,0),Position=UDim2.new(x,0,0,y),Size=UDim2.fromOffset(width,height),ZIndex=40,Active=false},layer)
    group:SetAttribute("PresentationKind",outcome and "Outcome" or id and "Skill" or "Death")
    local scale=make("UIScale",{Scale=reduced and 1 or outcome and I.OutcomeScale or I.SkillScale},group)
    if not reduced then
        -- One directional ink streak; no repeating flash or full-screen whiteout.
        local sweep=make("Frame",{Name="InkSweep",BorderSizePixel=0,BackgroundColor3=color,BackgroundTransparency=.25,Rotation=-16,Position=UDim2.new(0,-30,0,0),Size=UDim2.new(0,6,1,0),ZIndex=41},group)
        animate(sweep,.42,{Position=UDim2.new(1,-12,0,0),BackgroundTransparency=1})
        if outcome then
            for i=1,12 do
                local a=i*math.pi/6
                local shard=make("Frame",{Name="OutcomeShard",AnchorPoint=Vector2.new(.5,.5),BackgroundColor3=color,BorderSizePixel=0,BackgroundTransparency=.2,Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(3,18),Rotation=i*30,ZIndex=41},group)
                animate(shard,.85,{Position=UDim2.new(.5,math.cos(a)*width*.46,.5,math.sin(a)*height*.46),BackgroundTransparency=1,Rotation=i*30+65})
            end
        end
    end
    make("Frame",{BorderSizePixel=0,BackgroundColor3=color,Position=UDim2.fromOffset(0,0),Size=UDim2.new(1,0,0,3),ZIndex=41},group)
    local left=cinematic and math.floor(width*.43) or not short and id and 70 or 14
    if not short and id then
        local portrait=Portrait.render(group,id,UDim2.fromOffset(cinematic and 0 or 5,2),UDim2.fromOffset(cinematic and left-8 or 62,height-4),true,cinematic and "Hero" or "Face")
        if portrait then portrait.ZIndex=42 else glyph(group,id,color,40) end
        if cinematic and portrait and not reduced then
            local destination=portrait.Position;portrait.Position=destination+UDim2.fromOffset(-24,0)
            animate(portrait,I.PortraitIn,{Position=destination})
        end
    end
    if outcome then emblem(group,winner,color) end
    if cinematic then
        local def=Identity.byId[id]
        make("TextLabel",{Name="CastIdentity",BackgroundTransparency=1,Position=UDim2.fromOffset(left,18),Size=UDim2.new(1,-left-14,0,28),Text=Locale.isEnglish()and def.english or def.name.." / "..def.english,TextSize=18,TextColor3=C.Muted,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=42},group)
        make("Frame",{Name="CastUnderline",BackgroundColor3=color,BorderSizePixel=0,Position=UDim2.new(0,left,1,-34),Size=UDim2.new(1,-left-24,0,2),ZIndex=42},group)
    end
    local font=outcome and I.OutcomeSize or short and I.CompactSize or cinematic and 36 or I.TitleSize
    local titleLabel=make("TextLabel",{Name="ImpactTitle",BackgroundTransparency=1,Position=UDim2.fromOffset(left,short and 1 or outcome and I.OutcomeTitleTop or cinematic and 62 or 10),Size=UDim2.new(1,-left-14,0,short and height-2 or outcome and 52 or cinematic and 52 or 40),Text=title,TextSize=short and I.CompactSize or font,TextColor3=color,Font=Enum.Font.GothamBold,TextXAlignment=outcome and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=42},group)
    if Locale.isEnglish()then
        local available=width-left-14
        while titleLabel.TextSize>20 and game:GetService("TextService"):GetTextSize(titleLabel.ContentText,titleLabel.TextSize,titleLabel.Font,Vector2.new(10000,10000)).X>available do titleLabel.TextSize-=1 end
    end
    if not short then make("TextLabel",{Name="ImpactDetail",BackgroundTransparency=1,Position=UDim2.fromOffset(left,outcome and I.OutcomeDetailTop or cinematic and 130 or 49),Size=UDim2.new(1,-left-14,0,24),Text=detail,TextSize=I.MetaSize,TextColor3=C.Paper,Font=Enum.Font.GothamMedium,TextXAlignment=outcome and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=42},group)
    else local heading=root:FindFirstChild("OwnershipHeading");if heading then heading.Visible=false end end
    if not reduced then animate(group,I.In,{GroupTransparency=0});animate(scale,I.In,{Scale=1}) end
    task.delay(math.max(I.In,hold-I.Out),function()
        if serial~=ticket or not group then return end
        if reduced then Impact.reset();return end
        animate(group,I.Out,{GroupTransparency=1})
        task.delay(I.Out,function() if serial==ticket then Impact.reset() end end)
    end)
end
function Impact.present(event,hold,reduced)
    if event.kind=="Skill" and Identity.byId[event.source] then
        local def=Identity.byId[event.source];Impact.Counts.Skill=(Impact.Counts.Skill or 0)+1
        local colors={survivor=C.Cyan,anomaly=Config.TableFeedback.LinkColor,wasteland=C.Amber}
        show(def.skill.name,def.name,colors[def.faction] or C.Paper,event.source,hold+Config.Resolution.ContactLead+I.Out,reduced)
        if group then group:SetAttribute("CastSource",event.source) end
    elseif event.kind=="Death" then
        Impact.Counts.Death=(Impact.Counts.Death or 0)+1
        local hostile=event.owner=="B"
        local title=event.cause=="Execute" and "处决" or event.cause=="LinkTrigger" and "命线击破" or hostile and "击破" or "阵亡"
        local detail=Identity.name(event.target)..(hostile and " · 对手单位阵亡" or " · 己方单位阵亡")
        if hostile and (event.actionDeaths or 0)>1 then
            Impact.Counts.Chain=(Impact.Counts.Chain or 0)+1
            title=event.actionDeaths==2 and "双重击破" or event.actionDeaths==3 and "三重击破" or "连续击破"
            detail=Identity.name(event.target).." · 本次行动第 "..event.actionDeaths.." 次击破"
        end
        show(title,detail,hostile and C.Amber or C.Muted,nil,hold,reduced)
    elseif event.kind=="Damage" and event.damageType=="DeathRattle" then
        Impact.Counts.Rattle=(Impact.Counts.Rattle or 0)+1
        show("终响",Identity.name(event.source).." · 亡语触发",C.Paper,event.source,hold,reduced)
    elseif event.kind=="LinkTrigger" then
        show("命线纠缠","缚命 · 命线触发",Config.TableFeedback.LinkColor,"ye_ban",hold,reduced)
    elseif event.kind=="Damage" then
        local id=event.damageType=="Reflection" and "zhe_jing" or event.damageType=="Bleeding" and "xuan_bao"
            or event.damageType=="Normal" and event.source=="huan_shi" and "huan_shi"
            or event.damageType=="Normal" and event.target=="lan_dun" and "lan_dun"
        if id then
            local def=Identity.byId[id]
            show(def.skill.name,def.name.." · 被动触发",C.Paper,id,hold,reduced)
        end
    end
end
-- The cast illustration exits on the same contact that starts hit audio/HUD.
function Impact.contact(event,reduced)
    if not group or not group:GetAttribute("CastSource") then return end
    local ticket=serial
    if reduced then Impact.reset();return end
    animate(group,I.Out,{GroupTransparency=1})
    task.delay(I.Out,function()if serial==ticket then Impact.reset()end end)
end
function Impact.outcome(winner,round,hold,reduced)
    Impact.Counts.Outcome=(Impact.Counts.Outcome or 0)+1
    show(winner=="A" and "胜利" or winner=="B" and "失利" or "同归于尽","第 "..round.." 回合 · 行动结束",winner=="A" and C.Cyan or winner=="B" and C.Muted or C.Amber,nil,hold,reduced,true,winner)
end
return Impact
