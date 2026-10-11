local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Config = require(script.Parent.PresentationConfig)
local Locale = require(script.Parent.LocaleController)
local Camera = require(script.Parent.CameraController)
local Audio = require(script.Parent.AudioController)
local Music = require(script.Parent.MusicController)
local Table = require(script.Parent.TableController)
local Battle = require(script.Parent.BattleController)
local Tutorial = require(script.Parent.TutorialController)
local Legacy = require(script.Parent.UnitIdentity)
local Unit = require(script.Parent.UnitPresentation)
local Profile=require(script.Parent.ProfileController)
local Report=require(script.Parent.ReportController)
local Preferences=require(script.Parent.PreferencesView)
local SessionMenu=require(script.Parent.SessionMenu)
local Responsive=require(script.Parent.ResponsiveLayout)
local Product = require(game:GetService("ReplicatedStorage").DeadlockShared.ProductConfig)
local C = Config.Colors
local Progression=require(game:GetService("ReplicatedStorage").DeadlockShared.ProgressionConfig)
local RankAssets=require(script.Parent.RankAssets)
local Hub=require(script.Parent.HubView)
local hubNotice=""
local hubBusy=false
local hubScrolls={}
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
task.spawn(function()
    for attempt=1,4 do
        pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All,false);StarterGui:SetCore("TopbarEnabled",false) end)
        local chat=game:GetService("TextChatService")
        for _,name in ipairs({"ChatWindowConfiguration","ChatInputBarConfiguration","BubbleChatConfiguration"}) do local configuration=chat:FindFirstChild(name);if configuration then configuration.Enabled=false end end
        task.wait(.2)
    end
end)
local gui = Instance.new("ScreenGui")
gui.Name = "DeadlockUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local root = Instance.new("Frame")
root.Name = "Router"
root.BackgroundTransparency = 1
root.Size = UDim2.fromScale(1,1)
root.Parent = gui
local screen = "Boot"
local uiScale = 1
local route
local difficulty="Standard"
local matchMode="AI"
local featuredIndex=1
local featuredIds={"ting_sun","lan_dun","ye_ban","yan_wei","bai_ji","shuang_xing","chi_guang","zhe_jing","beng_yue","huan_shi","zhui_lie","xuan_bao"}
local historyView
local function savePreferences()
    Profile.save({master=Audio.Master,sfx=Audio.SFX,music=Music.Level,reduced=Camera.Reduced,large=uiScale>1,guide=Tutorial.Enabled,language=Locale.Preference})
end
local Kit=require(script.Parent.InterfaceKit)
local make,text,line,panel,button=Kit.make,Kit.text,Kit.line,Kit.panel,Kit.button
local function bottomButton(parent,label,fn,primary)
    local b=button(parent,label,0.07,0,0.86,0,fn,primary)
    b.AnchorPoint=Vector2.new(0,1)
    b.Position=UDim2.new(0.07,0,1,-12)
    b.Size=UDim2.new(0.86,0,0,44)
    return b
end
local function header(parent,kicker,title)
    text(parent,kicker,0.07,0.025,0.87,0.07,11,C.Cyan,Enum.Font.GothamMedium)
    text(parent,title,0.07,0.105,0.88,0.16,32,C.Paper,Enum.Font.GothamBold)
    line(parent,0.07,0.30,0.86)
end
local function chrome()
    if screen=="Menu" or screen=="Shop" or screen=="Inventory" or screen=="Career" or screen=="Friends" then return end
    text(root,"AXIOM  /  STRATEGIC CONTROL",0.035,0.015,0.6,0.04,11,C.Muted,Enum.Font.GothamMedium)
    text(root,"LOCAL COMMAND  •  01",0.75,0.015,0.22,0.04,11,C.Muted)
    line(root,0.035,0.068,0.93)
    line(root,0.035,0.937,0.93)
    text(root,Product.Name.."   /   "..Product.EnglishName,0.035,0.95,0.52,0.035,11,C.Muted)
    text(root,Config.Build,0.73,0.95,0.24,0.035,10,C.Muted)
