local Match=require(script.Parent.MatchRules)
local AI=require(script.Parent.StandardAI)
local Config=require(game:GetService("ReplicatedStorage").DeadlockShared.LegacyConfig)
local defs={};for _,h in ipairs(Config.heroes) do defs[h.id]=h end
return function()
    local count=0
    local function check(value,label) assert(value,"FIRST_MOVE_COMBAT: "..label);count+=1 end
    local function fixture(a,b)
        local state=Match.new();state.phase="SkillPhase";state.round=1;state.actor="A";state.actionOwner="A";state.initiative="A";state.turnSlot=1
        state.draftStep=7;state.picksRemaining=0
        for owner,ids in pairs({A=a,B=b}) do
            for _,id in ipairs(ids) do
                local h=defs[id];table.insert(state.rosters[owner],{id=id,hp=h.maxHp,maxHp=h.maxHp,atk=h.atk,cooldown=0,alive=true,used=false,statuses={}})
            end
        end
        return state
    end
    local function hero(state,id)
        for _,owner in ipairs({"A","B"}) do for _,h in ipairs(state.rosters[owner]) do if h.id==id then return h end end end
    end
    local function act(state,owner,kind,fields)
        fields=fields or {};fields.kind=kind;fields.revision=state.revision
        local ok,err=Match.apply(state,owner,fields);assert(ok,"FIRST_MOVE_COMBAT action "..kind..": "..tostring(err))
    end
    local function attack(state,id,targets,use,blocker)
        act(state,"A","SkillEnd");act(state,"A","AttackCommit",{attackerId=id,targets=targets,useSkill=use})
        if state.phase=="BlockSelect" then act(state,"B","BlockCommit",{blockerId=blocker}) end
    end
    local s=fixture({"ting_sun"},{"lan_dun","zhe_jing"})
    attack(s,"ting_sun",{"lan_dun"},false,"lan_dun")
    check(hero(s,"lan_dun").hp==26 and s.actor=="B","self block negates normal hit; second actor begins")
    s=fixture({"huan_shi"},{"lan_dun","zhe_jing"})
    attack(s,"huan_shi",{"lan_dun"},false,"lan_dun")
    check(hero(s,"lan_dun").hp==23,"unblockable attack still respects normal cap")
    s=fixture({"ting_sun","bai_ji"},{"zhe_jing","lan_dun"});hero(s,"ting_sun").hp=4
    attack(s,"ting_sun",{"zhe_jing"},false,nil)
    check(not hero(s,"ting_sun").alive and hero(s,"zhe_jing").hp==14,"surviving mirror reflects and kills attacker")
    s=fixture({"ting_sun"},{"zhe_jing"})
    attack(s,"ting_sun",{"zhe_jing"},true,nil)
    check(s.phase=="GameOver" and s.winner=="A" and hero(s,"ting_sun").hp==22,"execute skips normal damage/reflection; last defender auto resolves")
    s=fixture({"ting_sun","bai_ji"},{"lan_dun","zhe_jing"})
    attack(s,"ting_sun",{"lan_dun"},true,"lan_dun")
    check(hero(s,"ting_sun").cooldown==5 and hero(s,"lan_dun").alive,"blocked execute consumes cooldown")
    s=fixture({"beng_yue"},{"yan_wei","lan_dun"});hero(s,"yan_wei").hp=8
    attack(s,"beng_yue",{"yan_wei","lan_dun"},true,nil)
    check(s.phase=="DeathRattleChoice" and hero(s,"lan_dun").hp==26,"multi attack pauses before second segment")
    local rev=s.revision
    check(not Match.apply(s,"A",{kind="DeathRattleTarget",targetId="beng_yue",revision=rev}) and s.revision==rev,"wrong owner cannot resolve rattle")
    act(s,"B","DeathRattleTarget",{targetId="beng_yue"})
    check(hero(s,"beng_yue").hp==7 and hero(s,"lan_dun").hp==23 and hero(s,"beng_yue").cooldown==3,"rattle and remaining segment resolve once")
    s=fixture({"yan_wei","ye_ban","bai_ji"},{"lan_dun","zhe_jing","chi_guang"});hero(s,"lan_dun").hp=10
    s.link={owner="A",allyId="yan_wei",enemyId="zhe_jing",active=true}
    act(s,"A","SkillCast",{casterId="yan_wei",targetId="lan_dun"})
    check(not hero(s,"lan_dun").alive and not hero(s,"zhe_jing").alive and not s.link.active,"lethal rattle preserves originating death link continuation")
    s=fixture({"xuan_bao","bai_ji"},{"yan_wei","lan_dun"});hero(s,"yan_wei").hp=3
    hero(s,"yan_wei").statuses.bleeding=true;hero(s,"lan_dun").statuses.bleeding=true;s.phase="CoreSelection";s.actor=nil
    act(s,"A","CoreLock",{core="cyan"});act(s,"B","CoreLock",{core="purple"})
    check(s.phase=="DeathRattleChoice","bleeding death requests a target")
    act(s,"B","DeathRattleTarget",{targetId="xuan_bao"})
    check(hero(s,"lan_dun").hp==23 and s.phase=="SkillPhase" and s.actor=="A","bleeding resumes remaining targets and original actor")
    s=fixture({"zhui_lie"},{"yan_wei","lan_dun"});hero(s,"yan_wei").hp=8
    act(s,"A","SkillCast",{casterId="zhui_lie",targetId="yan_wei",secondTargetId="lan_dun"})
    check(s.phase=="DeathRattleChoice","final barrage pauses after first kill")
    act(s,"B","DeathRattleTarget",{targetId="zhui_lie"})
    check(hero(s,"lan_dun").hp==16 and hero(s,"zhui_lie").used,"final second resumes after rattle, bypasses normal cap")
    s=fixture({"zhui_lie"},{"lan_dun"});hero(s,"lan_dun").hp=8
    act(s,"A","SkillCast",{casterId="zhui_lie",targetId="lan_dun"})
    check(s.phase=="GameOver" and s.winner=="A","skill kill last enemy applies immediate victory")
    s=fixture({"yan_wei"},{"lan_dun"});hero(s,"lan_dun").hp=15
    act(s,"A","SkillCast",{casterId="yan_wei",targetId="lan_dun"})
    check(s.winner=="Draw","full simultaneous death chain produces draw")
    s=fixture({"chi_guang","bai_ji"},{"lan_dun","zhe_jing"})
    local revision=s.revision
    check(not Match.apply(s,"A",{kind="SkillCast",casterId="chi_guang",targetId="bai_ji",revision=revision}) and s.revision==revision and hero(s,"chi_guang").cooldown==0,"allied skill target rejected atomically")
    act(s,"A","SkillEnd");act(s,"A","AttackCommit",{attackerId="chi_guang",targets={"lan_dun"}})
    local view=Match.view(s,"B")
    check(view.ownAttack==nil and view.attack==nil and view.queue==nil and view.events[#view.events].source==nil,"attack intent and queue hidden from defender")
    s=fixture({"bai_ji","lan_dun"},{"zhe_jing","chi_guang"});hero(s,"lan_dun").hp=24
    act(s,"A","SkillCast",{casterId="bai_ji"})
    check(hero(s,"lan_dun").hp==26 and hero(s,"bai_ji").cooldown==3,"healing clamps to max")
    attack(s,"lan_dun",{"chi_guang"},false,nil)
    act(s,"B","SkillEnd");act(s,"B","AttackCommit",{attackerId="chi_guang",targets={"lan_dun"}});act(s,"A","BlockCommit",{blockerId="lan_dun"})
    check(s.round==2 and s.phase=="CoreSelection" and hero(s,"bai_ji").cooldown==2,"round end decrements newly used cooldown")
    -- Complete public-view-only games: catches deadlocks and illegal AI intents.
    local reports={}
    for seed=1,30 do
        local gameState=Match.new();local rng=Random.new(seed);local steps=0
        check(Match.view(gameState,"A").report==nil,"report unavailable before terminal")
        while gameState.phase~="GameOver" and steps<2500 do
            local owner=gameState.phase=="CoreSelection" and (gameState.cores.A and "B" or "A") or (gameState.phase=="Draft" and Config.draft[gameState.draftStep].player or gameState.actor or gameState.linkOwner)
            local intent=AI.intent(Match.view(gameState,owner),owner,rng)
            check(intent~=nil,"AI has legal phase intent seed "..seed)
            local ok,err=Match.apply(gameState,owner,intent)
            check(ok,"AI intent accepted seed "..seed..": "..tostring(err))
            steps+=1
            for _,side in ipairs({"A","B"}) do for _,h in ipairs(gameState.rosters[side]) do check(h.hp>=0 and h.hp<=h.maxHp and h.alive==(h.hp>0),"health invariant") end end
        end
        check(gameState.phase=="GameOver","seed "..seed.." finishes without timeout")
        local report=Match.view(gameState,"A").report
        check(report.winner==gameState.winner and report.finalRound==gameState.round,"report describes terminal result")
        check(report.completedRounds==gameState.round-1,"partial final round excluded from completed count")
        for _,side in ipairs({"A","B"}) do
            local sum=0;for _,row in ipairs(report.rounds) do sum+=row.teams[side].damage end
            check(sum==report.teams[side].damage,"round damage reconciles with team total")
        end
        table.insert(reports,{seed=seed,rounds=gameState.round,winner=gameState.winner,steps=steps})
    end
    print("FIRST_MOVE_COMBAT: "..count.." assertions passed; 30/30 public-view self-play matches completed")
    print("FIRST_MOVE_REGRESSION: "..game:GetService("HttpService"):JSONEncode(reports))
    return count
end
