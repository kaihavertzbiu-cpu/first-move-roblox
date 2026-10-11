-- Deterministic scheduler verifies shipping presentation order/cancellation.
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local config=require(modules.PresentationConfig)
local checks={};local jobs={};local played={};local presented={};local camera={Reduced=false};local outcomes=0;local callbacks=0
local function check(name,value) assert(value,name);table.insert(checks,name) end
local audio={Reset=function() end,Play=function(cue) table.insert(played,cue) end,Outcome=function() outcomes+=1 end}
camera.Set=function(screen) camera.screen=screen end;camera.Resolve=function() end
local dependencies={[modules.AudioController]=audio,[modules.CameraController]=camera,[modules.TableController]={present=function(event) table.insert(presented,event.kind) end},[modules.PresentationConfig]=config}
local results=0;dependencies[modules.MusicController]={Update=function() end,Result=function() results+=1 end}
local accents={};local outcomeAccents=0;local outcomeEffects=0
dependencies[modules.ImpactPresentation]={bind=function() end,reset=function() end,present=function(e) table.insert(accents,table.clone(e)) end,outcome=function() outcomeAccents+=1 end}
dependencies[modules.TableController].outcome=function() outcomeEffects+=1 end
local scheduler={defer=function(fn) table.insert(jobs,{fn=fn,delay=0}) end,delay=function(delay,fn) table.insert(jobs,{fn=fn,delay=delay}) end}
local director=assert(loadstring("local script,require,task=...\n"..modules.PresentationDirector.Source))({Parent=modules},function(k) return assert(dependencies[k]) end,scheduler)
local function changed() callbacks+=1 end
local function drain() local total=0;while #jobs>0 do local job=table.remove(jobs,1);total+=job.delay;job.fn() end;return total end
local view={sessionId="first",phase="BlockSelect",events={{kind="CoreReveal"}}}
director.update(view,changed);check("Joining does not replay historical events",#jobs==0 and #played==0)
for _,kind in ipairs({"Damage","Death","LinkTrigger","Death"}) do table.insert(view.events,{kind=kind}) end
view.phase="GameOver";view.winner="A";director.update(view,changed)
check("Terminal waits for public event sequence",director.resolving() and outcomes==0 and camera.screen=="Battle")
director.update(view,changed);drain()
check("Damage death link death retain server order",table.concat(presented,",")=="Damage,Death,LinkTrigger,Death")
check("Re-sync does not duplicate presentation",#presented==4 and #played==4)
check("Outcome follows final event once",outcomes==1 and camera.screen=="Result" and callbacks==1 and not director.resolving())
director.update(view,changed);drain();check("Repeated terminal has no repeated outcome",outcomes==1)
director.reset();view={sessionId="second",phase="AttackSelect",events={}};director.update(view,changed)
table.insert(view.events,{kind="Block"});director.update(view,changed);director.reset();local before=#presented;drain()
check("Exit cancels deferred old session effects",#presented==before and not director.resolving())
view={sessionId="retry",phase="BlockSelect",events={}};director.update(view,changed)
table.insert(view.events,{kind="Damage"});director.update(view,changed)
view.events={};director.update(view,changed);before=#presented;drain()
check("Training retry cancels prior attempt effects",#presented==before and not director.resolving())
camera.Reduced=true;view={sessionId="third",phase="SkillPhase",events={}};director.update(view,changed)
table.insert(view.events,{kind="Block"});director.update(view,changed)
check("Reduced motion keeps semantic block feedback",drain()<=config.Resolution.MinimumStep+.001 and presented[#presented]=="Block")
camera.Reduced=false;view={sessionId="signature",phase="SkillPhase",events={}};director.update(view,changed)
played={};local notifications={}
for _,e in ipairs({{kind="Execute"},{kind="Death"},{kind="LinkTrigger"},{kind="Damage",damageType="Reflection"},{kind="Damage",damageType="Bleeding"},{kind="Heal"}}) do table.insert(view.events,e) end
director.update(view,changed,function(e,hold,index) table.insert(notifications,{kind=e.kind,hold=hold,index=index}) end);drain()
check("Special events use distinct audio signatures",table.concat(played,",")=="execute,death,link,reflect,bleed,heal")
check("HUD receives the same public event order",#notifications==6 and notifications[3].kind=="LinkTrigger" and notifications[3].index==3)
check("Execution and link have dedicated readable holds",notifications[1].hold==config.Resolution.Execute and notifications[3].hold==config.Resolution.Link)
check("Result music waits for final sequence",results==1)
check("Terminal shows one cinematic accent and spatial outcome",outcomeAccents==1 and outcomeEffects==1)
view={sessionId="skills",phase="SkillPhase",events={}};director.update(view,changed)
local events={{kind="Skill",source="beng_yue",code="fury_press"},{kind="Damage",source="beng_yue",target="x",damageType="Normal"},{kind="RoundEnd"},{kind="Damage",source="beng_yue",target="x",damageType="Normal"},{kind="Execute",source="ting_sun",target="x"},{kind="Death",target="x",owner="B"}}
for _,e in ipairs(events) do table.insert(view.events,e) end
accents={};director.update(view,changed);drain()
check("Revealed skill enriches only that action's hit",accents[2].skillCode=="fury_press" and accents[3].skillCode==nil)
check("Public execution marks the subsequent death",accents[5].cause=="Execute")
check("Shipping public event payloads remain untouched",events[2].skillCode==nil and events[6].cause==nil)
view.phase="GameOver";view.winner="B";director.update(view,changed)
while outcomes<2 and #jobs>0 do table.remove(jobs,1).fn() end
check("Cinematic beat keeps report pending until completion",director.resolving() and outcomes==2)
local priorCallbacks=callbacks;director.reset();drain()
check("Exit during outcome cancels delayed report transition",callbacks==priorCallbacks and not director.resolving())
view={sessionId="chain",phase="SkillPhase",events={}};director.update(view,changed);accents={};played={}
for _,event in ipairs({{kind="ActionStart",owner="A"},{kind="Death",target="yan_wei",owner="A"},{kind="Damage",source="yan_wei",target="xuan_bao",damageType="DeathRattle"},{kind="Death",target="xuan_bao",owner="B"}}) do table.insert(view.events,event) end
director.update(view,changed);director.update(view,changed);drain()
check("Own sacrifice does not count as an enemy kill",accents[1].actionDeaths==1 and accents[3].actionDeaths==1 and played[3]=="death")
table.insert(view.events,{kind="Execute",source="ting_sun",target="zhe_jing"});table.insert(view.events,{kind="Death",target="zhe_jing",owner="B"})
director.update(view,changed);drain()
check("Same-action second kill has a distinct accent",accents[#accents].actionDeaths==2 and played[#played]=="chain")
check("Same-action execution retains public cause",accents[#accents].cause=="Execute")
table.insert(view.events,{kind="RoundEnd"});table.insert(view.events,{kind="ActionStart",owner="A"});table.insert(view.events,{kind="Death",owner="B",target="huan_shi"})
director.update(view,changed);drain()
check("A new action starts a fresh kill count",accents[#accents].actionDeaths==1 and played[#played]=="death")
view={sessionId="joining-chain",phase="SkillPhase",events={{kind="ActionStart"},{kind="Death",owner="B",target="first"}}};director.update(view,changed)
local oldCount=#accents;table.insert(view.events,{kind="Death",owner="B",target="second"});director.update(view,changed);drain()
check("Mid-action joining seeds public count without historical replay",#accents==oldCount+1 and accents[#accents].actionDeaths==2)
view={sessionId="voices",phase="SkillPhase",events={}};director.update(view,changed);played={}
for _,code in ipairs({"group_heal","stasis_lock","thunder_judgment","rail_shot","fury_press","final_barrage","overload_explode"}) do table.insert(view.events,{kind="Skill",source=code,code=code}) end
director.update(view,changed);drain()
check("All seven active skills select their own sound profile",table.concat(played,",")=="cast_heal,cast_lock,cast_execute,cast_rail,cast_maul,barrage,cast_overload")
view={sessionId="impact-tiers",phase="SkillPhase",events={}};director.update(view,changed);played={}
for _,e in ipairs({
 {kind="Damage",damageType="Normal",amount=4,effective=4},
 {kind="Damage",damageType="Normal",amount=8,effective=8},
 {kind="Damage",damageType="Skill",amount=15,effective=15},
 {kind="Damage",damageType="Normal",amount=15,effective=1},
 {kind="Damage",damageType="Bleeding",amount=15,effective=15},
 {kind="Damage",damageType="Reflection",amount=15,effective=15}
})do table.insert(view.events,e)end
director.update(view,changed);drain()
check("Actual damage controls tier; overkill and passive damage do not inflate impact",
 table.concat(played,",")=="hit,hit_heavy,hit_crushing,hit,bleed,reflect")
check("Tier annotation does not mutate public events",view.events[3].impactTier==nil)
camera.Reduced=false
view={sessionId="contact-timeline",phase="AttackSelect",events={},rosters={A={{id="source",hp=20,maxHp=20,alive=true}},B={{id="victim",hp=12,maxHp=12,alive=true}}}}
director.update(view,changed)
view.rosters.B[1]={id="victim",hp=0,maxHp=12,alive=false}
view.events={{kind="Damage",damageType="Normal",source="source",target="victim",amount=12,effective=12},{kind="Death",target="victim",owner="B"}}
local contacts={}
played={}
director.update(view,changed,function(e)table.insert(contacts,{kind=e.kind,hp=e.presentedHp,alive=e.presentedAlive})end)
check("Incoming terminal HP stays hidden until contact",director.hero(view.rosters.B[1]).hp==12 and director.hero(view.rosters.B[1]).alive)
table.remove(jobs,1).fn()
check("Windup has no hit sound or early HP change",#played==0 and director.hero(view.rosters.B[1]).hp==12)
table.remove(jobs,1).fn()
check("Contact synchronizes sound and actual HP",played[1]=="hit_crushing" and contacts[1].hp==0 and contacts[1].alive and director.hero(view.rosters.B[1]).hp==0)
drain()
check("Death commits after hit, then final state matches server",contacts[2].kind=="Death" and contacts[2].alive==false and director.hero(view.rosters.B[1]).alive==false)
view={sessionId="cancel-contact",phase="AttackSelect",events={}};director.update(view,changed)
view.events={{kind="Damage",source="source",target="victim",amount=8,effective=8,damageType="Normal"}}
director.update(view,changed);table.remove(jobs,1).fn();local playedBefore=#played;director.reset();drain()
check("Exit during windup cancels delayed hit",#played==playedBefore)

return game:GetService("HttpService"):JSONEncode({scope="isolated shipping presentation queue with deterministic scheduler; no subjective audio proof",passed=#checks,checks=checks})