end
local function economy()return Profile.Value and Profile.Value.economy or {credits=0,xp=0,rating=0,owned={},equipped="default"}end
local hubSelected="signal_cyan"
local function badge(parent,x,y,size,tier,color,symbol)
    local f=make("Frame",{Name="RankInsignia",BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size)},parent)
    local function stroke(ax,ay,bx,by,tint,width)
        local dx,dy=(bx-ax)*size,(by-ay)*size
        make("Frame",{BorderSizePixel=0,BackgroundColor3=tint,AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromOffset((ax+bx)*size/2,(ay+by)*size/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),width or 2),
            Rotation=math.deg(math.atan2(dy,dx))},f)
    end
    local plate=make("Frame",{Name="MetalFace",BorderSizePixel=0,BackgroundColor3=C.Panel,AnchorPoint=Vector2.new(.5,.5),
        Position=UDim2.fromScale(.5,.47),Size=UDim2.fromScale(.48,.48),Rotation=45},f)
    make("UIStroke",{Color=color,Thickness=2,Transparency=.15},plate)
    make("UIGradient",{Rotation=90,Color=ColorSequence.new(Color3.fromRGB(80,94,100),C.Ink)},plate)
    if symbol then
        plate.Size=UDim2.fromScale(.56,.56)
        if symbol=="signal_cyan" then
            -- Broken orbit: the Crescent's signal remains open at the east.
            for i=0,9 do
                local a=math.rad(55+i*25);local b=a+math.rad(22)
                stroke(.5+math.cos(a)*.23,.47+math.sin(a)*.23,.5+math.cos(b)*.23,.47+math.sin(b)*.23,color,3)
            end
            stroke(.50,.28,.67,.47,C.Paper,3);stroke(.67,.47,.50,.66,C.Paper,3)
        elseif symbol=="signal_amber" then
            stroke(.36,.29,.36,.63,C.Paper,3);stroke(.64,.29,.64,.63,C.Paper,3)
            stroke(.28,.39,.72,.39,color,3);stroke(.28,.55,.72,.55,color,3)
            stroke(.50,.23,.50,.71,color,2)
        elseif symbol=="signal_violet" then
            stroke(.28,.58,.44,.32,C.Paper,3);stroke(.44,.32,.51,.60,color,3)
            stroke(.51,.60,.61,.39,C.Paper,3);stroke(.61,.39,.74,.58,color,3)
            stroke(.27,.68,.43,.68,color,2);stroke(.59,.68,.74,.68,color,2)
        elseif symbol=="achievement" then
            if tier==1 then
                stroke(.5,.23,.72,.47,color,2);stroke(.72,.47,.5,.71,color,2)
                stroke(.5,.71,.28,.47,color,2);stroke(.28,.47,.5,.23,color,2)
                stroke(.36,.47,.64,.47,C.Paper,2);stroke(.5,.33,.5,.61,C.Paper,2)
            elseif tier==2 then
                stroke(.29,.30,.5,.47,C.Paper,2);stroke(.5,.47,.71,.30,C.Paper,2)
                stroke(.29,.48,.5,.65,color,2);stroke(.5,.65,.71,.48,color,2)
                stroke(.30,.73,.70,.73,color,2)
            else
                stroke(.23,.47,.5,.29,color,2);stroke(.5,.29,.77,.47,color,2)
                stroke(.77,.47,.5,.65,color,2);stroke(.5,.65,.23,.47,color,2)
                stroke(.5,.37,.59,.47,C.Paper,2);stroke(.59,.47,.5,.57,C.Paper,2)
                stroke(.5,.57,.41,.47,C.Paper,2);stroke(.41,.47,.5,.37,C.Paper,2)
            end
        else
            stroke(.5,.28,.5,.66,C.Paper,3);stroke(.35,.47,.65,.47,color,3)
        end
        return f
    end
    stroke(.5,.19,.5,.70,color,3);stroke(.34,.43,.5,.28,C.Paper,2);stroke(.5,.28,.66,.43,C.Paper,2)
    for i=1,math.min(4,tier)do
        local yy=.43+i*.075
        stroke(.13,yy-.11,.30,yy,color,2);stroke(.70,yy,.87,yy-.11,color,2)
        stroke(.13,yy-.11,.13,yy-.04,C.Muted,2);stroke(.87,yy-.11,.87,yy-.04,C.Muted,2)
    end
    if tier>=3 then
        stroke(.29,.23,.35,.14,color,2);stroke(.35,.14,.43,.23,color,2)
        stroke(.57,.23,.65,.14,color,2);stroke(.65,.14,.71,.23,color,2)
    end
    if tier>=5 then
        stroke(.43,.23,.5,.08,C.Paper,3);stroke(.5,.08,.57,.23,C.Paper,3)
    end
    for i=1,tier do
        local pip=make("Frame",{BackgroundColor3=color,BorderSizePixel=0,Rotation=45,Size=UDim2.fromOffset(4,4),
            Position=UDim2.new(.5,(i-(tier+1)/2)*10,.88,0)},f)
    end
    if RankAssets[tier] then
        local fallback=make("Frame",{Name="VectorFallback",BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},f)
        for _,child in ipairs(f:GetChildren())do if child~=fallback then child.Parent=fallback end end
        local art=make("ImageLabel",{Name="RankArtwork",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
            Image=RankAssets[tier],ScaleType=Enum.ScaleType.Fit,Visible=true},f)
        local connection
        local function ready()
            if art.Parent and (art.IsLoaded or game:GetService("ContentProvider"):GetAssetFetchStatus(art.Image)==Enum.AssetFetchStatus.Success) then
                art.Visible=true;fallback.Visible=false;f:SetAttribute("ArtworkLoaded",true)
                if connection then connection:Disconnect();connection=nil end
            end
        end
        connection=art:GetPropertyChangedSignal("IsLoaded"):Connect(ready)
        f.Destroying:Connect(function()if connection then connection:Disconnect();connection=nil end end)
        task.spawn(function()
            pcall(function()game:GetService("ContentProvider"):PreloadAsync({art})end)
            ready()
        end)
        ready()
    end
    return f
end
local function hub(kind)
    local function transact(command,id)
        if hubBusy then return end
        hubBusy=true;hubNotice="正在同步…";route(kind)
        Profile.action(command,id,function(message)
            hubBusy=false
            hubNotice=message=="已更新" and (command=="Equip" and "印记已装备" or "已加入收藏") or message
            if screen==kind then route(kind)end
        end)
    end
    Hub.render({root=root,colors=C,progression=Progression,economy=economy,
        stats=function()return Profile.Value and Profile.Value.stats or {}end,
        badge=badge,players=Players,selected=function()return hubSelected end,
        scroll=function()return hubScrolls[kind]or 0 end,
        busy=function()return hubBusy end,notice=function()return hubNotice end,
        navigate=function(nextKind)hubNotice="";route(nextKind,true)end,
        select=function(id,nextKind)hubSelected=id;route(nextKind,true)end,
        transact=transact,back=function()hubNotice="";route("Menu")end,
        startPVP=function()matchMode="PvP";route("Setup")end,
        invite=function()task.spawn(function()
            local social=game:GetService("SocialService")
            local ok,allowed=pcall(function()return social:CanSendGameInviteAsync(Players.LocalPlayer)end)
            if ok and allowed then local sent=pcall(function()social:PromptGameInvite(Players.LocalPlayer)end);hubNotice=sent and "邀请窗口已打开"or"邀请暂不可用"
            else hubNotice="邀请暂不可用"end
            if screen=="Friends"then route("Friends")end
        end)end},kind)
