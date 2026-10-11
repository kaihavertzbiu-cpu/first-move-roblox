-- Server authority. Pending choices keep the remaining event queue, never replay a snapshot.
local Config = require(game:GetService("ReplicatedStorage").DeadlockShared.LegacyConfig)
local Combat = {}
local defs = {}
for _, h in ipairs(Config.heroes) do defs[h.id]=h end
local function other(owner) return owner == "A" and "B" or "A" end
local function get(state,id)
    for _,owner in ipairs({"A","B"}) do
        for _,h in ipairs(state.rosters[owner]) do if h.id==id then return h,owner end end
    end
end
local function living(state,owner)
    local result={}
    for _,h in ipairs(state.rosters[owner]) do if h.alive then table.insert(result,h) end end
    return result
end
local function emit(state,kind,data)
    data=data or {};data.kind=kind;data.round=state.round
    table.insert(state.events,data)
end
local function prepend(state,events)
    for i=#events,1,-1 do table.insert(state.queue,1,events[i]) end
end
local function checkWin(state)
    local a,b=#living(state,"A"),#living(state,"B")
    if a>0 and b>0 then return false end
    state.phase="GameOver";state.actor=nil;state.pending=nil;state.attack=nil
    state.winner=a==0 and b==0 and "Draw" or (a>0 and "A" or "B")
    emit(state,"GameOver",{winner=state.winner})
    return true
end
local drain
local function startAction(state,owner)
    state.actor=owner;state.actionOwner=owner;state.phase="Resolving";state.resume="SkillPhase";state.queue={}
    emit(state,"ActionStart",{owner=owner})
    local source=get(state,"xuan_bao")
    if source and source.alive then
        local _,sourceOwner=get(state,"xuan_bao")
        if sourceOwner==owner then
            for _,h in ipairs(living(state,other(owner))) do
                if h.statuses.bleeding then table.insert(state.queue,{kind="Damage",target=h.id,source=source.id,amount=Config.damage.bleeding,damageType="Bleeding"}) end
            end
        end
    end
    drain(state)
end
local function finishAction(state)
    local owner=state.actionOwner
    for _,h in ipairs(state.rosters[owner]) do h.statuses.blocked=nil end
    state.attack=nil
    if state.turnSlot==1 then
        state.turnSlot=2
        startAction(state,other(state.initiative))
    else
        for _,side in ipairs({"A","B"}) do
            for _,h in ipairs(state.rosters[side]) do if h.alive then h.cooldown=math.max(0,h.cooldown-1) end end
        end
        emit(state,"RoundEnd")
        state.round+=1;state.cores={};state.phase="CoreSelection";state.actor=nil
    end
end
local function death(state,event)
    local h,owner=get(state,event.target)
    if not h or not h.alive then return end
    h.hp=0;h.alive=false
    emit(state,"Death",{target=h.id,owner=owner})
    local nextEvents={}
    if h.id=="yan_wei" then table.insert(nextEvents,{kind="Rattle",source=h.id,owner=owner,target=event.rattleTarget}) end
    -- Keep this continuation even if the rattle pauses or kills another unit.
    table.insert(nextEvents,{kind="Link",target=h.id,owner=owner})
    prepend(state,nextEvents)
end
local function damage(state,event)
    local target=get(state,event.target)
    if not target or not target.alive then return end
    local amount=event.amount
    if event.damageType=="Normal" then
        local attacker=get(state,event.source)
        if not attacker or not attacker.alive then return end
        if event.blocker==target.id and attacker.id~="huan_shi" then
            emit(state,"Block",{source=attacker.id,target=target.id})
            return
        end
        if event.execute then
            emit(state,"Execute",{source=attacker.id,target=target.id})
            target.hp=0;prepend(state,{{kind="Death",target=target.id}});return
        end
        if target.id=="lan_dun" then amount=math.min(amount,Config.normalDamageCap) end
        if attacker.id=="xuan_bao" then target.statuses.bleeding=true end
    end
    local effective=math.min(target.hp,amount)
    target.hp=math.max(0,target.hp-amount)
    emit(state,"Damage",{source=event.source,target=target.id,amount=amount,effective=effective,damageType=event.damageType})
    if target.hp==0 then prepend(state,{{kind="Death",target=target.id,rattleTarget=event.rattleTarget}})
    elseif event.damageType=="Normal" and target.id=="zhe_jing" then
        prepend(state,{{kind="Damage",source=target.id,target=event.source,amount=Config.damage.reflection,damageType="Reflection"}})
    end
