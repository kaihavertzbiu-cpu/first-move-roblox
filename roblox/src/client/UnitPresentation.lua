-- Original vector contact marks. No downloaded textures or gameplay authority.
local Colors=require(script.Parent.PresentationConfig).Colors
local Identity=require(script.Parent.UnitIdentity)
local Locale=require(script.Parent.LocaleController)
local Portrait=require(script.Parent.UnitPortrait)
local Unit={}
local shortRoles={ting_sun="Execution",lan_dun="Defense",ye_ban="Lifeline",yan_wei="Deathrattle",bai_ji="Healing",shuang_xing="Split strike",chi_guang="Ability lock",zhe_jing="Retaliation",beng_yue="Double strike",huan_shi="Unblockable",zhui_lie="Pursuit",xuan_bao="Bleeding"}
local TweenService=game:GetService("TweenService")
local Reaction=require(script.Parent.PresentationConfig).CardReaction
local Card=require(script.Parent.PresentationConfig).BattleCard
function Unit.portrait(ui,parent,id,position,size,alive,framing) return Portrait.render(parent,id,position,size,alive,framing) end
function Unit.glyph(ui,parent,id,size,color,position)
    local f=ui.make("Frame",{Name="ContactMark",BackgroundTransparency=1,Position=position or UDim2.fromScale(.075,.15),Size=UDim2.fromOffset(size,size)},parent)
    f:SetAttribute("UnitId",id)
    for _,path in ipairs(Identity.byId[id].paths) do for i=1,#path-1 do
        local a,b=path[i],path[i+1];local dx,dy=(b[1]-a[1])*size,(b[2]-a[2])*size
        ui.make("Frame",{BorderSizePixel=0,BackgroundColor3=color,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((a[1]+b[1])*size/2,(a[2]+b[2])*size/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy)+.7,2),Rotation=math.deg(math.atan2(dy,dx))},f)
    end end
    return f
end
local function clearLabel(button)
    for _,child in ipairs(button:GetChildren()) do if child:IsA("TextLabel") or child:IsA("UIPadding") then child:Destroy() end end