end
local function menu()
    local width,height=root.AbsoluteSize.X,root.AbsoluteSize.Y
    local portrait=width<540
    local short=height<380
    local compact=height<540
    local displayLarge=not compact and not portrait and width>=900
    local leftWidth=portrait and .57 or compact and .38 or .31
    local left=panel(root,.035,.10,leftWidth,.82,.035);left.Name="CommandMenu"
    left.BackgroundTransparency=1;left.SurfaceEdge.Transparency=1;left.MachinedCorner.Visible=false;left.LowerSeam.Visible=false;left.GraphiteSurface.Enabled=false
    local title=text(left,Product.Name,.075,0,.67,0,Locale.isEnglish()and(short and 22 or portrait and 28 or compact and 30 or 42)or(short and 32 or portrait and 48 or width<900 and 44 or compact and 44 or 64),C.Paper,Enum.Font.GothamBold)
    title.Position=UDim2.new(.075,0,0,short and 5 or 12);title.Size=UDim2.new(.67,0,0,short and 40 or displayLarge and 84 or 62)
    if not short then
        local brand=text(left,Locale.isEnglish()and"TACTICAL DUEL"or Product.EnglishName,.08,0,.84,0,15,C.Cyan,Enum.Font.GothamMedium)
        brand.Position=UDim2.new(.08,0,0,displayLarge and 108 or 76);brand.Size=UDim2.new(.84,0,0,24)
    end
    local gear=button(left,"设置",0,0,0,0,function()route("Settings")end)
    gear:SetAttribute("ControlId","Settings");gear.Position=UDim2.new(1,-56,0,short and 4 or 16);gear.Size=UDim2.fromOffset(44,44)
    gear.BackgroundTransparency=1;gear.ButtonEdge.Transparency=.85
    gear.UIPadding.PaddingLeft=UDim.new(0,0);gear.UIPadding.PaddingRight=UDim.new(0,0)
    for _,child in ipairs(gear:GetChildren())do if child:IsA("TextLabel")then child:Destroy()end end
    local gearRing=make("Frame",{Name="GearRing",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(18,18)},gear)
    make("UICorner",{CornerRadius=UDim.new(1,0)},gearRing);make("UIStroke",{Color=C.Muted,Thickness=1.5},gearRing)
    for i=0,7 do local angle=math.rad(i*45)
        make("Frame",{BorderSizePixel=0,BackgroundColor3=C.Muted,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,math.cos(angle)*11,.5,math.sin(angle)*11),Size=UDim2.fromOffset(4,4),Rotation=i*45},gear)
    end
    local core=make("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(6,6)},gear)
    make("UICorner",{CornerRadius=UDim.new(1,0)},core);make("UIStroke",{Color=C.Muted,Thickness=1.5},core)
    local buttonHeight=compact and 44 or 50
    local gap=short and 4 or compact and 8 or 12
    local navTop=short and 52 or math.min(displayLarge and 148 or 114,height*.82-buttonHeight*4-gap*3-8)
    local nav=make("Frame",{Name="CommandNavigation",BackgroundTransparency=1,
        Position=UDim2.fromOffset(0,navTop),Size=UDim2.new(1,0,0,buttonHeight*4+gap*3)},left)
    local trained=Profile.Value and Profile.Value.tutorialComplete
    local entries=trained and {{"开始对局","Setup"},{"攻防训练","Training"},{"行动档案","Record"},{"战术档案","Archive"}}or
        {{"开始训练","Training"},{"开始对局","Setup"},{"行动档案","Record"},{"战术档案","Archive"}}
    for i,row in ipairs(entries)do
        local b=button(nav,row[1],.08,0,.84,0,function()route(row[2])end)
        b.Position=UDim2.new(.08,0,0,(i-1)*(buttonHeight+gap));b.Size=UDim2.new(.84,0,0,buttonHeight)
        b:SetAttribute("ControlId",row[2]=="Training"and "StartTraining"or row[2]=="Setup"and "StartMatch"or row[2])
        b.BackgroundColor3=i<=2 and Color3.fromRGB(21,43,55)or C.Ink;b:SetAttribute("RestColor",b.BackgroundColor3)
        b.BackgroundTransparency=i<=2 and .18 or .65
        b.ButtonEdge.Color=i==1 and C.Cyan or Color3.fromRGB(83,117,131);b.ButtonEdge.Transparency=i==1 and .45 or 1; b.UpperBevel.Visible=false
        b.MachinedSurface.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(199,220,228)),ColorSequenceKeypoint.new(.20,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(132,159,172))})
        b.CommandRail.BackgroundColor3=i==1 and C.Cyan or C.Muted
        local caption=b:FindFirstChild("ButtonCaption")
        if caption then caption.TextSize=i<=2 and 22 or 19;caption.Font=Enum.Font.GothamBold;caption.TextColor3=C.Paper end
    end
    local e=economy()
    local identity=Progression.ById[e.equipped]
    local identityColor=identity and Color3.fromRGB(table.unpack(identity.color))or C.Paper
    local profile=text(root,Players.LocalPlayer.DisplayName.."  ·  Lv."..Progression.level(e.xp).."  "..Progression.rank(e.rating),
        .035,.015,.59,.055,15,identityColor,Enum.Font.GothamMedium)
    profile.TextWrapped=false;profile.TextTruncate=Enum.TextTruncate.AtEnd
    profile:SetAttribute("ProtectedText",Players.LocalPlayer.DisplayName)
    profile.Size=UDim2.new(.59,0,0,24)
    local currency=text(root,"核晶  "..e.credits,.67,.015,.295,.055,16,C.Cyan,Enum.Font.GothamBold)
    currency.TextXAlignment=Enum.TextXAlignment.Right
    currency.Size=UDim2.new(.295,0,0,24)
    local sideX=portrait and .64 or .625
    local sideWidth=portrait and .325 or .34
    local footerHeight=44
    local footerTop=math.min(height*.82,height*.92-footerHeight)
    local heroHeight=portrait and height*.48 or math.min(height*.70,footerTop-height*.10-12)
    local hero=panel(root,sideX,.10,sideWidth,0,1);hero.Name="FeaturedUnit";hero.Size=UDim2.new(sideWidth,0,0,heroHeight);hero.BackgroundTransparency=1
    local featured=Legacy.byId[featuredIds[featuredIndex]]
    local captionHeight=portrait and 86 or 82
    Unit.portrait({make=make},hero,featured.id,UDim2.fromOffset(0,0),UDim2.new(1,0,1,-captionHeight-6),true,portrait and "Face"or "Hero")
    local caption=make("Frame",{Name="FeaturedCaption",BackgroundColor3=C.Ink,BackgroundTransparency=.08,BorderSizePixel=0,
        Position=UDim2.new(0,0,1,-captionHeight),Size=UDim2.new(1,0,0,captionHeight)},hero)
    local name=text(caption,featured.name,0,0,0,0,portrait and 20 or 24,C.Paper,Enum.Font.GothamBold)
    name.Position=UDim2.fromOffset(8,0);name.Size=UDim2.new(1,portrait and -16 or -108,0,32)
    local stats=text(caption,"攻击 "..featured.atk.." · 生命 "..featured.maxHp,0,0,0,0,14,C.Muted)
    stats.Position=UDim2.fromOffset(8,38);stats.Size=UDim2.new(1,-108,0,28);stats.Visible=not portrait and sideWidth*width>=255
    local detail=button(caption,"详情",0,0,0,0,function()route("Character")end)
    detail:SetAttribute("ControlId","CharacterDetails")
    detail.Position=portrait and UDim2.new(.06,0,1,-48)or UDim2.new(1,-96,.5,-22)
    detail.Size=portrait and UDim2.new(.88,0,0,44)or UDim2.fromOffset(88,44)
    detail.BackgroundTransparency=.05
    line(caption,0,0,1,C.Cyan)
    local shortcuts={{"商店","Shop"},{"背包","Inventory"},{"生涯","Career"},{"好友","Friends"}}
    for i,row in ipairs(shortcuts)do
        local x=portrait and sideX or .425+(i-1)*.135
        local y=portrait and height*(.60+(i-1)*.076)or footerTop
        local b=button(root,row[1],x,0,portrait and sideWidth or .125,0,function()hubNotice="";route(row[2])end)
        b.Position=UDim2.new(x,0,0,y);b.Size=UDim2.new(portrait and sideWidth or .125,0,0,44)
        b.BackgroundTransparency=.45;b.UpperBevel.Visible=false;b.CommandRail.Visible=false;b.ButtonEdge.Transparency=.85
        b:SetAttribute("HideArrow",true)
        if not portrait then Kit.icon(b,row[2],-5,10,24,C.Muted);b:SetAttribute("CaptionInset",28)end
        local label=b:FindFirstChild("ButtonCaption");if label then label.Font=Enum.Font.GothamBold;label.TextSize=18 end
    end
