-- Shipping callbacks + real GUI engine + real rules accepting submitted intents.
-- Local fixtures only; no hardware input, live transport or two-client acceptance.
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local locale=require(modules.LocaleController);locale.Set("zh-cn")
local Rules=require(game.ServerScriptService.DeadlockServer.MatchRules)
local Http=game:GetService("HttpService")
local checks={};local scenes={};local callbacks={};local sent={};local gui
local function check(name,value) assert(value,name);table.insert(checks,name) end
local state={OnClientEvent={Connect=function(self,fn) self.callback=fn end}}
local intent={FireServer=function(_,packet) table.insert(sent,packet) end}
local remotes={State=state,WaitForChild=function(_,name) return name=="Intent" and intent or state end}
local shared=game.ReplicatedStorage.DeadlockShared
local fakeGame={GetService=function(_,name)
    if name=="GuiService" then return {} end
    if name=="UserInputService" then return {GamepadEnabled=false} end
    if name=="ReplicatedStorage" then return {WaitForChild=function(_,key) return key=="DeadlockRemotes" and remotes or shared end} end
    return game:GetService(name)
end}
local dependencies={[modules.PresentationConfig]=require(modules.PresentationConfig),[modules.UnitIdentity]=require(modules.UnitIdentity),[modules.UnitPresentation]=require(modules.UnitPresentation),[modules.AudioController]={Play=function()end},[modules.CameraController]={Reduced=true},[modules.TableController]={update=function()end,reset=function()end},[modules.PresentationDirector]={reset=function()end,update=function()end,resolving=function()return false end},[modules.ReportController]={},[modules.TutorialController]={Enabled=false},[shared.ProductConfig]=require(shared.ProductConfig)}
dependencies[modules.LocaleController]=locale
dependencies[modules.ReportStory]=require(modules.ReportStory)
local function load(module) return assert(loadstring("local game,script,require,task=...\n"..module.Source))(fakeGame,{Parent=modules},function(k)return assert(dependencies[k],"Missing dependency")end,{delay=function()end,defer=task.defer}) end
local kit=load(modules.InterfaceKit);dependencies[modules.InterfaceKit]=kit
local rawButton=kit.button;kit.button=function(...)local args={...};local b=rawButton(...);callbacks[b]=args[7];return b end
local Battle=load(modules.BattleController)
local function find(id) for _,b in ipairs(gui:GetDescendants())do if b:IsA("TextButton") and b:GetAttribute("ControlId")==id then return b end end end
local function click(id) local b=assert(find(id),"Missing "..id);assert(not b:GetAttribute("Disabled"),"Disabled "..id);callbacks[b]();task.wait(.08) end
local function details() if not gui.Router.ActionRail.ActionDetails.Visible then click("ActionDrawer") end end
local function clone(v) return Http:JSONDecode(Http:JSONEncode(v)) end
local pools={A={"zhui_lie","shuang_xing","beng_yue","yan_wei","bai_ji"},B={"lan_dun","ting_sun","chi_guang","zhe_jing","xuan_bao"}}
local skill=Rules.new();local indices={A=0,B=0}
while skill.phase=="Draft" do local owner=Rules.view(skill,"A").actor;indices[owner]+=1;assert(Rules.apply(skill,owner,{kind="DraftPick",heroId=pools[owner][indices[owner]],revision=skill.revision})) end
assert(Rules.apply(skill,"A",{kind="CoreLock",core="cyan",revision=skill.revision}))
assert(Rules.apply(skill,"B",{kind="CoreLock",core="purple",revision=skill.revision}))
assert(skill.phase=="SkillPhase" and skill.actor=="A","Fixture initiative")
local attack=clone(skill);assert(Rules.apply(attack,"A",{kind="SkillEnd",revision=attack.revision}))
local function show(model)
    local v=Rules.view(model,"A");v.sessionId="targeting-local-fixture";v.mode="AI"
    state.OnClientEvent.callback({view=v,started=true});task.wait(.08)
