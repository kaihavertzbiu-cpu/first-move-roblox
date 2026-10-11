-- Production rules + public projections; isolated fixtures, not a live match.
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local Story=require(modules.ReportStory)
local Match=require(game.ServerScriptService.DeadlockServer.MatchRules)
local Projection=require(game.ServerScriptService.DeadlockServer.PlayerProjection)
local defs=require(game.ReplicatedStorage.DeadlockShared.LegacyConfig)
local checks={}
local function check(label,ok) assert(ok,label);table.insert(checks,label) end
local function make(idsA,idsB)
 local s=Match.new();s.phase="SkillPhase";s.actor="A";s.actionOwner="A";s.initiative="A";s.turnSlot=1;s.round=1;s.draftStep=7;s.picksRemaining=0
 for side,ids in pairs({A=idsA,B=idsB}) do for _,id in ipairs(ids) do for _,d in ipairs(defs.heroes) do if d.id==id then table.insert(s.rosters[side],{id=id,hp=d.maxHp,maxHp=d.maxHp,atk=d.atk,cooldown=0,alive=true,used=false,statuses={}}) end end end end
 return s
end
local s=make({"yan_wei"},{"lan_dun"});s.rosters.B[1].hp=15
assert(Match.apply(s,"A",{kind="SkillCast",casterId="yan_wei",targetId="lan_dun",revision=s.revision}))
check("Existing core genuinely permits final sacrifice and rattle mutual destruction",s.phase=="GameOver" and s.winner=="Draw")
local v=Projection.view(s,"A");local before=game:GetService("HttpService"):JSONEncode(v)
local story=Story.build(v)
check("Mutual destruction has precise wording",story.title=="同归于尽" and story.subtitle:find("死亡连锁")~=nil)
check("Full sacrifice and rattle chain retained",#story.closing.steps==4 and story.closing.steps[1].kind=="Skill" and story.closing.steps[2].kind=="Death" and story.closing.steps[3].kind=="Damage" and story.closing.steps[4].kind=="Death")
check("Death rattle stays attributed to dead caster",story.closing.steps[3].side=="A" and story.closing.steps[3].unit=="yan_wei")
check("Final target has opponent ownership",story.closing.steps[4].side=="B")
local mirror=Story.build(Projection.view(s,"B"))
check("Mirrored report swaps sides without changing chronology",mirror.closing.steps[3].side=="B" and mirror.closing.steps[4].side=="A" and #mirror.closing.steps==4)
s=make({"ting_sun"},{"zhe_jing"})
assert(Match.apply(s,"A",{kind="SkillEnd",revision=s.revision}))
assert(Match.apply(s,"A",{kind="AttackCommit",attackerId="ting_sun",targets={"zhe_jing"},useSkill=true,revision=s.revision}))
story=Story.build(Projection.view(s,"A"))
check("Real execute victory uses execute summary",s.winner=="A" and story.closing.summary:find("处决")~=nil)
check("Execute timeline preserves skill execute death",#story.closing.steps==3 and story.closing.steps[2].kind=="Execute" and story.closing.steps[3].kind=="Death")
local sample={winner="B",round=2,rosters={A={{id="ting_sun"}},B={{id="huan_shi"}}},events={{kind="Damage",round=2,source="huan_shi",target="ting_sun",amount=7,effective=7,damageType="Normal"},{kind="Death",round=2,target="ting_sun",owner="A"}}}
story=Story.build(sample)
check("Truncated archive explicitly marked",story.closing.partial and #story.closing.steps==2)
check("Normal damage not called execution",not story.closing.summary:find("处决"))
local blocked={winner="A",round=1,rosters={A={{id="ting_sun"}},B={{id="zhe_jing"}}},events={{kind="AttackCommitted",owner="B",round=1},{kind="Block",source="zhe_jing",target="ting_sun",round=1},{kind="Damage",source="ting_sun",target="zhe_jing",damageType="Reflection",effective=4,round=1},{kind="Death",target="zhe_jing",owner="B",round=1}}}
story=Story.build(blocked)
check("Block belongs to protected unit not attacker",story.closing.steps[2].side=="A" and story.closing.steps[2].unit=="ting_sun")
check("No events avoids invented reconstruction",#Story.build({winner="A",round=1,events={}}).closing.steps==0)
check("Missing result never implies mutual destruction",Story.build({round=1,events={}}).title=="行动结束")
check("Public projection untouched",game:GetService("HttpService"):JSONEncode(v)==before)
return game:GetService("HttpService"):JSONEncode({scope="isolated real rules, terminal public projections and report story; no actual human or multiplayer play",passed=#checks,checks=checks})

