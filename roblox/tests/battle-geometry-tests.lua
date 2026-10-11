local terminalFixture=game:GetService('HttpService'):JSONDecode("{\"report\":{\"turningDeaths\":3,\"rounds\":[{\"completed\":true,\"fallen\":[{\"id\":\"shuang_xing\",\"owner\":\"A\"}],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":2,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":16},\"B\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":1,\"survivors\":0,\"healing\":0,\"executions\":1,\"damage\":0}},\"ties\":0,\"initiative\":\"B\",\"round\":1,\"cores\":{\"A\":\"purple\",\"B\":\"cyan\"}},{\"completed\":true,\"fallen\":[],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":0},\"B\":{\"hp\":0,\"blocks\":1,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7}},\"ties\":0,\"initiative\":\"B\",\"round\":2,\"cores\":{\"A\":\"purple\",\"B\":\"cyan\"}},{\"completed\":true,\"fallen\":[],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":0},\"B\":{\"hp\":0,\"blocks\":1,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7}},\"ties\":0,\"initiative\":\"A\",\"round\":3,\"cores\":{\"A\":\"cyan\",\"B\":\"purple\"}},{\"completed\":true,\"fallen\":[],\"teams\":{\"A\":{\"hp\":0,\"blocks\":1,\"links\":0,\"skills\":2,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":0},\"B\":{\"hp\":0,\"blocks\":2,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":0}},\"ties\":0,\"initiative\":\"B\",\"round\":4,\"cores\":{\"A\":\"red\",\"B\":\"purple\"}},{\"completed\":true,\"fallen\":[{\"id\":\"ting_sun\",\"owner\":\"B\"}],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":6},\"B\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7}},\"ties\":0,\"initiative\":\"A\",\"round\":5,\"cores\":{\"A\":\"purple\",\"B\":\"red\"}},{\"completed\":true,\"fallen\":[],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7},\"B\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7}},\"ties\":0,\"initiative\":\"B\",\"round\":6,\"cores\":{\"A\":\"purple\",\"B\":\"cyan\"}},{\"completed\":true,\"fallen\":[{\"id\":\"chi_guang\",\"owner\":\"A\"},{\"id\":\"yan_wei\",\"owner\":\"A\"},{\"id\":\"bai_ji\",\"owner\":\"B\"}],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":1,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":16},\"B\":{\"hp\":0,\"blocks\":2,\"links\":0,\"skills\":1,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":22}},\"ties\":0,\"initiative\":\"B\",\"round\":7,\"cores\":{\"A\":\"cyan\",\"B\":\"red\"}},{\"completed\":true,\"fallen\":[{\"id\":\"beng_yue\",\"owner\":\"A\"}],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7},\"B\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":8}},\"ties\":1,\"initiative\":\"A\",\"round\":8,\"cores\":{\"A\":\"red\",\"B\":\"cyan\"}},{\"completed\":true,\"fallen\":[],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":10},\"B\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7}},\"ties\":0,\"initiative\":\"A\",\"round\":9,\"cores\":{\"A\":\"red\",\"B\":\"cyan\"}},{\"completed\":true,\"fallen\":[],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":6},\"B\":{\"hp\":0,\"blocks\":1,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":7}},\"ties\":0,\"initiative\":\"B\",\"round\":10,\"cores\":{\"A\":\"purple\",\"B\":\"cyan\"}},{\"fallen\":[{\"id\":\"huan_shi\",\"owner\":\"B\"},{\"id\":\"xuan_bao\",\"owner\":\"A\"}],\"teams\":{\"A\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":11},\"B\":{\"hp\":0,\"blocks\":0,\"links\":0,\"skills\":0,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":8}},\"ties\":1,\"initiative\":\"A\",\"round\":11,\"cores\":{\"A\":\"purple\",\"B\":\"red\"}}],\"teams\":{\"A\":{\"hp\":0,\"blocks\":1,\"links\":0,\"skills\":5,\"survivors\":0,\"healing\":0,\"executions\":0,\"damage\":79},\"B\":{\"hp\":30,\"blocks\":7,\"links\":0,\"skills\":2,\"survivors\":2,\"healing\":0,\"executions\":1,\"damage\":80}},\"finalRound\":11,\"turningRound\":7,\"winner\":\"B\",\"schemaVersion\":1,\"completedRounds\":10},\"revision\":103,\"picksRemaining\":0,\"phase\":\"GameOver\",\"ownCore\":\"purple\",\"winner\":\"B\",\"events\":[{\"A\":\"purple\",\"kind\":\"CoreReveal\",\"round\":1,\"B\":\"cyan\"},{\"owner\":\"B\",\"round\":1,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":1,\"kind\":\"AttackCommitted\"},{\"round\":1,\"kind\":\"Skill\",\"source\":\"ting_sun\",\"code\":\"thunder_judgment\"},{\"target\":\"shuang_xing\",\"kind\":\"Execute\",\"source\":\"ting_sun\",\"round\":1},{\"target\":\"shuang_xing\",\"owner\":\"A\",\"round\":1,\"kind\":\"Death\"},{\"owner\":\"A\",\"round\":1,\"kind\":\"ActionStart\"},{\"round\":1,\"kind\":\"Skill\",\"source\":\"chi_guang\",\"code\":\"stasis_lock\"},{\"target\":\"zhui_lie\",\"kind\":\"Lock\",\"source\":\"chi_guang\",\"round\":1},{\"owner\":\"A\",\"round\":1,\"kind\":\"AttackCommitted\"},{\"round\":1,\"kind\":\"Skill\",\"source\":\"beng_yue\",\"code\":\"fury_press\"},{\"damageType\":\"Normal\",\"source\":\"beng_yue\",\"amount\":8,\"target\":\"ting_sun\",\"effective\":8,\"round\":1,\"kind\":\"Damage\"},{\"damageType\":\"Normal\",\"source\":\"beng_yue\",\"amount\":8,\"target\":\"ting_sun\",\"effective\":8,\"round\":1,\"kind\":\"Damage\"},{\"round\":1,\"kind\":\"RoundEnd\"},{\"A\":\"purple\",\"kind\":\"CoreReveal\",\"round\":2,\"B\":\"cyan\"},{\"owner\":\"B\",\"round\":2,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":2,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"huan_shi\",\"amount\":7,\"target\":\"chi_guang\",\"effective\":7,\"round\":2,\"kind\":\"Damage\"},{\"owner\":\"A\",\"round\":2,\"kind\":\"ActionStart\"},{\"owner\":\"A\",\"round\":2,\"kind\":\"AttackCommitted\"},{\"target\":\"ting_sun\",\"kind\":\"Block\",\"source\":\"beng_yue\",\"round\":2},{\"round\":2,\"kind\":\"RoundEnd\"},{\"A\":\"cyan\",\"kind\":\"CoreReveal\",\"round\":3,\"B\":\"purple\"},{\"owner\":\"A\",\"round\":3,\"kind\":\"ActionStart\"},{\"owner\":\"A\",\"round\":3,\"kind\":\"AttackCommitted\"},{\"target\":\"ting_sun\",\"kind\":\"Block\",\"source\":\"xuan_bao\",\"round\":3},{\"owner\":\"B\",\"round\":3,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":3,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"huan_shi\",\"amount\":7,\"target\":\"yan_wei\",\"effective\":7,\"round\":3,\"kind\":\"Damage\"},{\"round\":3,\"kind\":\"RoundEnd\"},{\"A\":\"red\",\"kind\":\"CoreReveal\",\"round\":4,\"B\":\"purple\"},{\"owner\":\"B\",\"round\":4,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":4,\"kind\":\"AttackCommitted\"},{\"target\":\"yan_wei\",\"kind\":\"Block\",\"source\":\"zhui_lie\",\"round\":4},{\"owner\":\"A\",\"round\":4,\"kind\":\"ActionStart\"},{\"round\":4,\"kind\":\"Skill\",\"source\":\"chi_guang\",\"code\":\"stasis_lock\"},{\"target\":\"zhui_lie\",\"kind\":\"Lock\",\"source\":\"chi_guang\",\"round\":4},{\"owner\":\"A\",\"round\":4,\"kind\":\"AttackCommitted\"},{\"round\":4,\"kind\":\"Skill\",\"source\":\"beng_yue\",\"code\":\"fury_press\"},{\"target\":\"ting_sun\",\"kind\":\"Block\",\"source\":\"beng_yue\",\"round\":4},{\"target\":\"ting_sun\",\"kind\":\"Block\",\"source\":\"beng_yue\",\"round\":4},{\"round\":4,\"kind\":\"RoundEnd\"},{\"A\":\"purple\",\"kind\":\"CoreReveal\",\"round\":5,\"B\":\"red\"},{\"owner\":\"A\",\"round\":5,\"kind\":\"ActionStart\"},{\"owner\":\"A\",\"round\":5,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"xuan_bao\",\"amount\":7,\"target\":\"ting_sun\",\"effective\":6,\"round\":5,\"kind\":\"Damage\"},{\"target\":\"ting_sun\",\"owner\":\"B\",\"round\":5,\"kind\":\"Death\"},{\"owner\":\"B\",\"round\":5,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":5,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"huan_shi\",\"amount\":7,\"target\":\"beng_yue\",\"effective\":7,\"round\":5,\"kind\":\"Damage\"},{\"round\":5,\"kind\":\"RoundEnd\"},{\"A\":\"purple\",\"kind\":\"CoreReveal\",\"round\":6,\"B\":\"cyan\"},{\"owner\":\"B\",\"round\":6,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":6,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"huan_shi\",\"amount\":7,\"target\":\"chi_guang\",\"effective\":7,\"round\":6,\"kind\":\"Damage\"},{\"owner\":\"A\",\"round\":6,\"kind\":\"ActionStart\"},{\"owner\":\"A\",\"round\":6,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"xuan_bao\",\"amount\":7,\"target\":\"bai_ji\",\"effective\":7,\"round\":6,\"kind\":\"Damage\"},{\"round\":6,\"kind\":\"RoundEnd\"},{\"A\":\"cyan\",\"kind\":\"CoreReveal\",\"round\":7,\"B\":\"red\"},{\"owner\":\"B\",\"round\":7,\"kind\":\"ActionStart\"},{\"round\":7,\"kind\":\"Skill\",\"source\":\"zhui_lie\",\"code\":\"final_barrage\"},{\"damageType\":\"Skill\",\"source\":\"zhui_lie\",\"amount\":8,\"target\":\"chi_guang\",\"effective\":6,\"round\":7,\"kind\":\"Damage\"},{\"target\":\"chi_guang\",\"owner\":\"A\",\"round\":7,\"kind\":\"Death\"},{\"damageType\":\"Skill\",\"source\":\"zhui_lie\",\"amount\":10,\"target\":\"yan_wei\",\"effective\":9,\"round\":7,\"kind\":\"Damage\"},{\"target\":\"yan_wei\",\"owner\":\"A\",\"round\":7,\"kind\":\"Death\"},{\"damageType\":\"DeathRattle\",\"source\":\"yan_wei\",\"amount\":15,\"target\":\"bai_ji\",\"effective\":15,\"round\":7,\"kind\":\"Damage\"},{\"owner\":\"B\",\"round\":7,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"huan_shi\",\"amount\":7,\"target\":\"beng_yue\",\"effective\":7,\"round\":7,\"kind\":\"Damage\"},{\"owner\":\"A\",\"round\":7,\"kind\":\"ActionStart\"},{\"damageType\":\"Bleeding\",\"source\":\"xuan_bao\",\"amount\":3,\"target\":\"bai_ji\",\"effective\":1,\"round\":7,\"kind\":\"Damage\"},{\"target\":\"bai_ji\",\"owner\":\"B\",\"round\":7,\"kind\":\"Death\"},{\"owner\":\"A\",\"round\":7,\"kind\":\"AttackCommitted\"},{\"round\":7,\"kind\":\"Skill\",\"source\":\"beng_yue\",\"code\":\"fury_press\"},{\"target\":\"huan_shi\",\"kind\":\"Block\",\"source\":\"beng_yue\",\"round\":7},{\"target\":\"huan_shi\",\"kind\":\"Block\",\"source\":\"beng_yue\",\"round\":7},{\"round\":7,\"kind\":\"RoundEnd\"},{\"A\":\"cyan\",\"kind\":\"CoreReveal\",\"round\":8,\"B\":\"cyan\"},{\"round\":8,\"kind\":\"CoreTie\"},{\"A\":\"red\",\"kind\":\"CoreReveal\",\"round\":8,\"B\":\"cyan\"},{\"owner\":\"A\",\"round\":8,\"kind\":\"ActionStart\"},{\"owner\":\"A\",\"round\":8,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"xuan_bao\",\"amount\":7,\"target\":\"zhui_lie\",\"effective\":7,\"round\":8,\"kind\":\"Damage\"},{\"owner\":\"B\",\"round\":8,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":8,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"zhui_lie\",\"amount\":8,\"target\":\"beng_yue\",\"effective\":8,\"round\":8,\"kind\":\"Damage\"},{\"target\":\"beng_yue\",\"owner\":\"A\",\"round\":8,\"kind\":\"Death\"},{\"round\":8,\"kind\":\"RoundEnd\"},{\"A\":\"red\",\"kind\":\"CoreReveal\",\"round\":9,\"B\":\"cyan\"},{\"owner\":\"A\",\"round\":9,\"kind\":\"ActionStart\"},{\"damageType\":\"Bleeding\",\"source\":\"xuan_bao\",\"amount\":3,\"target\":\"zhui_lie\",\"effective\":3,\"round\":9,\"kind\":\"Damage\"},{\"owner\":\"A\",\"round\":9,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"xuan_bao\",\"amount\":7,\"target\":\"huan_shi\",\"effective\":7,\"round\":9,\"kind\":\"Damage\"},{\"owner\":\"B\",\"round\":9,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":9,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"huan_shi\",\"amount\":7,\"target\":\"xuan_bao\",\"effective\":7,\"round\":9,\"kind\":\"Damage\"},{\"round\":9,\"kind\":\"RoundEnd\"},{\"A\":\"purple\",\"kind\":\"CoreReveal\",\"round\":10,\"B\":\"cyan\"},{\"owner\":\"B\",\"round\":10,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":10,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"huan_shi\",\"amount\":7,\"target\":\"xuan_bao\",\"effective\":7,\"round\":10,\"kind\":\"Damage\"},{\"owner\":\"A\",\"round\":10,\"kind\":\"ActionStart\"},{\"damageType\":\"Bleeding\",\"source\":\"xuan_bao\",\"amount\":3,\"target\":\"zhui_lie\",\"effective\":3,\"round\":10,\"kind\":\"Damage\"},{\"damageType\":\"Bleeding\",\"source\":\"xuan_bao\",\"amount\":3,\"target\":\"huan_shi\",\"effective\":3,\"round\":10,\"kind\":\"Damage\"},{\"owner\":\"A\",\"round\":10,\"kind\":\"AttackCommitted\"},{\"target\":\"zhui_lie\",\"kind\":\"Block\",\"source\":\"xuan_bao\",\"round\":10},{\"round\":10,\"kind\":\"RoundEnd\"},{\"A\":\"purple\",\"kind\":\"CoreReveal\",\"round\":11,\"B\":\"purple\"},{\"round\":11,\"kind\":\"CoreTie\"},{\"A\":\"purple\",\"kind\":\"CoreReveal\",\"round\":11,\"B\":\"red\"},{\"owner\":\"A\",\"round\":11,\"kind\":\"ActionStart\"},{\"damageType\":\"Bleeding\",\"source\":\"xuan_bao\",\"amount\":3,\"target\":\"zhui_lie\",\"effective\":3,\"round\":11,\"kind\":\"Damage\"},{\"damageType\":\"Bleeding\",\"source\":\"xuan_bao\",\"amount\":3,\"target\":\"huan_shi\",\"effective\":3,\"round\":11,\"kind\":\"Damage\"},{\"owner\":\"A\",\"round\":11,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"xuan_bao\",\"amount\":7,\"target\":\"huan_shi\",\"effective\":5,\"round\":11,\"kind\":\"Damage\"},{\"target\":\"huan_shi\",\"owner\":\"B\",\"round\":11,\"kind\":\"Death\"},{\"owner\":\"B\",\"round\":11,\"kind\":\"ActionStart\"},{\"owner\":\"B\",\"round\":11,\"kind\":\"AttackCommitted\"},{\"damageType\":\"Normal\",\"source\":\"zhui_lie\",\"amount\":8,\"target\":\"xuan_bao\",\"effective\":8,\"round\":11,\"kind\":\"Damage\"},{\"target\":\"xuan_bao\",\"owner\":\"A\",\"round\":11,\"kind\":\"Death\"},{\"winner\":\"B\",\"round\":11,\"kind\":\"GameOver\"}],\"coreLocked\":{\"A\":true,\"B\":true},\"rosters\":{\"A\":[{\"statuses\":[],\"used\":false,\"atk\":7,\"maxHp\":22,\"id\":\"xuan_bao\",\"alive\":false,\"hp\":0,\"cooldown\":0},{\"statuses\":[],\"used\":false,\"atk\":7,\"maxHp\":22,\"id\":\"shuang_xing\",\"alive\":false,\"hp\":0,\"cooldown\":0},{\"statuses\":[],\"used\":false,\"atk\":8,\"maxHp\":22,\"id\":\"beng_yue\",\"alive\":false,\"hp\":0,\"cooldown\":2},{\"statuses\":[],\"used\":false,\"atk\":7,\"maxHp\":16,\"id\":\"yan_wei\",\"alive\":false,\"hp\":0,\"cooldown\":0},{\"statuses\":[],\"used\":false,\"atk\":4,\"maxHp\":20,\"id\":\"chi_guang\",\"alive\":false,\"hp\":0,\"cooldown\":0}],\"B\":[{\"statuses\":{\"bleeding\":true},\"used\":false,\"atk\":8,\"maxHp\":22,\"id\":\"ting_sun\",\"alive\":false,\"hp\":0,\"cooldown\":1},{\"statuses\":{\"bleeding\":true},\"used\":true,\"atk\":8,\"maxHp\":20,\"id\":\"zhui_lie\",\"alive\":true,\"hp\":4,\"cooldown\":0},{\"statuses\":{\"bleeding\":true},\"used\":false,\"atk\":7,\"maxHp\":18,\"id\":\"huan_shi\",\"alive\":false,\"hp\":0,\"cooldown\":0},{\"statuses\":[],\"used\":false,\"atk\":3,\"maxHp\":26,\"id\":\"lan_dun\",\"alive\":true,\"hp\":26,\"cooldown\":0},{\"statuses\":{\"bleeding\":true},\"used\":false,\"atk\":4,\"maxHp\":23,\"id\":\"bai_ji\",\"alive\":false,\"hp\":0,\"cooldown\":0}]},\"round\":11,\"initiative\":\"A\"}")
-- Real Roblox GUI geometry, shipping battle/report renderers, fake state transport.
-- The terminal fixture is an earlier real rules-generated match, not a new match.
local qa=Instance.new("Folder");qa.Name="BattleGeometryQA";qa.Parent=game.ServerStorage
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient:Clone();modules.Parent=qa
local locale=require(modules.LocaleController);locale.Set("zh-cn")
local checks={};local scenes={};local gui
local function check(name,value) assert(value,name);table.insert(checks,name) end
local config=require(modules.PresentationConfig);local identity=require(modules.UnitIdentity)
local callbacks={};local timers={};local sent={}
local clock=0
local state={OnClientEvent={Connect=function(self,fn) self.callback=fn end}}
local intent={FireServer=function(_,packet) table.insert(sent,packet) end}
local remotes={State=state,WaitForChild=function(_,name) return name=="Intent" and intent or state end}
local replicated={DeadlockShared=game.ReplicatedStorage.DeadlockShared,WaitForChild=function(_,name) return name=="DeadlockRemotes" and remotes or game.ReplicatedStorage:WaitForChild(name) end}
local fakeGame={GetService=function(_,name)
    if name=="GuiService" then return {} end
    if name=="UserInputService" then return {GamepadEnabled=false} end
    if name=="ReplicatedStorage" then return replicated end
    return game:GetService(name)
end}
local dependencies={[modules.PresentationConfig]=config,[modules.UnitIdentity]=identity,[modules.UnitPresentation]=require(modules.UnitPresentation),[modules.AudioController]={Play=function() end},[modules.CameraController]={Reduced=true},[modules.TableController]={update=function() end,reset=function() end},[modules.PresentationDirector]={reset=function() end,update=function() end,resolving=function() return false end}}
dependencies[modules.LocaleController]=locale
dependencies[game.ReplicatedStorage.DeadlockShared.ProductConfig]=require(game.ReplicatedStorage.DeadlockShared.ProductConfig)
dependencies[game.ReplicatedStorage.DeadlockShared.LegacyConfig]=require(game.ReplicatedStorage.DeadlockShared.LegacyConfig)
dependencies[modules.ReportStory]=require(modules.ReportStory)
local function load(module,scheduler) return assert(loadstring("local game,script,require,task,os=...\n"..module.Source))(fakeGame,{Parent=modules},function(k) return assert(dependencies[k],"Unknown dependency") end,scheduler or task,{clock=function() return clock end}) end
local kit=load(modules.InterfaceKit);dependencies[modules.InterfaceKit]=kit
local raw=kit.button;kit.button=function(...) local args={...};local b=raw(...);callbacks[b]=args[7];return b end
dependencies[modules.TutorialController]=load(modules.TutorialController)
dependencies[modules.ReportController]=load(modules.ReportController)
local layout=load(modules.ResponsiveLayout)
local battle=load(modules.BattleController,{delay=function(seconds,fn) table.insert(timers,fn) end})
local function find(id) for _,b in ipairs(gui:GetDescendants()) do if b:IsA("TextButton") and (b:GetAttribute("ControlId")==id or b.Name==id) then return b end end end
local function click(id) local b=assert(find(id),"Missing "..id);assert(not b:GetAttribute("Disabled"),"Disabled "..id);callbacks[b]();task.wait(.1) end
local Rules=require(game.ServerScriptService.DeadlockServer.MatchRules)
local Training=require(game.ServerScriptService.DeadlockServer.TrainingMatch)
local initial=Rules.new();local built=Rules.new();local n=0
for _,h in ipairs(identity.heroes) do if h.id~="ye_ban" and n<10 then local v=Rules.view(built,"A");assert(Rules.apply(built,v.actor,{kind="DraftPick",heroId=h.id,revision=v.revision}));n+=1 end end
local coreView=Rules.view(built,"A");coreView.sessionId="geometry"
local terminal=terminalFixture;terminal.sessionId="geometry-terminal"
terminal.reward={credits=20,xp=40,rating=-15}
local function inspect(label,size)
    local root=gui.Router;local count=0
    for _,b in ipairs(root:GetDescendants()) do if b:IsA("TextButton") then
        count+=1;check(size.." "..label.." target "..count,b.AbsoluteSize.X>=43.99 and b.AbsoluteSize.Y>=43.99)
        local id=b:GetAttribute("ControlId") or ""
        if id:match("^Hero:") or id:match("^Draft:") then
            for i,t in ipairs(b:GetChildren()) do if t:IsA("TextLabel") then
                check(size.." "..label.." "..id.." label "..i.." readable bounds",t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1)
                check(size.." "..label.." "..id.." label "..i.." remains in card",t.Position.Y.Offset+t.AbsoluteSize.Y<=b.AbsoluteSize.Y+1)
            end end
        end
    end end
    local details=root:FindFirstChild("ActionRail")
    if details and details.ActionDetails.Visible then
        local list=details.ActionDetails;local primary=find("PrimaryAction") or find("SyncState")
        check(size.." "..label.." details clears fixed action",list.AbsolutePosition.Y+list.AbsoluteSize.Y<=primary.AbsolutePosition.Y-7.99)
        for _,item in ipairs(list:GetDescendants()) do if item:IsA("TextLabel") and (item.Parent.Name=="DecisionUnit" or (item.Parent:GetAttribute("ControlId") or ""):match("^TargetSlot:")) then
            check(size.." "..label.." decision text fits "..item.Text,item.TextBounds.X<=item.AbsoluteSize.X+1 and item.TextBounds.Y<=item.AbsoluteSize.Y+1)
        end end
    end
    local report=root:FindFirstChild("RoundReview",true)
    if report then
        for i,t in ipairs(root:GetDescendants()) do if t:IsA("TextLabel") and t.Visible then
            check(size.." "..label.." report text "..i.." readable bounds",t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1)
        end end
        check(size.." report list has usable viewport",report.ReviewList.AbsoluteSize.Y>=44)
        local previousBottom=0
        for _,item in ipairs(report.ReviewList:GetChildren()) do if item.Name=="ClosingStep" then
            local label=item.ClosingText
            check(size.." closing timeline row fits",item.AbsoluteSize.Y>=label.AbsoluteSize.Y and label.AbsoluteSize.X>0)
            check(size.." closing timeline text clears insignia",label.AbsolutePosition.X>=item.AbsolutePosition.X+45)
            check(size.." closing timeline stays ordered",item.AbsolutePosition.Y>=previousBottom)
            previousBottom=item.AbsolutePosition.Y+item.AbsoluteSize.Y
        end end
        check(size.." report return stays in banner",find("ReportReturn").AbsolutePosition.Y+find("ReportReturn").AbsoluteSize.Y<=root.ReportBanner.AbsolutePosition.Y+root.ReportBanner.AbsoluteSize.Y+1)
        local metrics=root:FindFirstChild("MetricStrip",true);local overview=root:FindFirstChild("OverviewPanel",true)
        check(size.." report metrics do not overlap overview",metrics.AbsolutePosition.Y+metrics.AbsoluteSize.Y<=overview.AbsolutePosition.Y)
        local again=find("ReportRematch");local back=find("ReportReturn")
        if again then
            check(size.." rematch remains inside banner",again.AbsolutePosition.Y>=root.ReportBanner.AbsolutePosition.Y and again.AbsolutePosition.Y+again.AbsoluteSize.Y<=root.ReportBanner.AbsolutePosition.Y+root.ReportBanner.AbsoluteSize.Y+1)
            check(size.." rematch and return do not overlap",again.AbsolutePosition.Y+again.AbsoluteSize.Y<=back.AbsolutePosition.Y or again.AbsolutePosition.X+again.AbsoluteSize.X<=back.AbsolutePosition.X)
        end
    end
    table.insert(scenes,{viewport=size,screen=label,targets=count})
