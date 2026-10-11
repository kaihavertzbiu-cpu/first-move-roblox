-- Real Roblox GUI geometry with shipping Bootstrap renderers. Services which
-- could alter a match, camera, audio or profile are replaced. No input synthesis.
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local kit;local callbacks={};local checks={};local scenes={};local currentGui
local function check(name,value) assert(value,name);table.insert(checks,name) end
local function loadWith(module,fakeGame,dependencies,scheduler)
    return assert(loadstring("local game,script,require,task=...\n"..module.Source))(fakeGame,{Parent=modules},function(k) return assert(dependencies[k],"Unexpected require "..tostring(k)) end,scheduler or task)
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
dependencies[modules.RankAssets]=rankAssets
dependencies[modules.ResponsiveLayout]=loadWith(modules.ResponsiveLayout,game,dependencies)
dependencies[modules.PreferencesView]=loadWith(modules.PreferencesView,game,dependencies)
dependencies[modules.SessionMenu]={close=function() end,active=function() return false end}
dependencies[modules.CameraController]={Set=function() end,Reduced=false}
dependencies[modules.TableController]={Reduced=false}
dependencies[modules.TutorialController]={Enabled=true}
dependencies[modules.BattleController]={init=function() end,active=function() return false end,refresh=function() end}
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
    end
    if label=="Settings" then
        local panel=root:FindFirstChild("PreferencesPanel");local area=panel.SettingsArea;local footer=panel:FindFirstChildWhichIsA("TextButton")
        check("Settings scroll does not overlap save status",area.AbsolutePosition.Y+area.AbsoluteSize.Y<=panel.AbsolutePosition.Y+panel.AbsoluteSize.Y-108.01+1)
        check("Settings still has one full touch row",area.AbsoluteSize.Y>=44)
    end
    if label=="Menu" then
        local featured=root:FindFirstChild("FeaturedUnit")
        local nextUnit=featured:FindFirstChild("下一位")
        for _,t in ipairs(featured:GetChildren()) do
            if t:IsA("TextLabel") or t:IsA("ViewportFrame") then
                check("Featured unit fits panel "..viewport,t.AbsoluteSize.Y>0 and t.AbsolutePosition.Y>=featured.AbsolutePosition.Y and t.AbsolutePosition.Y+t.AbsoluteSize.Y<=featured.AbsolutePosition.Y+featured.AbsoluteSize.Y+1)
                if nextUnit then check("Featured unit clears preview control "..viewport,t.AbsolutePosition.Y+t.AbsoluteSize.Y+1<=nextUnit.AbsolutePosition.Y) end
                if t:IsA("TextLabel") then check("Featured unit text readable "..viewport,t.TextBounds.Y<=t.AbsoluteSize.Y+1 and t.TextBounds.X<=t.AbsoluteSize.X+1) end
            end
        end
    end
    table.insert(scenes,{viewport=viewport,screen=label,targets=targets,scrollBodies=bodyCount})
end

local profile=dependencies[modules.ProfileController]
profile.Value={economy={credits=200,xp=250,rating=250,owned={},equipped="default"},stats={gamesPlayed=10,wins=1,readHits=10},history={}}
local calls=0;local pending
profile.action=function(command,id,done) calls+=1;pending=done end
local ok,err=pcall(function()
loadWith(modules.Bootstrap,fakeGame,dependencies,scheduler)
currentGui=assert(core:FindFirstChild("DeadlockUI"));currentGui.Name="FirstMoveHubQA"
currentGui.Router.Size=UDim2.fromOffset(1280,722);task.wait(.15)
for _,timer in ipairs(timers)do if timer.seconds==.8 then timer.fn();break end end;task.wait(.15)
activate("商店")
local buy=assert(find("兑换 · 120 核晶"));local cb=callbacks[buy]
cb();task.wait(.15)
check("request issued once",calls==1)
check("busy state visible",find("正在同步…")~=nil)
cb();check("stale callback cannot double submit",calls==1)
profile.Value.economy.credits=80;profile.Value.economy.owned.signal_cyan=true
pending("已更新");task.wait(.15)
activate("装备印记")
check("equip request issued",calls==2)
profile.Value.economy.equipped="signal_cyan";pending("已更新");task.wait(.15)
check("equipped state visible",find("已装备")~=nil)
activate("生涯");inspect("Career with progress","1280x722")
end)
if currentGui then currentGui:Destroy()end
profile.Changed:Destroy()
if not ok then error(err)end
return {passed=#checks,scope="Hub UI with mock profile RPC; not cloud persistence verification"}
