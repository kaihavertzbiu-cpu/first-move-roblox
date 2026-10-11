-- Real Roblox GUI geometry with shipping Bootstrap renderers. Services which
-- could alter a match, camera, audio or profile are replaced. No input synthesis.
local qa=Instance.new("Folder");qa.Name="DossierTypographyQA";qa.Parent=game.ServerStorage
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient:Clone();modules.Parent=qa
local locale=require(modules.LocaleController);locale.Set("zh-cn")
local kit;local callbacks={};local checks={};local scenes={};local currentGui
local function check(name,value) assert(value,name);table.insert(checks,name) end
local function loadWith(module,fakeGame,dependencies,scheduler)
    return assert(loadstring("local game,script,require,task=...\n"..module.Source))(fakeGame,{Parent=modules},function(k) return k==modules.LocaleController and locale or assert(dependencies[k],"Unexpected require "..tostring(k)) end,scheduler or task)
end
local core=game:GetService("CoreGui")
local config=require(modules.PresentationConfig)
local rankAssets=require(modules.RankAssets)
local audio;audio={Master=.65,SFX=.7,Play=function() end,SetLevels=function(master,sfx) audio.Master=master;audio.SFX=sfx end}
local dependencies={[modules.PresentationConfig]=config,[modules.AudioController]=audio,[modules.UnitIdentity]=require(modules.UnitIdentity),[modules.UnitPresentation]=require(modules.UnitPresentation)}
dependencies[modules.MusicController]={Level=.35,SetLevels=function() end,SetScreen=function() end}
kit=loadWith(modules.InterfaceKit,game,dependencies);local rawButton=kit.button
kit.button=function(...) local args={...};local b=rawButton(...);callbacks[b]=args[7];return b end
dependencies[modules.InterfaceKit]=kit
dependencies[modules.HubView]=loadWith(modules.HubView,game,dependencies)
dependencies[modules.RankAssets]=rankAssets
dependencies[modules.ResponsiveLayout]=loadWith(modules.ResponsiveLayout,game,dependencies)
dependencies[modules.PreferencesView]=loadWith(modules.PreferencesView,game,dependencies)
dependencies[modules.SessionMenu]={close=function() end,active=function() return false end}
dependencies[modules.CameraController]={Set=function() end,Reduced=false}
dependencies[modules.TableController]={Reduced=false}
dependencies[modules.TutorialController]={Enabled=true}
local started={}
local battle={active=function() return false end,refresh=function() end}
battle.init=function(ui) battle.route=ui.route end
battle.start=function() table.insert(started,{mode=battle.Mode,difficulty=battle.Difficulty})end
dependencies[modules.BattleController]=battle
dependencies[modules.ReportController]={}
dependencies[modules.ProfileController]={Value={stats={gamesPlayed=0},history={}},Storage={mode="Studio"},Changed=Instance.new("BindableEvent"),start=function() end,save=function() end,statusText=function() return "Studio 试玩 · 记录仅在本次测试内保留" end}
local product=game.ReplicatedStorage.DeadlockShared.ProductConfig;dependencies[product]=require(product)
local progression=game.ReplicatedStorage.DeadlockShared.ProgressionConfig;dependencies[progression]=require(progression)
local timers={}
local guiService={}
local fakeGame={GetService=function(_,name)
    if name=="Players" then return {LocalPlayer={DisplayName="指挥官",WaitForChild=function() return core end},GetPlayers=function()return {}end} end
    if name=="StarterGui" then return {SetCoreGuiEnabled=function() end} end
    if name=="UserInputService" then return {GamepadEnabled=false,InputBegan={Connect=function() end}} end
    if name=="GuiService" then return guiService end
    if name=="ContextActionService" then return {BindActionAtPriority=function() end} end
    return game:GetService(name)
end}
local scheduler={spawn=function() end,defer=task.defer,delay=function(seconds,fn) table.insert(timers,{seconds=seconds,fn=fn}) end}
local Session=loadWith(modules.SessionMenu,fakeGame,dependencies)
local function find(label) for _,b in ipairs(currentGui:GetDescendants()) do if b:IsA("TextButton") and b.Name==label then return b end end end
local function activate(label) local b=assert(find(label),"Missing "..label);assert(callbacks[b],"Missing callback");callbacks[b]();task.wait(.15) end
local function inspect(label,viewport)
    local root=currentGui.Router;local targets,bodyCount=0,0
    for _,b in ipairs(root:GetDescendants()) do
        if b:IsA("TextButton") then targets+=1;check(label.." target "..targets.." >=44px",b.AbsoluteSize.X>=43.99 and b.AbsoluteSize.Y>=43.99) end
        if b:IsA("ScrollingFrame") and b.Name=="PanelBody" then
            bodyCount+=1;check(label.." body has readable viewport",b.AbsoluteSize.Y>=44)
            local footer=b.Parent:FindFirstChildWhichIsA("TextButton")
            if footer then check(label.." body clears footer",b.AbsolutePosition.Y+b.AbsoluteSize.Y<=footer.AbsolutePosition.Y-7.99) end
            for _,t in ipairs(b:GetChildren()) do if t:IsA("TextLabel") then check(label.." paragraph fits measured height",t.TextBounds.Y<=t.AbsoluteSize.Y+1) end end
        end
    end
    if root:FindFirstChild("PlayerHub") then
        local hub=root.PlayerHub
        check(label.." scrolling content clears footer",hub.HubContent.AbsolutePosition.Y+hub.HubContent.AbsoluteSize.Y<=hub.AbsolutePosition.Y+hub.AbsoluteSize.Y-60)
        for _,t in ipairs(hub:GetDescendants())do
            if t:IsA("TextLabel") and t.Visible then
                check(label.." readable "..t.Text,t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1)
            end
        end
        local fixed={}
        for _,b in ipairs(hub:GetChildren())do if b:IsA("TextButton")then
            table.insert(fixed,b)
            check(label.." fixed control visible "..b.Name,b.AbsolutePosition.Y>=hub.AbsolutePosition.Y and b.AbsolutePosition.Y+b.AbsoluteSize.Y<=hub.AbsolutePosition.Y+hub.AbsoluteSize.Y+1)
        end end
        for i,a in ipairs(fixed)do for j=i+1,#fixed do
            local b=fixed[j]
            local xx=math.min(a.AbsolutePosition.X+a.AbsoluteSize.X,b.AbsolutePosition.X+b.AbsoluteSize.X)-math.max(a.AbsolutePosition.X,b.AbsolutePosition.X)
            local yy=math.min(a.AbsolutePosition.Y+a.AbsoluteSize.Y,b.AbsolutePosition.Y+b.AbsoluteSize.Y)-math.max(a.AbsolutePosition.Y,b.AbsolutePosition.Y)
            check(label.." fixed controls separated "..a.Name.." "..b.Name,xx<=1 or yy<=1)
        end end
    end
    if label=="Settings" then
        local panel=root:FindFirstChild("PreferencesPanel");local area=panel.SettingsArea;local footer=panel:FindFirstChildWhichIsA("TextButton")
        check("Settings scroll does not overlap save status",area.AbsolutePosition.Y+area.AbsoluteSize.Y<=panel.AbsolutePosition.Y+panel.AbsoluteSize.Y-108.01+1)
        check("Settings still has one full touch row",area.AbsoluteSize.Y>=44)
    end
    if label=="Menu" then
        local featured=root:FindFirstChild("FeaturedUnit")
        local command=root.CommandMenu
        local art,caption=featured.UnitPortrait,featured.FeaturedCaption
        check("Menu portrait is not covered by information "..viewport,art.AbsolutePosition.Y+art.AbsoluteSize.Y<=caption.AbsolutePosition.Y+1)
        local buttons={}
        for _,obj in ipairs(root:GetDescendants())do
            check("Menu never requires scrolling "..viewport,not obj:IsA("ScrollingFrame"))
            if obj:IsA("TextButton")then
                table.insert(buttons,obj)
                check("Menu button visible in viewport "..viewport.." "..obj.Name,obj.AbsolutePosition.Y>=root.AbsolutePosition.Y and obj.AbsolutePosition.Y+obj.AbsoluteSize.Y<=root.AbsolutePosition.Y+root.AbsoluteSize.Y*.937 and obj.AbsolutePosition.X>=root.AbsolutePosition.X and obj.AbsolutePosition.X+obj.AbsoluteSize.X<=root.AbsolutePosition.X+root.AbsoluteSize.X)
            elseif obj:IsA("TextLabel")and obj.Visible then
                check("Menu typography fits "..viewport.." "..obj.ContentText,obj.TextBounds.X<=obj.AbsoluteSize.X+1 and obj.TextBounds.Y<=obj.AbsoluteSize.Y+1)
            end
        end
        for i,a in ipairs(buttons)do for j=i+1,#buttons do
            local b=buttons[j]
            local x=math.min(a.AbsolutePosition.X+a.AbsoluteSize.X,b.AbsolutePosition.X+b.AbsoluteSize.X)-math.max(a.AbsolutePosition.X,b.AbsolutePosition.X)
            local y=math.min(a.AbsolutePosition.Y+a.AbsoluteSize.Y,b.AbsolutePosition.Y+b.AbsoluteSize.Y)-math.max(a.AbsolutePosition.Y,b.AbsolutePosition.Y)
            check("Menu buttons never overlap "..viewport.." "..a.Name.." "..b.Name,x<=1 or y<=1)
        end end
        for _,name in ipairs({"商店","背包","生涯","好友"})do
            local b=find(name)
            check("Menu shortcuts clear footer "..viewport,b.AbsolutePosition.Y+b.AbsoluteSize.Y<=root.AbsolutePosition.Y+root.AbsoluteSize.Y*.937)
        end
        check("Menu panels separated "..viewport,command.AbsolutePosition.X+command.AbsoluteSize.X<featured.AbsolutePosition.X)
        local labels={}
        for _,t in ipairs(command:GetChildren())do
            if t:IsA("TextLabel")and t.Visible then
                check("Menu brand text fits "..viewport.." "..t.Text,t.TextBounds.Y<=t.AbsoluteSize.Y+1 and t.TextBounds.X<=t.AbsoluteSize.X+1)
                table.insert(labels,t)
            end
        end
        table.sort(labels,function(a,b)return a.AbsolutePosition.Y<b.AbsolutePosition.Y end)
        for i=2,#labels do check("Menu brand rows separated "..viewport,labels[i-1].AbsolutePosition.Y+labels[i-1].AbsoluteSize.Y<=labels[i].AbsolutePosition.Y+1)end
        if #labels>0 then check("Menu brand clears navigation "..viewport,labels[#labels].AbsolutePosition.Y+labels[#labels].AbsoluteSize.Y<=command.CommandNavigation.AbsolutePosition.Y+1)end
        local nextUnit=featured:FindFirstChild("下一位")
        for _,t in ipairs(featured:GetChildren()) do
            if t:IsA("TextLabel") or t:IsA("ViewportFrame") then
                check("Featured unit fits panel "..viewport,t.AbsoluteSize.Y>0 and t.AbsolutePosition.Y>=featured.AbsolutePosition.Y and t.AbsolutePosition.Y+t.AbsoluteSize.Y<=featured.AbsolutePosition.Y+featured.AbsoluteSize.Y+1)
                if nextUnit then check("Featured unit clears preview control "..viewport,t.AbsolutePosition.Y+t.AbsoluteSize.Y+1<=nextUnit.AbsolutePosition.Y) end
                if t:IsA("TextLabel") then check("Featured unit text readable "..viewport,t.TextBounds.Y<=t.AbsoluteSize.Y+1 and t.TextBounds.X<=t.AbsoluteSize.X+1) end
            end
        end
    end
    if label=="Setup" then
        local p=root.MatchSetup
        local pvp,ai,begin=find("双人对峙"),find("AI 对局"),find("开始对局")
        check("Setup has two explicit modes "..viewport,pvp~=nil and ai~=nil)
        check("Setup exactly one selected mode "..viewport,pvp:GetAttribute("Selected")~=ai:GetAttribute("Selected"))
        check("Setup selected mode reaches action "..viewport,begin:GetAttribute("Mode")== (pvp:GetAttribute("Selected")and "PvP" or "AI"))
        local options;for _,b in ipairs(p:GetChildren())do if b:GetAttribute("ControlId")=="Difficulty"then options=b end end
        check("Setup options clear action "..viewport,options.AbsolutePosition.Y+options.AbsoluteSize.Y+6<=begin.AbsolutePosition.Y)
        for _,t in ipairs(p:GetDescendants())do
            if t:IsA("TextLabel")and t.Visible then
                check("Setup readable "..viewport.." "..t.Text,t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1)
            end
        end
    end
    table.insert(scenes,{viewport=viewport,screen=label,targets=targets,scrollBodies=bodyCount})