end
drain=function(state)
    while #state.queue>0 do
        local event=table.remove(state.queue,1)
        if event.kind=="Damage" then damage(state,event)
        elseif event.kind=="Death" then death(state,event)
        elseif event.kind=="Link" then
            local link=state.link
            if link and link.active and link.owner==event.owner and link.allyId==event.target then
                link.active=false
                emit(state,"LinkTrigger",{source=event.target,target=link.enemyId})
                prepend(state,{{kind="Death",target=link.enemyId}})
            end
        elseif event.kind=="Rattle" then
            local enemies=living(state,other(event.owner))
            if #enemies>0 then
                local target,targetOwner=get(state,event.target)
                if target and target.alive and targetOwner~=event.owner then
                    prepend(state,{{kind="Damage",source=event.source,target=target.id,amount=Config.damage.deathRattle,damageType="DeathRattle"}})
                else
                    state.pending={owner=event.owner,source=event.source}
                    state.phase="DeathRattleChoice";state.actor=event.owner
                    return
                end
            end
        elseif event.kind=="FinalSecond" then
            local first=get(state,event.first)
            if first and not first.alive and event.target then
                prepend(state,{{kind="Damage",source=event.source,target=event.target,amount=Config.damage.finalSecond,damageType="Skill"}})
            end
        end
    end
    if checkWin(state) then return end
    if state.resume=="AfterAttack" then finishAction(state)
    else state.phase=state.resume;state.actor=state.actionOwner or state.actor end
end
function Combat.beginRound(state)
    state.turnSlot=1;state.actionOwner=state.initiative
    startAction(state,state.initiative)
end
local function enemyTarget(state,owner,id)
    local h,side=get(state,id)
    return h and h.alive and side==other(owner)
end
local function resolveAttack(state,blocker)
    local attack=state.attack
    local h=get(state,attack.attackerId)
    local def=defs[h.id]
    state.queue={};state.resume="AfterAttack";state.phase="Resolving";state.actor=attack.owner;state.actionOwner=attack.owner
    if attack.useSkill then h.cooldown=def.skill.cooldown;emit(state,"Skill",{source=h.id,code=def.skill.code}) end
    for _,id in ipairs(attack.targets) do
        table.insert(state.queue,{kind="Damage",source=h.id,target=id,amount=h.atk,damageType="Normal",blocker=blocker,execute=attack.useSkill and h.id=="ting_sun"})
    end
    drain(state)
