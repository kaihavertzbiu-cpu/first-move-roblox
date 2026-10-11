-- Shipping rules/schema and an isolated DataService transport; no cloud writes.
local modules=game.ServerScriptService.DeadlockServer
local Training=require(modules.TrainingMatch)
local Schema=require(modules.ProfileSchema)
local checks={}
local function check(name,value) assert(value,name);table.insert(checks,name) end
local state,t=Training.new()
local function act(kind,fields)
    fields=fields or {};fields.kind=kind;fields.revision=state.revision
    return Training.apply(state,t,fields)
end
check("Training starts with real concealed attack",state.phase=="BlockSelect" and state.actor=="A")
local ok,result=act("BlockCommit",{blockerId="lan_dun"})
check("Wrong block gives retry feedback",ok and result=="BlockChosen" and Training.model(t).feedback=="miss")
local revision=state.revision
ok,result=act("TrainingRetry");check("Failed scenario can restart",ok and result=="Retry")
state,t=Training.new(revision+1)
check("Retry revision never rolls back",state.revision>revision)
check("Old choice cannot replay after retry",not Training.apply(state,t,{kind="BlockCommit",revision=revision,blockerId="bai_ji"}))
ok,result=act("BlockCommit",{blockerId="bai_ji"})
check("Correct block is established by rule event",ok and result=="BlockRead" and Training.model(t).feedback=="success")
local unharmed;for _,h in ipairs(state.rosters.A) do if h.id=="bai_ji" then unharmed=h.hp==h.maxHp end end
check("Successful block preserves support HP",unharmed)
check("Feedback cannot bypass continue",not act("SkillEnd"))
check("Continue starts player skill window",act("TrainingContinue") and state.phase=="SkillPhase" and state.actor=="A")
check("Recovery exercise exposes actual injured ally",state.rosters.A[1].id=="lan_dun" and state.rosters.A[1].hp==23)
local skillRevision=state.revision
check("Training cannot skip the recovery lesson",not act("SkillEnd") and state.revision==skillRevision)
check("Wrong skill caster is rejected atomically",not act("SkillCast",{casterId="ting_sun"}) and state.revision==skillRevision)
check("Real heal unlocks attack lesson",act("SkillCast",{casterId="bai_ji"}) and t.skillUsed and Training.model(t).step==3)
local healed,cooldown=false,false
for _,h in ipairs(state.rosters.A) do if h.id=="lan_dun" then healed=h.hp==26 elseif h.id=="bai_ji" then cooldown=h.cooldown==3 end end
check("Healing and cooldown use shipping values",healed and cooldown)
check("Skill did not consume the attack opportunity",state.phase=="SkillPhase" and state.actor=="A")
check("Shipping skill window can finish",act("SkillEnd") and state.phase=="AttackSelect")
ok,result=act("AttackCommit",{attackerId="lan_dun",targets={"xuan_bao"},useSkill=false})
check("Attack and preset defense resolve through rules",ok and result=="AttackCommitted" and Training.model(t).complete)
check("Completed training rejects more attacks",not act("AttackCommit",{attackerId="lan_dun",targets={"xuan_bao"}}))
local old=Schema.new();old.tutorialComplete=true;old.stats.gamesPlayed=2
local p=Schema.normalize(old)
check("Old match flag does not fake learned training",not p.tutorialComplete and p.firstMatchCompleted and p.stats.gamesPlayed==2)
p=Schema.apply(p,{kind="Learning",step="blockChosen"})
check("Wrong block alone cannot complete training",not p.tutorialComplete)
p=Schema.apply(p,{kind="Learning",step="blockRead"});p=Schema.apply(p,{kind="Learning",step="attackCommitted"})
check("Both demonstrated steps complete learning",p.tutorialComplete and p.stats.gamesPlayed==2 and #p.history==0)
p=Schema.apply(p,{kind="Learning",step="skillUsed"})
check("Additional skill learning is saved without a match",p.learning.skillUsed and p.stats.gamesPlayed==2 and #p.history==0)
local prior=Schema.new();prior.learning.blockRead=true;prior.learning.attackCommitted=true;prior.learning.skillUsed=nil
check("Existing graduated players keep progress without fake skill proof",Schema.normalize(prior).tutorialComplete and not Schema.normalize(prior).learning.skillUsed)
local future={schemaVersion=99,unknown={precious="preserve"}}
check("Unsupported versions are read only",not Schema.writable(future) and not Schema.writable({schemaVersion=0}) and not Schema.writable("bad"))
check("Schema operations preserve future fields",Schema.apply(future,{kind="Settings",settings={master=0}}).unknown.precious=="preserve")
check("Malformed match operation fails closed",Schema.apply(p,{kind="Match"}).stats.gamesPlayed==2)

local function storageScenario(initial,changeAfterLoad)
    local raw=Schema.copy(initial);local writes=0;local cancelled=0;local tasks={};local updates={}
    local player={UserId=123,Parent=true}
    local function signal() return {Connect=function(self,fn) self.callback=fn end} end
    local players={PlayerAdded=signal(),PlayerRemoving=signal(),GetPlayers=function() return {player} end}
    local fakeStore={GetAsync=function() return Schema.copy(raw) end,UpdateAsync=function(_,_,transform)
        writes+=1;local value=transform(Schema.copy(raw));if value==nil then cancelled+=1 else raw=Schema.copy(value) end;return Schema.copy(raw)
    end}
    local fakeGame={ReplicatedStorage={},GetService=function(_,name)
        if name=="Players" then return players end
        if name=="RunService" then return {IsStudio=function() return false end} end
        if name=="DataStoreService" then return {GetDataStore=function() return fakeStore end} end
        error(name)
    end,BindToClose=function() end}
    local fakeTask={spawn=function(fn,...) table.insert(tasks,{fn=fn,args=table.pack(...)}) end,delay=function() end,defer=function() end,wait=function() return false end}
    local fakeInstance={new=function() return {FireClient=function(_,_,packet) table.insert(updates,packet) end} end}
    local factory=assert(loadstring("local game,Instance,task,script,require=...\n"..modules.DataService.Source))
    local service=factory(fakeGame,fakeInstance,fakeTask,{Parent=modules},function() return Schema end)
    service.start()
    for _,job in ipairs(tasks) do job.fn(table.unpack(job.args,1,job.args.n)) end
    if changeAfterLoad then raw=Schema.copy(changeAfterLoad) end
    service.learning(player,"blockRead");service.learning(player,"attackCommitted");service.flush(player)
    return raw,writes,cancelled,updates[#updates],service.profile(player)
end
local raw,writes,cancelled,packet,profile=storageScenario(future)
check("Future profile never enters write queue",writes==0 and raw.schemaVersion==99 and raw.unknown.precious=="preserve")
check("Client receives explicit read only status",packet.storage.status=="ReadOnly")
raw,writes,cancelled,packet=storageScenario(Schema.new(),future)
check("Concurrent version upgrade cancels UpdateAsync",writes==1 and cancelled==1 and raw.unknown.precious=="preserve" and packet.storage.status=="ReadOnly")
raw,writes,cancelled,packet,profile=storageScenario(Schema.new())
check("Learning writes merge without competitive results",writes==1 and cancelled==0 and raw.tutorialComplete and raw.stats.gamesPlayed==0 and #raw.history==0 and packet.storage.status=="Saved")
return game:GetService("HttpService"):JSONEncode({scope="isolated shipping training/schema/storage contracts; no cloud or GUI proof",passed=#checks,checks=checks})