end
local profile=dependencies[modules.ProfileController]
local portraits={}
local ok,err=pcall(function()
    for _,size in ipairs({{390,722},{750,303},{676,560},{1280,722},{1274,419}})do
        for _,large in ipairs({false,true})do
            timers={};callbacks={}
            profile.Value.settings={master=.65,sfx=.7,music=.35,reduced=false,large=large,guide=true,language=locale.Preference}
            loadWith(modules.Bootstrap,fakeGame,dependencies,scheduler)
            currentGui=assert(core:FindFirstChild("DeadlockUI"));currentGui.Name="DossierTypographyQA"
            currentGui.Router.Size=UDim2.fromOffset(size[1],size[2]);task.wait(.15)
            for _,timer in ipairs(timers)do if timer.seconds==.8 then timer.fn();break end end
            task.wait(.15);profile.Changed:Fire();task.wait(.15);activate("详情")
            local viewport=size[1].."x"..size[2]..(large and " large"or " normal")
            local seen={}
            for i=1,12 do
                local p=currentGui.Router.CharacterDossier
                local scroll=p.CharacterDetails
                local id=p.UnitPortrait:GetAttribute("UnitId")
                check(viewport.." unique role "..id,not seen[id]);seen[id]=true;portraits[id]=true
                for _,t in ipairs(scroll:GetDescendants())do if t:IsA("TextLabel")then
                    check(viewport.." natural glyph "..t.Name,not t.RichText and not t.Text:find("<font")and t:GetAttribute("NaturalGlyphs"))
                    check(viewport.." measured paragraph "..id.." "..t.Name,t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1)
                    check(viewport.." font "..t.Name,t.FontFace.Family==(t.Name=="CharacterCodename"and config.DossierTypography.CodeFamily or config.DossierTypography.Family))
                end end
                for _,name in ipairs({"SkillDescription","Biography","WorldBackground"})do
                    local t=scroll[name]
                    check(viewport.." line height "..name,math.abs(t.LineHeight-config.DossierTypography.LineHeight)<.001)
                    check(viewport.." readable size "..name,t.TextSize>=18)
                end
                check(viewport.." hierarchy name",scroll.DossierIdentity.CharacterName.FontFace.Weight==Enum.FontWeight.Bold)
                local footer=find("返回")
                check(viewport.." scroll clears footer",scroll.AbsolutePosition.Y+scroll.AbsoluteSize.Y<=footer.AbsolutePosition.Y-7.99)
                check(viewport.." art clears footer",p.UnitPortrait.AbsolutePosition.Y+p.UnitPortrait.AbsoluteSize.Y<=footer.AbsolutePosition.Y)
                check(viewport.." scroll has viewport",scroll.AbsoluteSize.Y>=100)
                for _,label in ipairs({"上一位","下一位","返回"})do
                    local b=find(label)
                    check(viewport.." fixed button "..label,b.AbsoluteSize.Y>=44 and b.AbsoluteSize.X>=44 and b.AbsolutePosition.Y+b.AbsoluteSize.Y<=currentGui.Router.AbsolutePosition.Y+size[2])
                end
                table.insert(scenes,{viewport=viewport,id=id,bodySize=scroll.SkillDescription.TextSize,storySize=scroll.Biography.TextSize,title=scroll.DossierIdentity.CharacterName.Text,titleSize=scroll.DossierIdentity.CharacterName.TextSize})
                activate("下一位")
            end
            local old=currentGui.Router.CharacterDossier
            profile.Value.settings.large=not large;profile.Changed:Fire();task.wait(.15)
            check(viewport.." preference rerenders dossier",old.Parent==nil and currentGui.Router:FindFirstChild("CharacterDossier")~=nil)
            currentGui:Destroy();profile.Changed:Destroy()
            profile.Changed=Instance.new("BindableEvent")
        end
    end
end)
if currentGui and currentGui.Parent then currentGui:Destroy()end
profile.Changed:Destroy();qa:Destroy()
if not ok then error(err)end
local count=0;for _ in pairs(portraits)do count+=1 end
return game.HttpService:JSONEncode({passed=#checks,scenes=scenes,characters=count,rendering="Shipping Lua, isolated GUI/services, measured Roblox TextBounds"})