end

local function character()
    local def=Legacy.byId[featuredIds[featuredIndex]]
    local narrow=root.AbsoluteSize.X<640
    local T=Config.DossierTypography
    local p=panel(root,.035,.10,.93,.80,.03);p.Name="CharacterDossier"
    local art=Unit.portrait({make=make},p,def.id,UDim2.fromOffset(0,0),UDim2.new(narrow and .30 or .40,0,1,-64),true,narrow and "Hero"or "Full")
    local x=narrow and .34 or .44
    local body=make("ScrollingFrame",{Name="CharacterDetails",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(x,0,0,14),Size=UDim2.new(1-x-.035,0,1,-82),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.Cyan},p)
    make("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},body)
    local n=0
    local function row(name,value,size,color,weight,leading,code)
        n+=1
        local t=text(body,value,0,0,1,0,size,color)
        t.Name=name;t:SetAttribute("NaturalGlyphs",true);t.Text=value;t.RichText=false
        t.FontFace=Font.new(code and T.CodeFamily or T.Family,weight or Enum.FontWeight.Regular)
        t.LineHeight=leading or 1;t.LayoutOrder=n
        t.Size=UDim2.new(1,-12,0,0);t.AutomaticSize=Enum.AutomaticSize.Y;t.TextYAlignment=Enum.TextYAlignment.Top
        make("UIPadding",{PaddingBottom=UDim.new(0,4)},t)
        return t
    end
    local function divider()
        n+=1
        make("Frame",{Name="DossierRule",LayoutOrder=n,BorderSizePixel=0,BackgroundColor3=C.Line,BackgroundTransparency=.25,Size=UDim2.new(1,-12,0,1)},body)
    end
    n+=1
    local identity=make("Frame",{Name="DossierIdentity",LayoutOrder=n,BackgroundTransparency=1,Size=UDim2.new(1,-12,0,60)},body)
    local name=row("CharacterName",def.name,T.Title,C.Paper,Enum.FontWeight.Bold)
    name.Parent=identity;name.AutomaticSize=Enum.AutomaticSize.None;name.Position=UDim2.fromOffset(0,0);name.Size=UDim2.fromOffset(106,60)
    if Locale.isEnglish()then name.Text=def.english;name.Size=UDim2.new(1,0,0,60)end
    local code=row("CharacterCodename",def.english,T.Code,C.Muted,Enum.FontWeight.Bold,1,true)
    code.Parent=identity;code.AutomaticSize=Enum.AutomaticSize.None;code.Position=UDim2.fromOffset(120,25);code.Size=UDim2.new(1,-120,0,32)
    code.Visible=not Locale.isEnglish()
    row("CombatAttributes","攻击  "..def.atk.."     生命  "..def.maxHp,24,C.Cyan,Enum.FontWeight.SemiBold)
    row("CombatRole",def.role,19,T.StoryColor,Enum.FontWeight.SemiBold)
    divider()
    local skill=def.skill
    row("SkillName",skill.name,T.Heading,C.Paper,Enum.FontWeight.Bold)
    row("SkillTiming",skill.isPassive and "被动"or skill.isGameLimited and "每局一次"or skill.cooldown>0 and "冷却 "..skill.cooldown.." 回合"or"特殊触发",18,C.Amber,Enum.FontWeight.SemiBold)
    row("SkillDescription",skill.description,T.Body,T.BodyColor,Enum.FontWeight.Regular,T.LineHeight)
    divider()
    row("BiographyHeading","人物档案",T.Heading,C.Paper,Enum.FontWeight.Bold)
    row("Faction",Legacy.factions[def.faction]or"未知",18,C.Cyan,Enum.FontWeight.SemiBold)
    row("Biography",def.story,T.Story,T.StoryColor,Enum.FontWeight.Regular,T.LineHeight)
    divider()
    row("WorldHeading","世界背景",T.Heading,C.Paper,Enum.FontWeight.Bold)
    row("WorldBackground",Legacy.world,T.Story,T.StoryColor,Enum.FontWeight.Regular,T.LineHeight)
    local previous=button(p,"上一位",.035,0,.28,0,function()featuredIndex=(featuredIndex-2)%#featuredIds+1;route("Character")end)
    local next=button(p,"下一位",.345,0,.28,0,function()featuredIndex=featuredIndex%#featuredIds+1;route("Character")end)
    local back=button(p,"返回",.655,0,.31,0,function()route("Menu")end)
    for _,b in ipairs({previous,next,back})do
        b.Position=UDim2.new(b.Position.X.Scale,0,1,-56);b.Size=UDim2.new(b.Size.X.Scale,0,0,44)
        b.BackgroundColor3=C.Panel;b:SetAttribute("RestColor",C.Panel);b.BackgroundTransparency=.2
        b.UpperBevel.Visible=false;b.CommandRail.Visible=false;b.ButtonEdge.Transparency=.8
        b.ButtonCaption.FontFace=Font.new(T.Family,Enum.FontWeight.SemiBold);b.ButtonCaption.TextColor3=C.Paper
    end
end
local function setup()
    local narrow=root.AbsoluteSize.X<620
    local short=root.AbsoluteSize.Y<450
    local p=panel(root,.035,.10,.93,.80);p.Name="MatchSetup"
    local width=root.AbsoluteSize.X*.93
    local height=root.AbsoluteSize.Y*.80
    local inset=narrow and 16 or 24
    local contentWidth=narrow and width-inset*2 or width*.59-inset
    local function label(value,x,y,w,h,size,color,font)
        local t=text(p,value,0,0,0,0,size,color,font)
        t.Position=UDim2.fromOffset(x,y);t.Size=UDim2.fromOffset(w,h)
        return t
    end
    label("选择对局",inset,short and 8 or 16,contentWidth,short and 36 or 50,short and 25 or 34,C.Paper,Enum.Font.GothamBold)
    local top=short and 54 or 88
    local gap=12
    local cardHeight=short and (narrow and 54 or 66) or 100
    local sideBySide=short and not narrow
    local cardWidth=sideBySide and (contentWidth-gap)/2 or contentWidth
    local function modeCard(mode,title,detail,index)
        local selected=matchMode==mode
        local x=inset+(sideBySide and (index-1)*(cardWidth+gap) or 0)
        local y=top+(sideBySide and 0 or (index-1)*(cardHeight+gap))
        local b=button(p,title,0,0,0,0,function() matchMode=mode;route("Setup") end,selected)
        b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(cardWidth,cardHeight)
        b:SetAttribute("ControlId",mode=="PvP" and "MatchMode" or "AIMode")
        b:SetAttribute("Mode",mode);b:SetAttribute("Selected",selected)
        for _,child in ipairs(b:GetChildren())do if child:IsA("TextLabel")then child:Destroy()end end
        local titleLabel=text(b,title,0,0,1,0,short and 19 or 24,selected and C.Ink or C.Paper,Enum.Font.GothamBold)
        titleLabel.Position=UDim2.fromOffset(0,short and 2 or 7);titleLabel.Size=UDim2.new(1,-24,0,32)
        local detailLabel=text(b,detail,0,0,1,0,14,selected and C.Ink or C.Muted)
        detailLabel.Position=UDim2.fromOffset(0,short and 34 or 45);detailLabel.Size=UDim2.new(1,-8,0,short and 26 or 36)
        detailLabel.TextYAlignment=Enum.TextYAlignment.Top
        detailLabel.Visible=not (short and narrow)
        local state=text(b,selected and "✓" or "",0,0,0,0,18,selected and C.Ink or C.Cyan)
        state.Position=UDim2.new(1,-23,0,7);state.Size=UDim2.fromOffset(23,28)
        return b
    end
    modeCard("PvP","双人对峙",short and "玩家对战" or "与另一位指挥官争夺先攻",1)
    modeCard("AI","AI 对局",short and "单人挑战" or "独自迎战，磨炼攻防判断",2)
    local optionsY=top+(sideBySide and cardHeight or cardHeight*2+gap)+12
    local locked=matchMode=="PvP" or not Profile.Value or Profile.Value.stats.gamesPlayed<1
    local optionLabel=matchMode=="PvP" and "同服务器配对" or difficulty=="Advanced" and "难度 · 高级" or "难度 · 标准"
    local b=button(p,optionLabel,0,0,0,0,function()
        if not locked then difficulty=difficulty=="Standard" and "Advanced" or "Standard";route("Setup") end
    end)
    b.Position=UDim2.fromOffset(inset,optionsY);b.Size=UDim2.fromOffset(contentWidth,44)
    b:SetAttribute("ControlId","Difficulty");b:SetAttribute("Disabled",locked);b.Selectable=not locked
    if locked then for _,t in ipairs(b:GetChildren())do if t:IsA("TextLabel")and t.Text=="›" then t:Destroy()end end end
    if optionsY+94<=height-62 then
        label(matchMode=="PvP" and "与朋友进入同一服务器，再同时开始配对。" or locked and "完成首局后解锁高级难度" or "点击切换难度",inset,optionsY+50,contentWidth,44,14,C.Muted)
    end
    if not narrow then
        local art=make("Frame",{Name="MatchPreview",BackgroundColor3=C.Panel,BorderSizePixel=0,
            Position=UDim2.new(.64,0,0,16),Size=UDim2.new(.36,-inset,1,-88),ClipsDescendants=true},p)
        Unit.portrait({make=make},art,matchMode=="PvP" and "ting_sun" or "lan_dun",UDim2.fromScale(0,0),UDim2.fromScale(1,1),true,short and "Face" or "Hero")
        local strip=make("Frame",{Name="PreviewCaption",BackgroundColor3=C.Ink,BackgroundTransparency=.03,BorderSizePixel=0,
            Position=UDim2.new(0,0,1,short and -44 or -88),Size=UDim2.new(1,0,0,short and 44 or 88)},art)
        local t=text(strip,"战术对峙",.06,0,.88,short and 1 or .5,short and 20 or 26,C.Paper,Enum.Font.GothamBold)
        if not short then text(strip,"消灭对方全部单位",.06,.5,.88,.5,14,C.Muted)end
        line(strip,0,0,1,C.Cyan)
    end
    local footerY=height-56
    local backWidth=math.min(narrow and 116 or 164,contentWidth*.40)
    local back=button(p,"返回指挥室",0,0,0,0,function()route("Menu")end)
    back.Position=UDim2.fromOffset(inset,footerY);back.Size=UDim2.fromOffset(backWidth,44)
    local start=button(p,"开始对局",0,0,0,0,function() Battle.Difficulty=difficulty;Battle.Mode=matchMode;route("Battle") end,true)
    start.Position=UDim2.fromOffset(inset+backWidth+12,footerY);start.Size=UDim2.fromOffset(contentWidth-backWidth-12,44)
    start:SetAttribute("ControlId","BeginMatch");start:SetAttribute("Mode",matchMode)
    start.ButtonCaption.Text=matchMode=="PvP" and "进入配对" or "开始对局"
end
local function briefing()
    local p=panel(root,0.035,0.12,0.34,0.77)
    header(p,"MISSION BRIEFING","让对手先露出破绽")
    for i,row in ipairs({{"01  建立阵容","蛇形选取五名不同单位，保留角色各自的反制能力。"},{"02  争夺先攻","秩序 > 新月 > 荒芜 > 秩序。相同能核重新暗选。"},{"03  承诺行动","技能消耗冷却或限定次数。选中攻击目标后，等待对方暗选格挡。"}}) do
        local y=0.33+(i-1)*0.16
        text(p,row[1],0.07,y,0.86,0.05,15,C.Cyan,Enum.Font.GothamMedium)
        text(p,row[2],0.07,y+0.055,0.86,0.085,14,C.Paper)
    end
    bottomButton(p,"返回任务配置",function() route("Setup") end)
    button(root,"战术指导  "..(Tutorial.Enabled and "开" or "关"),0.79,0.70,0.18,0.075,function() Tutorial.Enabled=not Tutorial.Enabled;savePreferences();route("Briefing") end)
    button(root,"开始行动",0.79,0.81,0.18,0.075,function() Battle.Difficulty=difficulty;Battle.Mode=matchMode;route("Battle") end,true)
end
local function archive()
    local p=panel(root,0.035,0.12,0.32,0.77)
    header(p,"TACTICAL ARCHIVE","行动手册")
    text(p,"能核决定行动顺序。技能先于普攻结算；防守方只能让一名单位保护自己。仅剩一名单位时无法格挡。",0.07,0.33,0.86,0.23,17,C.Paper)
    text(p,"KNOWN  /  已知\n阵容、生命与技能冷却\n\nUNKNOWN  /  未知\n未揭示的能核、攻击意图与敌方命线",0.07,0.54,0.86,0.25,14,C.Muted)
    bottomButton(p,"返回指挥室",function() route("Menu") end)
    local details=panel(root,0.69,0.12,0.28,0.77)
    text(details,"UNIT REGISTRY  /  12",0.07,0.03,0.86,0.06,12,C.Cyan)
    local list=make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(0.06,0.115),Size=UDim2.fromScale(0.90,0.84),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.Cyan},details)
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,16)},list)
    for i,h in ipairs(Legacy.heroes) do
        local row=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,-8,0,136),LayoutOrder=i},list)
        Unit.portrait({make=make},row,h.id,UDim2.fromOffset(0,1),UDim2.new(.13,0,0,48),true)
        local title=text(row,h.name.."  /  "..h.english,0.15,0,.85,0,16,C.Paper,Enum.Font.GothamMedium)
        local stats=text(row,h.role.."  ·  "..h.atk.." ATK · "..h.maxHp.." HP",.15,0,.85,0,13,C.Muted)
        local ability=text(row,h.skill.name.." / "..h.skill.description,0,0,1,0,14,C.Paper)
        local divider=line(row,0,0,1)
        local function measureRow()
            local service=game:GetService("TextService")
            local y=0
            for _,label in ipairs({title,stats,ability}) do
                local indent=label==ability and 0 or .15
                local width=math.max(row.AbsoluteSize.X*(1-indent),1)
                local height=math.ceil(service:GetTextSize(label.ContentText,label.TextSize,label.Font,Vector2.new(width,100000)).Y)+6
                label.Position=UDim2.new(indent,0,0,y);label.Size=UDim2.new(1-indent,0,0,height);label.TextYAlignment=Enum.TextYAlignment.Top
                y+=height+6
            end
            divider.Position=UDim2.new(0,0,0,y);row.Size=UDim2.new(1,-8,0,y+1)
        end
        row:GetPropertyChangedSignal("AbsoluteSize"):Connect(measureRow)
        for _,label in ipairs({title,stats,ability}) do label:GetPropertyChangedSignal("TextSize"):Connect(measureRow) end
        task.defer(measureRow)
    end