end
local function submit(model,kind)
    click("PrimaryAction");local payload=sent[#sent].intent
    check("Submitted "..kind,payload and payload.kind==kind)
    local accepted,err=Rules.apply(model,"A",payload);check("Real rules accept "..kind.." "..tostring(err),accepted)
    return payload
end
local function inspect(label,viewport)
    for _,b in ipairs(gui.Router:GetDescendants()) do if b:IsA("TextButton") then
        local id=b:GetAttribute("ControlId") or ""
        if id:match("^TargetSlot:") or id=="PrimaryAction" then
            check(label.." "..viewport.." touch target",b.AbsoluteSize.X>=43.99 and b.AbsoluteSize.Y>=43.99)
            for _,t in ipairs(b:GetChildren())do if t:IsA("TextLabel") and t.Visible then check(label.." "..viewport.." label bounds",t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1) end end
        end
        if id:match("^Hero:") then
            local badge=b:FindFirstChild("TargetOrder")
            for _,t in ipairs(b:GetChildren())do if t:IsA("TextLabel") then
                check(label.." "..viewport.." roster label fits",t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1)
                if badge and t~=badge and t.AbsolutePosition.Y<badge.AbsolutePosition.Y+badge.AbsoluteSize.Y and badge.AbsolutePosition.Y<t.AbsolutePosition.Y+t.AbsoluteSize.Y then
                    check(label.." "..viewport.." order badge clears name",badge.AbsolutePosition.X+badge.AbsoluteSize.X<=t.AbsolutePosition.X)
                end
            end end
        end
    end end
    table.insert(scenes,{viewport=viewport,screen=label})
end
local function editorVisible(label)
    details();local list=gui.Router.ActionRail.ActionDetails
    for _,id in ipairs({"TargetSlot:1","TargetSlot:2"})do local b=find(id);if b then check(label.." editor visible without scrolling",b.AbsolutePosition.Y>=list.AbsolutePosition.Y and b.AbsolutePosition.Y+b.AbsoluteSize.Y<=list.AbsolutePosition.Y+list.AbsoluteSize.Y+1) end end
end
local ok,err=pcall(function()
    for _,size in ipairs({{390,722},{676,560},{750,303},{844,332},{1280,722}})do
        callbacks={};gui=Instance.new("ScreenGui");gui.Name="FirstMoveTargetingQA";gui.Parent=game:GetService("CoreGui")
        local root=Instance.new("Frame");root.Name="Router";root.Size=UDim2.fromOffset(size[1],size[2]);root.BackgroundTransparency=1;root.Parent=gui;task.wait(.08)
        Battle.init({root=root,make=kit.make,text=kit.text,button=kit.button,panel=kit.panel,line=kit.line,chrome=function()end,fit=function()kit.fit(root,1.12)end,fontScale=function()return 1.12 end,route=function()end})
        local viewport=size[1].."x"..size[2]
        local twin=clone(attack);show(twin);click("Hero:A:shuang_xing");details();click("Option:1")
        click("Hero:B:ting_sun");click("Hero:B:lan_dun");editorVisible("Twin "..viewport)
        check("Twin "..viewport.." ordered HUD markers",find("Hero:B:ting_sun"):GetAttribute("TargetOrder")=="①" and find("Hero:B:lan_dun"):GetAttribute("TargetOrder")=="②")
        click("TargetSlot:1")
        if find("ActionDrawer")then check("Twin "..viewport.." editing closes blocking drawer",not root.ActionRail.ActionDetails.Visible);check("Twin "..viewport.." heading identifies active slot",string.find(root.OwnershipHeading.Text,"①",1,true)~=nil)end
        click("Hero:B:chi_guang");details();click("TargetSlot:2");click("Hero:B:chi_guang")
        check("Twin "..viewport.." distinct collision requires replacement",find("PrimaryAction"):GetAttribute("Disabled"))
        click("Hero:B:xuan_bao");inspect("Twin corrected",viewport)
        local twinIntent=submit(twin,"AttackCommit")
        check("Twin "..viewport.." first edited independently",twinIntent.targets[1]=="chi_guang" and twinIntent.targets[2]=="xuan_bao")
        check("Twin "..viewport.." enemy projection remains private",Rules.view(twin,"B").ownAttack==nil)
        show(twin);click("Hero:B:ting_sun");check("Waiting "..viewport.." inspection does not imply hidden target",find("Hero:B:ting_sun"):GetAttribute("TargetOrder")==nil and find("PrimaryAction"):GetAttribute("Disabled"))
        local maul=clone(attack);show(maul);click("Hero:A:beng_yue");details();click("Option:1");click("Hero:B:ting_sun");click("Hero:B:ting_sun")
        check("Maul "..viewport.." repeat target enables commit",not find("PrimaryAction"):GetAttribute("Disabled"))
        check("Maul "..viewport.." repeated HUD marker",find("Hero:B:ting_sun"):GetAttribute("TargetOrder")=="×2")
        inspect("Maul repeated",viewport)
        details();click("TargetSlot:1");click("Hero:B:lan_dun");inspect("Maul first edited",viewport)
        local maulIntent=submit(maul,"AttackCommit")
        check("Maul "..viewport.." replacing first retains second",maulIntent.targets[1]=="lan_dun" and maulIntent.targets[2]=="ting_sun")
        -- Public 6 HP fixture: the first hit kills and enables the conditional second hit.
        local final=clone(skill);final.rosters.B[3].hp=6;show(final);click("Hero:A:zhui_lie");check("Final "..viewport.." first target required",find("PrimaryAction"):GetAttribute("Disabled"))
        details();click("TargetSlot:2");click("Hero:B:lan_dun");details()
        local firstEmpty=false;for _,label in ipairs(find("TargetSlot:1"):GetChildren())do if label:IsA("TextLabel") and string.find(label.Text,"未选择",1,true)then firstEmpty=true end end
        check("Final "..viewport.." selecting second first keeps first empty",firstEmpty and find("PrimaryAction"):GetAttribute("Disabled"))
        show(final);click("Hero:A:zhui_lie")
        click("Hero:B:ting_sun");check("Final "..viewport.." second target required",find("PrimaryAction"):GetAttribute("Disabled"))
        click("Hero:B:lan_dun");editorVisible("Final "..viewport);click("TargetSlot:1");click("Hero:B:chi_guang");inspect("Final ready",viewport)
        local finalIntent=submit(final,"SkillCast")
        check("Final "..viewport.." ordered skill targets retained",finalIntent.targetId=="chi_guang" and finalIntent.secondTargetId=="lan_dun" and final.rosters.A[1].used)
        check("Final "..viewport.." killing first enables second",not final.rosters.B[3].alive and final.rosters.B[1].hp==16)
        local noKill=clone(skill);show(noKill);click("Hero:A:zhui_lie");click("Hero:B:chi_guang");click("Hero:B:lan_dun");submit(noKill,"SkillCast")
        check("Final "..viewport.." surviving first does not hit second",noKill.rosters.B[3].hp==12 and noKill.rosters.B[1].hp==26)
        -- Explicit one-survivor boundary sample, not a natural completed match.
        local one=clone(attack);for i,h in ipairs(one.rosters.B)do if i>1 then h.alive=false;h.hp=0 end end
        show(one);click("Hero:A:shuang_xing");check("One enemy "..viewport.." no unusable twin toggle",find("Option:1")==nil)
        click("Hero:B:lan_dun");inspect("One enemy normal attack",viewport);local oneIntent=submit(one,"AttackCommit")
        check("One enemy "..viewport.." normal attack remains valid",#oneIntent.targets==1 and not oneIntent.useSkill)
        local finalOne=clone(skill);for i,h in ipairs(finalOne.rosters.B)do if i>1 then h.alive=false;h.hp=0 end end
        show(finalOne);click("Hero:A:zhui_lie");click("Hero:B:lan_dun");check("Final one "..viewport.." no second slot",find("TargetSlot:2")==nil)
        inspect("Final one survivor",viewport);local singleIntent=submit(finalOne,"SkillCast")
        check("Final one "..viewport.." legacy single target retained",singleIntent.secondTargetId==nil and finalOne.rosters.B[1].hp==18)
        local echo=clone(skill);show(echo);click("Hero:A:yan_wei");click("Hero:B:ting_sun");inspect("Self destruct",viewport)
        local echoIntent=submit(echo,"SkillCast")
        check("Echo "..viewport.." unrelated preselection cannot auto rattle",echoIntent.targetId==nil and echoIntent.secondTargetId==nil and echo.phase=="DeathRattleChoice")
        gui:Destroy();gui=nil
    end
end)
if gui then gui:Destroy()end
if not ok then error(err)end
return Http:JSONEncode({scope="Local shipping callbacks, Roblox GUI geometry and real rules accepting intents; fake transport/audio/camera; explicit low-HP and one-survivor boundary samples; no hardware or live PvP acceptance",passed=#checks,scenes=scenes})