end
function Combat.apply(state,owner,intent)
    if state.phase=="DeathRattleChoice" and intent.kind=="DeathRattleTarget" then
        if owner~=state.pending.owner then return false,"WrongActor" end
        if not enemyTarget(state,owner,intent.targetId) then return false,"InvalidEnemy" end
        prepend(state,{{kind="Damage",source=state.pending.source,target=intent.targetId,amount=Config.damage.deathRattle,damageType="DeathRattle"}})
        state.pending=nil;state.phase="Resolving";drain(state);return true
    end
    if state.actor~=owner then return false,"WrongActor" end
    if state.phase=="SkillPhase" and intent.kind=="SkillEnd" then state.phase="AttackSelect";return true end
    if state.phase=="SkillPhase" and intent.kind=="SkillCast" then
        local caster,side=get(state,intent.casterId)
        if not caster or not caster.alive or side~=owner then return false,"InvalidCaster" end
        if caster.cooldown>0 or caster.used or caster.statuses.blocked then return false,"SkillUnavailable" end
        local code=defs[caster.id].skill.code
        if code~="group_heal" and code~="stasis_lock" and code~="final_barrage" and code~="overload_explode" then return false,"WrongSkillTiming" end
        if code=="stasis_lock" or code=="final_barrage" then
            if not enemyTarget(state,owner,intent.targetId) then return false,"InvalidEnemy" end
        end
        if code=="final_barrage" then
            local enemies=living(state,other(owner))
            if #enemies>1 and (not enemyTarget(state,owner,intent.secondTargetId) or intent.secondTargetId==intent.targetId) then return false,"InvalidSecondTarget" end
        end
        if code=="overload_explode" and intent.targetId~=nil and not enemyTarget(state,owner,intent.targetId) then return false,"InvalidEnemy" end
        emit(state,"Skill",{source=caster.id,code=code})
        state.queue={};state.actionOwner=owner;state.resume="SkillPhase";state.phase="Resolving"
        if code=="group_heal" then
            for _,h in ipairs(living(state,owner)) do
                local amount=math.min(Config.healing,h.maxHp-h.hp);h.hp+=amount
                if amount>0 then emit(state,"Heal",{source=caster.id,target=h.id,amount=amount}) end
            end
            caster.cooldown=defs[caster.id].skill.cooldown
        elseif code=="stasis_lock" then
            get(state,intent.targetId).statuses.blocked=true;caster.cooldown=defs[caster.id].skill.cooldown
            emit(state,"Lock",{source=caster.id,target=intent.targetId})
        elseif code=="overload_explode" then
            table.insert(state.queue,{kind="Death",target=caster.id,rattleTarget=intent.targetId})
        else
            caster.used=true
            table.insert(state.queue,{kind="Damage",source=caster.id,target=intent.targetId,amount=Config.damage.finalFirst,damageType="Skill"})
            table.insert(state.queue,{kind="FinalSecond",source=caster.id,first=intent.targetId,target=intent.secondTargetId})
        end
        drain(state);return true
    end
    if state.phase=="AttackSelect" and intent.kind=="AttackCommit" then
        local attacker,side=get(state,intent.attackerId)
        if not attacker or not attacker.alive or side~=owner then return false,"InvalidAttacker" end
        if type(intent.targets)~="table" or #intent.targets<1 or #intent.targets>2 then return false,"InvalidTargets" end
        local use=intent.useSkill==true
        local def=defs[attacker.id]
        local double=use and (attacker.id=="shuang_xing" or attacker.id=="beng_yue")
        if use and (attacker.cooldown>0 or def.skill.type~="active_attack_phase") then return false,"SkillUnavailable" end
        if #intent.targets~=(double and 2 or 1) then return false,"InvalidTargets" end
        if use and attacker.id=="shuang_xing" and intent.targets[1]==intent.targets[2] then return false,"DistinctTargetsRequired" end
        for _,id in ipairs(intent.targets) do if not enemyTarget(state,owner,id) then return false,"InvalidEnemy" end end
        state.attack={owner=owner,attackerId=attacker.id,targets=table.clone(intent.targets),useSkill=use}
        state.phase="BlockSelect";state.actor=other(owner)
        emit(state,"AttackCommitted",{owner=owner}) -- No hidden attacker/target in public event.
        if #living(state,other(owner))==1 then resolveAttack(state,nil) end
        return true
    end
    if state.phase=="BlockSelect" and intent.kind=="BlockCommit" then
        if intent.blockerId~=nil then
            local h,side=get(state,intent.blockerId)
            if not h or not h.alive or side~=owner then return false,"InvalidBlocker" end
        end
        resolveAttack(state,intent.blockerId);return true
    end
    return false,"WrongPhase"
end
return Combat