end
local function getPreferences()
    return {master=Audio.Master,sfx=Audio.SFX,music=Music.Level,reduced=Camera.Reduced,large=uiScale>1,guide=Tutorial.Enabled,language=Locale.Preference}
end
local function changePreference(key,value)
    if key=="master" then Audio.SetLevels(value,Audio.SFX);Music.SetLevels(value,Music.Level)
    elseif key=="sfx" then Audio.SetLevels(Audio.Master,value)
    elseif key=="music" then Music.SetLevels(Audio.Master,value)
    elseif key=="reduced" then Camera.Reduced=value;if Table.SetReduced then Table.SetReduced(value) else Table.Reduced=value end;Camera.Set(Camera.Screen)
    elseif key=="large" then uiScale=value and 1.12 or 1
    elseif key=="guide" then Tutorial.Enabled=value
    elseif key=="language" then Locale.Set(value) end
    savePreferences();Kit.fit(root,uiScale)
end
local function settings()
    local narrow=root.AbsoluteSize.X<760
    local p=panel(root,.035,.12,narrow and .93 or .42,.77);p.Name="PreferencesPanel"
    header(p,"SYSTEM PREFERENCES","设置")
    local area=make("Frame",{Name="SettingsArea",BackgroundTransparency=1,Position=UDim2.fromScale(.07,.34),Size=UDim2.new(.86,0,.66,-108)},p)
    Preferences.render(area,getPreferences,changePreference,function() return uiScale end)
    local about=button(p,"关于与许可",.52,0,.41,0,function()route("Credits")end)
    about.Position=UDim2.new(.52,0,1,-56);about.Size=UDim2.new(.41,0,0,44)
    local note=text(p,Profile.statusText(),.07,0,.86,0,12,C.Muted);note.Position=UDim2.new(.07,0,1,-85);note.Size=UDim2.new(.86,0,0,26)
    local back=bottomButton(p,"返回指挥室",function() route("Menu") end);back.Size=UDim2.new(.41,0,0,44)