end
local function inspectQueue(label)
    local panel=gui.Router.WaitingPanel;local body=panel.QueueExplanation
    local practice,back=find("QueuePractice"),find("Quit")
    check(label.." queue readable scroll viewport",body.AbsoluteSize.Y>=44)
    check(label.." queue text clears footer",body.AbsolutePosition.Y+body.AbsoluteSize.Y+7.99<=math.min(practice.AbsolutePosition.Y,back.AbsolutePosition.Y))
    check(label.." queue actions do not overlap",practice.AbsolutePosition.Y+practice.AbsoluteSize.Y+7.99<=back.AbsolutePosition.Y or practice.AbsolutePosition.X+practice.AbsoluteSize.X+7.99<=back.AbsolutePosition.X)
    for _,button in ipairs({practice,back}) do
        check(label.." queue action stays in panel",button.AbsolutePosition.Y>=panel.AbsolutePosition.Y and button.AbsolutePosition.Y+button.AbsoluteSize.Y<=panel.AbsolutePosition.Y+panel.AbsoluteSize.Y+1)
    end
    for _,t in ipairs(panel:GetDescendants()) do if t:IsA("TextLabel") then
        check(label.." queue text fits "..t.Name,t.TextBounds.X<=t.AbsoluteSize.X+1 and t.TextBounds.Y<=t.AbsoluteSize.Y+1)
    end end