end
function Unit.roster(ui,button,h,def,owner,marker,picked)
    clearLabel(button)
    button:SetAttribute("ControlId","Hero:"..owner..":"..h.id)
    button.Selectable=h.alive
    button:SetAttribute("Disabled",not h.alive)
    local color=owner=="A" and Colors.Cyan or Colors.Amber
    local order=marker=="①② " and "×2" or (marker or ""):gsub("%s","")
    -- Battle contacts have their own frame; menu rails never divide the portraits.
    for _,name in ipairs({"CommandRail","UpperBevel"})do local o=button:FindFirstChild(name);if o then o.Visible=false end end
    local surface=picked and Card.SelectedSurface or Card.Surface
    button.BackgroundColor3=surface;button.BackgroundTransparency=0
    button:SetAttribute("RestColor",surface);button:SetAttribute("HoverColor",Card.HoverSurface)
    button:SetAttribute("Selected",picked);button:SetAttribute("BattleCard",true)
    local edge=button:FindFirstChild("ButtonEdge")
    if edge then edge.Color=picked and Card.Highlight or Card.Edge;edge.Thickness=1;edge.Transparency=picked and .08 or .57 end
    local material=button:FindFirstChild("MachinedSurface")
    if material then material.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromRGB(183,185,189)) end
    local function metal(name,position,size,tint,alpha)
        return ui.make("Frame",{Name=name,BorderSizePixel=0,BackgroundColor3=tint,BackgroundTransparency=alpha or 0,
            Position=position,Size=size,ZIndex=4},button)
    end
    metal("FrameHighlight",UDim2.fromOffset(1,1),UDim2.new(1,-2,0,1),Card.Highlight,.72)
    metal("FrameShadow",UDim2.new(0,1,1,-1),UDim2.new(1,-2,0,1),Color3.new(0,0,0),.12)
    local inset=Card.Inset
    local portrait=button.AbsoluteSize.Y>=Card.CompactHeight and button.AbsoluteSize.X>=86
    if portrait then
        local art=Portrait.render(button,h.id,UDim2.fromOffset(inset,inset),UDim2.new(1,-inset*2,1,-Card.FooterHeight-inset),h.alive)
        art.ZIndex=2
        local shade=ui.make("Frame",{Name="PortraitVignette",BorderSizePixel=0,BackgroundColor3=Card.Surface,
            Position=UDim2.new(0,inset,1,-Card.FooterHeight-16),Size=UDim2.new(1,-inset*2,0,16),ZIndex=3},button)
        ui.make("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,.05)})},shade)
    end
    local title=ui.text(button,def.name,0,0,1,0,15,h.alive and Colors.Paper or Colors.Muted,Enum.Font.GothamBold)
    title.Name="UnitName";title.ZIndex=5;title.TextWrapped=false
    title.Position=portrait and UDim2.new(0,7,1,-Card.FooterHeight+2) or UDim2.fromOffset(7,3)
    title.Size=UDim2.new(1,-14,0,24)
    button:SetAttribute("TargetOrder",order~="" and order or nil)
    if order~="" then
        local t=ui.text(button,order,0,0,0,0,12,color);t.Name="TargetOrder"
        t.Position=UDim2.new(1,-24,0,5);t.Size=UDim2.fromOffset(19,20);t.TextWrapped=false;t.ZIndex=6
        t.TextXAlignment=Enum.TextXAlignment.Center;t.BackgroundColor3=Card.Surface;t.BackgroundTransparency=.08
        ui.make("UIStroke",{Color=color,Thickness=1,Transparency=.3},t)
    end
    local health=ui.text(button,h.alive and h.hp.."/"..h.maxHp or Locale.isEnglish()and"KO"or"阵亡",0,0,1,0,13,h.alive and Colors.Paper or Colors.Muted)
    health.Name="HealthValue";button:SetAttribute("MaxHp",h.maxHp)
    health.Position=UDim2.new(.40,0,1,-26);health.Size=UDim2.new(.60,-7,0,20);health.TextWrapped=false
    health.TextXAlignment=Enum.TextXAlignment.Right;health.ZIndex=5
    local attack=ui.text(button,"ATK "..h.atk,0,0,1,0,10,h.alive and Colors.Muted or Card.Edge)
    attack.Position=UDim2.new(0,7,1,-26);attack.Size=UDim2.new(.45,-7,0,20);attack.Name="AttackValue";attack.TextWrapped=false;attack.ZIndex=5
    local track=ui.make("Frame",{Name="HealthTrack",BorderSizePixel=0,BackgroundColor3=Card.Track,
        Position=UDim2.new(0,7,1,-5),Size=UDim2.new(1,-14,0,2),ZIndex=5},button)
    ui.make("Frame",{Name="HealthFill",BorderSizePixel=0,BackgroundColor3=h.hp/h.maxHp<=.3 and Card.LowHealth or Card.Health,Size=UDim2.fromScale(h.hp/h.maxHp,1),ZIndex=5},track)
    local accent=picked and Card.Highlight or color
    metal("ContactCorner",UDim2.fromOffset(1,1),UDim2.fromOffset(picked and 21 or 9,2),accent,picked and 0 or .35)
    if picked then metal("SelectedCorner",UDim2.new(1,-17,1,-2),UDim2.fromOffset(16,2),Card.Highlight,0) end
end
function Unit.react(button,event,hold,reduced)
    local old=button:FindFirstChild("CardReaction");if old then old:Destroy() end
    local health=button:FindFirstChild("HealthValue")
    if health and event.presentedHp~=nil then
        health.Text=event.presentedAlive==false and (Locale.isEnglish()and"KO"or"阵亡") or event.presentedHp.."/"..button:GetAttribute("MaxHp")
    end
    local track=button:FindFirstChild("HealthTrack");local fill=track and track:FindFirstChild("HealthFill")
    local layer=Instance.new("Frame");layer.Name="CardReaction";layer.BackgroundTransparency=1;layer.Size=UDim2.fromScale(1,1)
    layer.ZIndex=15;layer.Active=false;layer.Parent=button
    local tweens={}
    local function animate(object,time,goal)
        local t=TweenService:Create(object,TweenInfo.new(time,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),goal)
        table.insert(tweens,t);t:Play()
    end
    local portrait=button:FindFirstChild("UnitPortrait")
    local position=portrait and portrait.Position
    local dead=event.kind=="Death"
    layer.Destroying:Connect(function()
        for _,t in ipairs(tweens)do t:Cancel()end
        if portrait and portrait.Parent then
            portrait.Position=position;portrait.Visible=true
            local art=portrait:FindFirstChild("Artwork")
            if art then art.ImageColor3=dead and Colors.Muted or Color3.new(1,1,1);art.ImageTransparency=dead and .55 or 0 end
        end
    end)
    if fill and event.presentedHp~=nil then
        fill.BackgroundColor3=event.presentedHp/math.max(1,button:GetAttribute("MaxHp"))<=.3 and Card.LowHealth or Card.Health
        local goal=UDim2.fromScale(event.presentedHp/math.max(1,button:GetAttribute("MaxHp")),1)
        if reduced then fill.Size=goal else animate(fill,Reaction.HealthTime,{Size=goal}) end
    end
    if dead then
        button:SetAttribute("Disabled",true);button.Selectable=false
        if portrait and not reduced then
            -- Six clipped pieces retain the authored face crop; no placeholder symbol.
            for row=0,1 do for col=0,2 do
                local piece=Instance.new("Frame");piece.Name="PortraitShard";piece.ClipsDescendants=true
                piece.BackgroundTransparency=1;piece.Size=UDim2.fromOffset(portrait.AbsoluteSize.X/3,portrait.AbsoluteSize.Y/2)
                local origin=portrait.AbsolutePosition-button.AbsolutePosition
                piece.Position=UDim2.fromOffset(origin.X+col*piece.Size.X.Offset,origin.Y+row*piece.Size.Y.Offset)
                piece.ZIndex=16;piece.Parent=layer
                local image=portrait:Clone();image.Name="ShardArtwork";image.Visible=true;image.Position=UDim2.fromScale(-col,-row)
                image.Size=UDim2.fromScale(3,2);image.ZIndex=16;image.Parent=piece
                for _,child in ipairs(image:GetDescendants())do if child:IsA("GuiObject")then child.ZIndex=16 end end
                local art=image:FindFirstChild("Artwork")
                if art then art.ImageColor3=Color3.new(1,1,1);art.ImageTransparency=0;animate(art,hold,{ImageTransparency=1}) end
                animate(piece,hold,{Position=piece.Position+UDim2.fromOffset((col-1)*Reaction.ShardTravel,(row==0 and -1 or 1)*Reaction.ShardTravel),Rotation=(col-1)*Reaction.ShardAngle})
            end end
            portrait.Visible=false
        end
    elseif event.kind=="Damage" and portrait and not reduced then
        local tier=event.impactTier or 1
        local art=portrait:FindFirstChild("Artwork")
        if art then art.ImageColor3=Reaction.ContactTint;animate(art,Reaction.Recover,{ImageColor3=Color3.new(1,1,1)}) end
        portrait.Position=position+UDim2.fromOffset(Reaction.Recoil[tier],0)
        animate(portrait,math.min(hold,Reaction.Recover),{Position=position})
    end
    task.delay(math.max(hold,Reaction.HealthTime),function()if layer.Parent then layer:Destroy()end end)
end
function Unit.draft(ui,button,def,taken,picked)
    clearLabel(button)
    button:SetAttribute("ControlId","Draft:"..def.id)
    button.Selectable=not taken
    button:SetAttribute("Disabled",taken and true or false)
    local brief=button.AbsoluteSize.Y<62
    local compact=button.AbsoluteSize.X<120 or brief
    local x=compact and .08 or .29
    local portrait=button.AbsoluteSize.X>=126 and button.AbsoluteSize.Y>=44
    if portrait then
        x=brief and .31 or .38
        Portrait.render(button,def.id,UDim2.new(.01,0,0,2),UDim2.new(brief and .28 or .36,0,0,button.AbsoluteSize.Y-4),not taken)
    elseif not compact then Unit.glyph(ui,button,def.id,30,taken and Colors.Muted or Colors.Cyan) end
    local title=ui.text(button,def.name,x,0,1-x-.04,0,17,taken and Colors.Muted or Colors.Paper,Enum.Font.GothamMedium)
    title.Position=UDim2.new(x,0,0,2);title.Size=UDim2.new(1-x-.04,0,0,24);title.TextWrapped=false
    if not brief then local role=ui.text(button,Locale.isEnglish()and shortRoles[def.id]or def.role,x,0,1-x-.04,0,12,Colors.Muted);role.Position=UDim2.new(x,0,0,28);role.Size=UDim2.new(1-x-.04,0,0,20) end
    local detail=taken and (taken=="A" and "己方已选" or "对手已选") or brief and def.role or portrait and def.atk.."攻 "..def.maxHp.."血" or def.atk.." ATK · "..def.maxHp.." HP"
    if Locale.isEnglish()and not taken then detail=def.atk.." ATK · "..def.maxHp.." HP"end
    local sub=ui.text(button,detail,x,0,1-x-.04,0,13,Colors.Muted)
    sub.Position=UDim2.new(x,0,1,-24);sub.Size=UDim2.new(1-x-.04,0,0,22);sub.TextWrapped=false
    if picked then ui.make("UIStroke",{Color=Colors.Cyan,Thickness=1},button) end
end
return Unit