end
local function openSessionMenu()
    if not Battle.inProgress() then return end
    SessionMenu.open({root=root,getPreferences=getPreferences,changePreference=changePreference,scale=function() return uiScale end,resume=Battle.refresh,quit=Battle.quit})
end
local function credits()
    local p=panel(root,0.035,0.12,0.35,0.77)
    header(p,"PROJECT CREDITS",Product.Name.." / "..Product.EnglishName)
    local list=make("ScrollingFrame",{Name="CreditsList",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(.07,.33),Size=UDim2.new(.86,0,.67,-76),CanvasSize=UDim2.fromOffset(0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.Cyan},p)
    make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},list)
    local value="核心玩法来源\n《核域对峙 / 异象迷宫》Web 原型\n\n场景与界面\n本工程原创几何、排版与镜头\n\n音效\nRoblox 内置采样；AgentAST / Sci-fi Interface GUI\n剪辑、调速、淡出与混音。\n"
    for _,key in ipairs({"click","select","acknowledge"}) do
        local source=Config.Audio.Sources[key]
        value..="\n"..source.name.."\n"..source.creator.." · "..source.license.."\n"..source.url.."\n"
    end
    value..="\n许可\nhttps://creativecommons.org/licenses/by/3.0/"
    value..="\n战斗音效 · Courtesy of Pro Sound Effects\n"
    for _,key in ipairs({"whoosh","metal","impact"}) do local source=Config.Audio.Sources[key];value..="\n"..source.name.."\n"..source.creator.." · "..source.license.."\n"..source.url.."\n" end
    value..="\n平台音频使用说明\nhttps://create.roblox.com/docs/audio/assets"
    value..="\n环境音乐 · Courtesy of APM Music\n"
    for _,key in ipairs({"Deployment","Battle","Endgame"}) do local source=Config.Music.Sources[key];value..="\n"..source.name.."\n"..source.license.."\n"..source.url.."\n" end
    value..="\n音乐许可\nhttps://en.help.roblox.com/hc/en-us/articles/360000927163-Using-Licensed-Music-on-Roblox"
    local credit=text(list,value,0,0,1,0,14,C.Paper);credit.TextYAlignment=Enum.TextYAlignment.Top
    local function measureCredits()
        local bounds=game:GetService("TextService"):GetTextSize(credit.ContentText,credit.TextSize,credit.Font,Vector2.new(math.max(list.AbsoluteSize.X-8,1),100000))
        credit.Size=UDim2.new(1,-8,0,math.ceil(bounds.Y)+4)
    end
    list:GetPropertyChangedSignal("AbsoluteSize"):Connect(measureCredits)
    credit:GetPropertyChangedSignal("TextSize"):Connect(measureCredits)
    task.defer(measureCredits)
    bottomButton(p,"返回指挥室",function() route("Menu") end)
