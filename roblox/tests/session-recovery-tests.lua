-- Isolated server contract test. Uses shipping MatchService source and rules;
-- fake transport/players prevent writes or actions in an active game.
local modules=game.ServerScriptService.DeadlockServer
local Rules=require(modules.MatchRules)
local Projection=require(modules.PlayerProjection)
local Config=require(game.ReplicatedStorage.DeadlockShared.LegacyConfig)
local clock=0
local messages={};local checks={};local completeCount=0
local function check(name,value) assert(value,name);table.insert(checks,name) end
local function signal() return {Connect=function(self,fn) self.callback=fn end} end
local fakePlayers={PlayerRemoving=signal()}
local intent,stateEvent
local fakeInstance={new=function(class)
    local obj={OnServerEvent=signal()}
    function obj:FireClient(player,packet) messages[player]=messages[player] or {};table.insert(messages[player],packet) end
    if class=="RemoteEvent" then if not intent then intent=obj else stateEvent=obj end end
    return obj
end}
local fakeGame={GetService=function(_,name)
    if name=="Players" then return fakePlayers end
    if name=="ReplicatedStorage" then return {DeadlockShared={AIConfig="AIConfig"}} end
    if name=="HttpService" then return game:GetService(name) end
    error("Unexpected service "..name)
end}
local fakeData={profile=function() return {stats={gamesPlayed=1}} end,complete=function() completeCount+=1 end,learning=function() end}
local stateOverride
local ruleFactory={apply=Rules.apply,view=Rules.view,new=function() if stateOverride then local s=stateOverride;stateOverride=nil;return s end;return Rules.new() end}
local dependencies={[modules.MatchRules]=ruleFactory,[modules.TrainingMatch]=require(modules.TrainingMatch),[modules.PlayerProjection]=Projection,[modules.DataService]=fakeData,[modules.AIDirector]={intent=function() return nil end},AIConfig={Standard={think=.75},Advanced={think=.75}}}
local fakeRequire=function(key) return assert(dependencies[key],"Unexpected require") end
local fakeWorkspace={SetAttribute=function() end}
local factory=assert(loadstring("local game,Instance,task,script,require,workspace,os=...\n"..modules.MatchService.Source))
local service=factory(fakeGame,fakeInstance,{delay=function() end},{Parent=modules},fakeRequire,fakeWorkspace,{clock=function() return clock end})
service.start()
local p1={Name="TestA",Parent=true};local p2={Name="TestB",Parent=true}
local function send(p,msg) clock+=1;intent.OnServerEvent.callback(p,msg) end
local function latest(p) local list=messages[p] or {};return list[#list] end
local function count(p) return #(messages[p] or {}) end
send(p1,{command="Start",mode="PvP"});check("First player queues",latest(p1).queued==true)
send(p2,{command="Start",mode="PvP"});local id=latest(p1).view.sessionId
check("Both players share session",latest(p2).view.sessionId==id)
local before=latest(p1).view
send(p1,{command="Sync",sessionId=id})
check("Sync acknowledges recovery",latest(p1).synced==true and latest(p1).ack==false)
check("Sync leaves revision unchanged",latest(p1).view.revision==before.revision)
send(p1,{command="Start",mode="PvP"})
check("Retry Start reuses session",latest(p1).view.sessionId==id and latest(p1).started)
local n=count(p1);send(p1,{command="Sync",sessionId="wrong"});check("Wrong session Sync rejected",count(p1)==n)
local picked=0
for _,hero in ipairs(Config.heroes) do if hero.id~="ye_ban" and picked<10 then
    local v=latest(p1).view;local player=v.actor=="A" and p1 or p2
    send(player,{command="Action",sessionId=id,intent={kind="DraftPick",heroId=hero.id,revision=v.revision}})
    check("Draft action "..(picked+1).." accepted",latest(player).error==nil and latest(player).ack==true)
    picked+=1
end end
check("Draft enters secret core phase",latest(p1).view.phase=="CoreSelection")
local r=latest(p1).view.revision
send(p1,{command="Action",sessionId=id,intent={kind="CoreLock",core="cyan",revision=r}})
local after=latest(p1).view
send(p2,{command="Sync",sessionId=id})
check("Sync does not disclose opponent core",latest(p2).view.ownCore==nil and latest(p2).view.cores==nil and latest(p2).view.coreLocked.B==true)
check("Sync preserves same core window",latest(p2).view.phase=="CoreSelection" and latest(p2).view.revision==after.revision)
send(p2,{command="Action",sessionId=id,intent={kind="CoreLock",core="red",revision=r}})
check("Concurrent core selection still resolves",latest(p1).view.phase~="CoreSelection" and latest(p2).error==nil)
local v=latest(p1).view;local n1,n2=count(p1),count(p2)
send(p1,{command="Sync",sessionId=id});send(p1,{command="Sync",sessionId=id})
check("Repeated Sync has no action replay",latest(p1).view.revision==v.revision and #latest(p1).view.events==#v.events and count(p2)==n2)
send(p1,{command="Quit",sessionId="wrong"});check("Wrong Quit cannot close live match",latest(p1).closed~=true)
send(p1,{command="Quit"})
check("Quit without lost session ID closes sender",latest(p1).closed==true and not latest(p1).abandoned)
check("Opponent receives cancellation",latest(p2).closed==true and latest(p2).abandoned==true)
check("Cancellation does not record completion",completeCount==0)
send(p1,{command="Start",mode="PvP"});send(p1,{command="Quit"});send(p2,{command="Start",mode="PvP"})
check("Queue cancel cannot create ghost opponent",latest(p2).queued==true)
send(p2,{command="Quit"});check("Queue cancel works without session ID",latest(p2).closed==true)
send(p1,{command="Start",mode="PvP"});send(p1,{command="Start",mode="PvP"})
check("Queued Start retry is idempotent",latest(p1).queued==true)
send(p1,{command="Start",mode="AI",difficulty="Standard"})
check("Queue switches atomically to AI draft",latest(p1).view.mode=="AI" and latest(p1).view.phase=="Draft")
send(p2,{command="Start",mode="PvP"})
check("AI switch leaves no ghost queue opponent",latest(p2).queued==true and latest(p1).view.mode=="AI")
send(p1,{command="Quit"});send(p1,{command="Start",mode="PvP"})
local pairedId=latest(p1).view.sessionId
send(p1,{command="Start",mode="AI",difficulty="Standard"})
check("Already paired switch retains real PvP session",latest(p1).view.sessionId==pairedId and latest(p1).view.mode=="PvP" and latest(p2).view.sessionId==pairedId)
send(p1,{command="Quit"});send(p2,{command="Start",mode="PvP"})
check("Repeated queue retry did not leave duplicate waiting entry",latest(p2).queued==true)
send(p2,{command="Quit"})
-- A terminal fixture exercises restart transport; actual play is separate acceptance.
stateOverride=Rules.new();stateOverride.phase="GameOver";stateOverride.winner="A"
send(p1,{command="Start",mode="AI",difficulty="Standard"});local old=latest(p1).view.sessionId
check("Terminal fixture records completion once",completeCount==1)
send(p1,{command="Sync",sessionId=old});check("Terminal sync cannot duplicate record",completeCount==1)
send(p1,{command="Restart",sessionId=old,extra=true});check("Malformed restart rejected",latest(p1).error=="InvalidRequest" and latest(p1).view.sessionId==old)
send(p1,{command="Restart",sessionId=old});local nextId=latest(p1).view.sessionId
check("Restart creates independent fresh AI draft",nextId~=old and latest(p1).view.phase=="Draft" and latest(p1).started)
check("Restart preserves difficulty without duplicate result",latest(p1).view.difficulty=="Standard" and completeCount==1)
local nRestart=count(p1);send(p1,{command="Restart",sessionId=old})
check("Old repeated restart cannot replace new match",count(p1)==nRestart)
send(p1,{command="Restart",sessionId=nextId});check("Unfinished match cannot restart",latest(p1).error=="WrongPhase" and latest(p1).view.sessionId==nextId)
send(p1,{command="Quit"});send(p1,{command="Start",mode="Training"});check("Training uses separate mode",latest(p1).view.mode=="Training" and latest(p1).view.training.step==1)
send(p1,{command="Quit"});check("Training cancellation cannot record a match",completeCount==1)
send(p1,{command="Start",mode="PvP"})
stateOverride=Rules.new();stateOverride.phase="GameOver";stateOverride.winner="A"
send(p2,{command="Start",mode="PvP"});local pvpId=latest(p1).view.sessionId
check("Both terminal PvP players may invite rematch",latest(p1).view.rematch.available and latest(p2).view.rematch.available and completeCount==3)
send(p1,{command="Restart",sessionId=pvpId,accept=true})
check("One consent cannot force a new match",latest(p1).view.sessionId==pvpId and latest(p1).view.rematch.requested and latest(p2).view.rematch.opponentRequested)
send(p1,{command="Restart",sessionId=pvpId,accept=true})
check("Repeated consent remains idempotent",latest(p1).view.rematch.requested and completeCount==3)
send(p1,{command="Restart",sessionId=pvpId,accept=false});check("Invitation may be withdrawn",not latest(p1).view.rematch.requested and not latest(p2).view.rematch.opponentRequested)
send(p1,{command="Restart",sessionId=pvpId,accept=true});send(p2,{command="Restart",sessionId=pvpId,accept=true})
check("Mutual consent creates shared fresh session",latest(p1).view.sessionId~=pvpId and latest(p1).view.sessionId==latest(p2).view.sessionId and latest(p1).view.phase=="Draft")
check("Rematch swaps first draft side",latest(p1).view.actor=="B" and latest(p2).view.actor=="A")
check("PvP rematch never duplicates prior result",completeCount==3)
send(p1,{command="Quit"});send(p1,{command="Start",mode="PvP"})
stateOverride=Rules.new();stateOverride.phase="GameOver";stateOverride.winner="A";send(p2,{command="Start",mode="PvP"})
send(p1,{command="Quit"});check("Finished opponent departure refreshes rematch availability",latest(p2).view.phase=="GameOver" and latest(p2).view.rematch.available==false)
return game:GetService("HttpService"):JSONEncode({scope="isolated shipping server contract; no actual GUI input",passed=#checks,checks=checks})