end
local ok,err=pcall(function()
    for _,size in ipairs({{390,722},{676,560},{750,303},{844,332},{1280,722}}) do
        callbacks={};gui=Instance.new("ScreenGui");gui.Name="FirstMoveBattleGeometryQA";gui.Parent=game:GetService("CoreGui")
        local root=Instance.new("Frame");root.Name="Router";root.Size=UDim2.fromOffset(size[1],size[2]);root.BackgroundTransparency=1;root.Parent=gui;task.wait(.1)
        local ui={root=root,make=kit.make,text=kit.text,button=kit.button,panel=kit.panel,line=kit.line,chrome=function() end,fit=function() kit.fit(root,1.12) end,fontScale=function() return 1.12 end,route=function() end,closeMenu=function() end,reflow=layout.apply}
        battle.init(ui);battle.start();task.wait(.1);local label=size[1].."x"..size[2];inspect("Connecting",label)
        timers[#timers]();task.wait(.1);inspect("SlowConnecting",label)
        clock=0;state.OnClientEvent.callback({queued=true});task.wait(.1);inspect("Waiting",label);inspectQueue(label)
        clock=31;timers[#timers]();task.wait(.1);inspectQueue(label.." long wait")
        local packetsBeforeResize=#sent
        root.Size=UDim2.fromOffset(size[2],size[1]);task.wait(.1);battle.refresh();task.wait(.1);inspectQueue(label.." rotated")
        check(label.." queue rotation keeps elapsed time",root:FindFirstChild("QueueElapsed",true).Text=="已等待 00:31")
        root.Size=UDim2.fromOffset(size[1],size[2]);task.wait(.1);battle.refresh();task.wait(.1);inspectQueue(label.." restored")
        check(label.." queue resizing sends no network actions",#sent==packetsBeforeResize)
        local draft=Rules.view(initial,"A");draft.sessionId="geometry";state.OnClientEvent.callback({view=draft,started=true});task.wait(.1);inspect("Draft",label)
        click(identity.heroes[1].name.."\n"..identity.heroes[1].atk.." ATK · "..identity.heroes[1].maxHp.." HP");inspect("DraftDetails",label)
        state.OnClientEvent.callback({view=coreView,started=true});task.wait(.1)
        if find("ActionDrawer") then click("ActionDrawer") end;inspect("CoreSelection",label)
        click("Core:red");click("PrimaryAction");timers[#timers]();task.wait(.1);inspect("SlowAction",label)
        state.OnClientEvent.callback({view=coreView,synced=true});task.wait(.1)
        if find("GuidePanel") then click("GuidePanel");inspect("GuideSheet",label);click("GuideToggle") end
        state.OnClientEvent.callback({view=terminal,started=true});task.wait(.1);inspect("ReportHighlights",label)
        local closing=dependencies[modules.ReportStory].build(terminal).closing
        local replay=root:FindFirstChild("ClosingReplay",true)
        check(label.." replay begins at first public event",replay:GetAttribute("PublicEventIndex")==closing.steps[1].index)
        check(label.." first replay step cannot go earlier",find("ReportStepPrevious"):GetAttribute("Disabled"))
        local packetsBeforeReplay=#sent
        for i=2,#closing.steps do
            click("ReportStepNext");inspect("ReportStep"..i,label)
            check(label.." replay follows public reveal order",replay:GetAttribute("PublicEventIndex")==closing.steps[i].index)
            check(label.." replay caption is a recorded fact",replay:FindFirstChild("ReplayFact",true).Text==closing.steps[i].text)
        end
        check(label.." replay ends at last retained fact",find("ReportStepNext"):GetAttribute("Disabled"))
        check(label.." reviewing never sends a game action",#sent==packetsBeforeReplay)
        click("ReportRounds");inspect("ReportRounds",label)
        click("ReportRound:11");inspect("ReportRoundEvents",label)
        click("ReportEvents");inspect("ReportEvents",label);click("ReportHighlights")
        check(label.." recap preserves selected step",root:FindFirstChild("ClosingReplay",true):GetAttribute("PublicEventIndex")==closing.steps[#closing.steps].index)
        click("ReportRounds")
        local reviewList=root:FindFirstChild("ReviewList",true)
        reviewList.CanvasPosition=Vector2.new(0,120);local savedRounds=reviewList.CanvasPosition.Y
        local rematchView=game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):JSONEncode(terminal))
        rematchView.mode="PvP";rematchView.rematch={available=true,opponentRequested=true}
        local packetsBefore=#sent
        state.OnClientEvent.callback({view=rematchView});task.wait(.15)
        check(label.." rematch update retains rounds tab",find("ReportRounds"):GetAttribute("Selected"))
        check(label.." rematch update retains rounds scroll",math.abs(root:FindFirstChild("ReviewList",true).CanvasPosition.Y-savedRounds)<1)
        inspect("ReportInvitationContinuity",label)
        click("ReportRound:11")
        reviewList=root:FindFirstChild("ReviewList",true);reviewList.CanvasPosition=Vector2.new(0,60);local savedEvents=reviewList.CanvasPosition.Y
        rematchView.rematch.opponentRequested=false;rematchView.rematch.requested=true
        state.OnClientEvent.callback({view=rematchView});task.wait(.15)
        check(label.." rematch update retains filtered events tab",find("ReportEvents"):GetAttribute("Selected"))
        local filtered=false;for _,t in ipairs(root:FindFirstChild("ReviewList",true):GetChildren())do if t:IsA("TextLabel") and t.Text:find("R11 · 按实际揭示顺序",1,true)then filtered=true end end
        check(label.." rematch update retains selected round",filtered)
        check(label.." rematch update retains event scroll",math.abs(root:FindFirstChild("ReviewList",true).CanvasPosition.Y-savedEvents)<1)
        click("ReportRounds");check(label.." switching back restores rounds position",math.abs(root:FindFirstChild("ReviewList",true).CanvasPosition.Y-savedRounds)<1)
        local body=root:FindFirstChild("ReportBody")
        if body then
            body.CanvasPosition=Vector2.new(0,100);local savedBody=body.CanvasPosition.Y
            state.OnClientEvent.callback({view=rematchView});task.wait(.15)
            check(label.." rematch update retains outer report position",math.abs(root.ReportBody.CanvasPosition.Y-savedBody)<1)
        end
        root.Size=UDim2.fromOffset(size[1],size[2]+90);task.wait(.1);battle.refresh();task.wait(.15)
        check(label.." resize retains report tab",find("ReportRounds"):GetAttribute("Selected"))
        check(label.." resize safely clamps scroll",root:FindFirstChild("ReviewList",true).CanvasPosition.Y<=math.max(0,root:FindFirstChild("ReviewList",true).AbsoluteCanvasSize.Y-root:FindFirstChild("ReviewList",true).AbsoluteSize.Y)+1)
        check(label.." reading updates do not submit replay requests",#sent==packetsBefore)
        root.Size=UDim2.fromOffset(size[1],size[2]);task.wait(.1)
        local freshReport=game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):JSONEncode(terminal));freshReport.sessionId="new-report-"..label
        state.OnClientEvent.callback({view=freshReport});task.wait(.15)
        check(label.." another match starts at closing recap",find("ReportHighlights"):GetAttribute("Selected"))
        check(label.." another match starts at top",root:FindFirstChild("ReviewList",true).CanvasPosition.Y==0 and (not root:FindFirstChild("ReportBody") or root.ReportBody.CanvasPosition.Y==0))
        local training,t=Training.new()
        local function teachingView()
            local v=Rules.view(training,"A");v.sessionId="training-geometry";v.mode="Training";v.training=Training.model(t)
            state.OnClientEvent.callback({view=v,started=true});task.wait(.1)
        end
        teachingView();inspect("TrainingBlock",label)
        assert(Training.apply(training,t,{kind="BlockCommit",blockerId="bai_ji",revision=training.revision}))
        assert(Training.apply(training,t,{kind="TrainingContinue",revision=training.revision}))
        local function formalView()
            local v=Rules.view(training,"A");v.sessionId="formal-geometry";v.mode="AI"
            state.OnClientEvent.callback({view=v,started=true});task.wait(.1)
        end
        local function visibleOption(message)
            local details=root.ActionRail.ActionDetails
            if not details.Visible then click("ActionDrawer") end
            details=root.ActionRail.ActionDetails
            local toggle=assert(find("Option:1"),"Missing formal skill option")
            check(label.." "..message,details.CanvasPosition.Y==0 and toggle.AbsolutePosition.Y>=details.AbsolutePosition.Y and toggle.AbsolutePosition.Y+toggle.AbsoluteSize.Y<=details.AbsolutePosition.Y+details.AbsoluteSize.Y+1)
        end
        formalView();click("Hero:A:bai_ji");inspect("FormalHealing",label)
        if find("ActionDrawer") then check(label.." formal healing does not require opening drawer",not root.ActionRail.ActionDetails.Visible) end
        check(label.." formal healing needs no enemy",not find("PrimaryAction"):GetAttribute("Disabled"))
        click("PrimaryAction");check(label.." formal healing sends real skill intent",sent[#sent].intent.kind=="SkillCast" and sent[#sent].intent.casterId=="bai_ji" and sent[#sent].intent.targetId==nil)
        formalView();click("Hero:A:lan_dun");check(label.." passive has no misleading cast control",find("Option:1")==nil);inspect("FormalPassive",label)
        formalView();click("Hero:A:ting_sun");check(label.." attack phase skill has no wrong timing cast control",find("Option:1")==nil);inspect("FormalAttackTiming",label)
        teachingView();inspect("TrainingSkill",label)
        check(label.." healing cannot be skipped in GUI",find("PrimaryAction"):GetAttribute("Disabled"))
        click("Hero:A:bai_ji")
        check(label.." selected healer enables main action",not find("PrimaryAction"):GetAttribute("Disabled"))
        inspect("TrainingSelectedSkill",label)
        assert(Training.apply(training,t,{kind="SkillCast",casterId="bai_ji",revision=training.revision}))
        teachingView();inspect("TrainingAfterSkill",label)
        assert(Training.apply(training,t,{kind="SkillEnd",revision=training.revision}))
        formalView();click("Hero:A:ting_sun");click("Hero:B:xuan_bao");visibleOption("formal attack skill visible without scrolling")
        click("Option:1");inspect("FormalAttackSkill",label);click("PrimaryAction")
        check(label.." formal attack submits enabled skill",sent[#sent].intent.kind=="AttackCommit" and sent[#sent].intent.useSkill==true and sent[#sent].intent.attackerId=="ting_sun")
        teachingView();click("Hero:A:ting_sun");click("Hero:B:xuan_bao")
        local details=root.ActionRail.ActionDetails
        if not details.Visible then click("ActionDrawer") end
        details=root.ActionRail.ActionDetails
        local toggle=find("Option:1")
        check(label.." training attack skill visible without scrolling",details.CanvasPosition.Y==0 and toggle.AbsolutePosition.Y>=details.AbsolutePosition.Y and toggle.AbsolutePosition.Y+toggle.AbsoluteSize.Y<=details.AbsolutePosition.Y+details.AbsoluteSize.Y+1)
        click("Option:1");inspect("TrainingAttackSkill",label)
        assert(Training.apply(training,t,{kind="AttackCommit",attackerId="ting_sun",targets={"xuan_bao"},useSkill=true,revision=training.revision}))
        teachingView();inspect("TrainingComplete",label)
        gui:Destroy();gui=nil
    end
end)
if gui then gui:Destroy() end
qa:Destroy()
if not ok then error(err) end
return game:GetService("HttpService"):JSONEncode({scope="Roblox battle/report GUI geometry with fake transport and prior terminal sample; no hardware input or visual/mobile acceptance",passed=#checks,scenes=scenes})