end
local function recordScreen()
    local p=panel(root,.035,.12,.32,.77);header(p,"TACTICAL RECORD","行动档案")
    local profile=Profile.Value;local s=profile and profile.stats
    local value=s and s.gamesPlayed>0 and ("完成 "..s.gamesPlayed.." 局  /  胜率 "..math.floor(s.wins/s.gamesPlayed*100).."%\n胜利 "..s.wins.."  /  失利 "..s.losses..(s.draws>0 and "\n同归于尽 "..s.draws or "").."\n平均回合 "..string.format("%.1f",s.totalTurns/s.gamesPlayed).."\n最高连胜 "..s.bestStreak.."\n格挡预判 "..(s.readAttempts>0 and math.floor(s.readHits/s.readAttempts*100).."%" or "尚无样本")) or "尚无已完成行动。\n完成一局后，会保留统计和最近五份战报。"
    text(p,value,.07,.34,.86,.36,18,C.Paper);text(p,Profile.statusText(),.07,.74,.86,.10,12,C.Muted)
    bottomButton(p,"返回指挥室",function() route("Menu") end)
    local side=panel(root,.59,.12,.38,.77);text(side,"RECENT OPERATIONS / 最近行动",.06,.035,.88,.08,13,C.Cyan)
    local list=make("ScrollingFrame",{Name="RecordHistory",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(.06,.15),Size=UDim2.fromScale(.88,.80),CanvasSize=UDim2.fromOffset(0,profile and #profile.history*82 or 0),ScrollBarThickness=3,ScrollBarImageColor3=C.Cyan},side)
    if profile then for i,entry in ipairs(profile.history) do local v=entry.view;local title=(v.winner=="A" and "胜利" or v.winner=="B" and "失利" or "同归于尽").."  /  "..(entry.difficulty=="PvP" and "双人" or entry.difficulty=="Advanced" and "高级" or "标准").."  /  "..v.round.." 回合"
        local b=button(list,title,0,0,1,0,function() historyView=v;route("HistoryReport") end);b.Position=UDim2.fromOffset(0,(i-1)*82);b.Size=UDim2.new(1,-8,0,70);b:SetAttribute("ControlId","History:"..i)
    end end
end
local function fit()
    Kit.fit(root,uiScale)
end
route=function(nextScreen,resetHub)
    local oldList=root:FindFirstChild("HubContent",true)
    if oldList then hubScrolls[screen]=oldList.CanvasPosition.Y end
    if resetHub then hubScrolls[nextScreen]=0 end
    SessionMenu.close(false)
    screen=nextScreen
    root:ClearAllChildren()
    root:SetAttribute("Screen",screen)
    Camera.Set(screen)
    Music.SetScreen(screen)
    chrome()
    if screen=="Menu" then menu()
    elseif screen=="Shop" or screen=="Inventory" or screen=="Career" or screen=="Friends" then hub(screen)
    elseif screen=="Character" then character()
    elseif screen=="Setup" then setup()
    elseif screen=="Briefing" then briefing()
    elseif screen=="Archive" then archive()
    elseif screen=="Settings" then settings()
    elseif screen=="Record" then recordScreen()
    elseif screen=="HistoryReport" and historyView then Report.render({root=root,make=make,text=text,button=button,panel=function(parent,x,y,w,h,a) return panel(parent,x,y,w,h,a,true) end,line=line,fit=fit},historyView,function() route("Record") end)
    elseif screen=="Abandoned" then local p=panel(root,.035,.12,.34,.77);header(p,"OPERATION CANCELLED","对手已离开")
        text(p,"这场行动已取消，不记录胜负。\n你可以回到指挥室重新配对。",.07,.36,.86,.30,18,C.Paper);bottomButton(p,"返回指挥室",function() route("Menu") end,true)
    elseif screen=="Credits" then credits()
    elseif screen=="Training" then
        Battle.Mode="Training";Battle.Difficulty="Standard";screen="Battle";root:SetAttribute("Screen","Battle");Camera.Set("Battle");Battle.start()
    elseif screen=="Battle" then
        text(root,"正在连接战略桌…",0.35,0.43,0.45,0.12,24,C.Paper)
        Battle.start()
    elseif screen=="Title" then
        local p=panel(root,0.035,0.19,0.35,0.65,0.08)
        text(p,"AXIOM STRATEGIC SYSTEMS",0.075,0.04,0.85,0.10,11,C.Cyan)
        text(p,Product.Name,0.07,0.16,0.88,0.30,66,C.Paper,Enum.Font.GothamBold)
        text(p,Product.EnglishName,0.075,0.45,0.84,0.10,21,C.Cyan,Enum.Font.GothamMedium)
        text(p,Product.Tagline,0.075,0.60,0.84,0.10,17,C.Muted)
        button(p,"ENTER COMMAND",0.075,0.77,0.85,0.15,function() route("Menu") end,true)
    end
    Responsive.apply(root,screen)
    fit()
    if UserInputService.GamepadEnabled then
        GuiService.SelectedObject=root:FindFirstChildWhichIsA("TextButton",true)
    end
end
local resizeTicket=0
root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    resizeTicket+=1;local ticket=resizeTicket
    task.delay(.08,function() if ticket~=resizeTicket then return end
        SessionMenu.reflow()
        if screen=="Battle" and Battle.active() then Battle.refresh()
        elseif screen~="Boot" and screen~="Battle" then route(screen) end
    end)
end)
game:GetService("ContextActionService"):BindActionAtPriority("FirstMoveSessionMenu",function(_,state,input)
    if not SessionMenu.active() and not Battle.active() then return Enum.ContextActionResult.Pass end
    if state==Enum.UserInputState.Begin then
        if SessionMenu.active() then SessionMenu.close()
        elseif Battle.inProgress() then openSessionMenu()
        elseif input.KeyCode==Enum.KeyCode.Backspace or input.KeyCode==Enum.KeyCode.ButtonB then Audio.Play("back");Battle.quit() end
    end
    return Enum.ContextActionResult.Sink
end,false,Enum.ContextActionPriority.High.Value,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.ButtonB,Enum.KeyCode.ButtonStart)
UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Backspace or input.KeyCode==Enum.KeyCode.ButtonB then
        if not Battle.active() and not SessionMenu.active() and screen~="Title" then Audio.Play("back");route("Menu") end
    end
end)
local boot=panel(root,0,0,1,1,0)
text(boot,"FIRST MOVE  /  AXIOM CONTROL",0.35,0.43,0.5,0.10,24,C.Paper,Enum.Font.GothamMedium)
Battle.init({root=root,make=make,text=text,button=button,panel=panel,line=line,chrome=chrome,fit=fit,fontScale=function() return uiScale end,route=route,preferences=savePreferences,openMenu=openSessionMenu,menuActive=SessionMenu.active,closeMenu=function() SessionMenu.close(false) end,reflow=Responsive.apply})
Profile.Changed.Event:Connect(function()
    if Profile.Value then local s=Profile.Value.settings;Locale.Set(s.language or "auto");Audio.SetLevels(s.master,s.sfx);Music.SetLevels(s.master,s.music);Camera.Reduced=s.reduced;if Table.SetReduced then Table.SetReduced(s.reduced) else Table.Reduced=s.reduced end;uiScale=s.large and 1.12 or 1;Tutorial.Enabled=s.guide end
    if screen=="Menu" or screen=="Record" or screen=="Settings" or screen=="Setup" or screen=="Shop" or screen=="Inventory" or screen=="Career" or screen=="Character" then route(screen) end
end)
Profile.start()
Locale.Changed.Event:Connect(function()
    task.defer(function()
        if SessionMenu.active()then SessionMenu.reflow()end
        if screen=="Battle"and Battle.active()then Battle.refresh()
        elseif screen~="Boot"and screen~="Battle"then route(screen)end
    end)
end)

for _,event in ipairs({Players.PlayerAdded,Players.PlayerRemoving})do
    event:Connect(function()task.defer(function()if screen=="Friends"then route("Friends")end end)end)
end
task.delay(0.8,function() route("Menu") end)
