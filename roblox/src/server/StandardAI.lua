-- Input is the same projected view a player receives; no private state reference.
local Config=require(game:GetService("ReplicatedStorage").DeadlockShared.LegacyConfig)
local defs={}
for _,h in ipairs(Config.heroes) do defs[h.id]=h end
local AI={}
local function alive(roster)
    local list={};for _,h in ipairs(roster) do if h.alive then table.insert(list,h) end end;return list
end
local function weakest(list)
    local best=list[1];for _,h in ipairs(list) do if h.hp<best.hp then best=h end end;return best
end
function AI.intent(view,owner,rng)
    local enemy=owner=="A" and "B" or "A"
    local allies=alive(view.rosters[owner]);local enemies=alive(view.rosters[enemy])
    local function answer(kind,fields)
        fields=fields or {};fields.kind=kind;fields.revision=view.revision;return fields
    end
    if view.phase=="Draft" and view.actor==owner then
        local taken={};for _,side in ipairs({"A","B"}) do for _,h in ipairs(view.rosters[side]) do taken[h.id]=true end end
        local best,score
        for _,h in ipairs(Config.heroes) do
            local value=h.atk+h.maxHp*.20+rng:NextNumber(0,5)
            if h.id=="ting_sun" or h.id=="xuan_bao" then value+=2 end
            if not taken[h.id] and (not score or value>score) then best=h;score=value end
        end
        return answer("DraftPick",{heroId=best.id})
    end
    if view.phase=="LinkSetup" and view.actor==owner then
        local ally
        for _,h in ipairs(allies) do if h.id~="ye_ban" and (not ally or h.maxHp<ally.maxHp) then ally=h end end
        local target=enemies[1]
        for _,h in ipairs(enemies) do if h.atk>target.atk then target=h end end
        return answer("LinkConfirm",{allyId=ally.id,enemyId=target.id})
    end
    if view.phase=="CoreSelection" and not view.coreLocked[owner] then
        local cores={"cyan","red","purple"}
        return answer("CoreLock",{core=cores[rng:NextInteger(1,3)]})
    end
    if view.actor~=owner then return nil end
    if view.phase=="DeathRattleChoice" then return answer("DeathRattleTarget",{targetId=weakest(enemies).id}) end
    if view.phase=="SkillPhase" then
        for _,h in ipairs(allies) do
            if h.cooldown==0 and not h.used and not h.statuses.blocked then
                local code=defs[h.id].skill.code
                if code=="group_heal" then
                    local missing=0;for _,a in ipairs(allies) do missing+=math.min(Config.healing,a.maxHp-a.hp) end
                    if missing>=4 then return answer("SkillCast",{casterId=h.id}) end
                elseif code=="final_barrage" and weakest(enemies).hp<=Config.damage.finalFirst then
                    local first=weakest(enemies);local second
                    for _,e in ipairs(enemies) do if e.id~=first.id and (not second or e.hp<second.hp) then second=e end end
                    return answer("SkillCast",{casterId=h.id,targetId=first.id,secondTargetId=second and second.id})
                elseif code=="stasis_lock" then
                    local target
                    for _,e in ipairs(enemies) do
                        local skill=defs[e.id].skill
                        if not e.statuses.blocked and e.cooldown==0 and not skill.isPassive and skill.triggerTiming=="active" then target=e;break end
                    end
                    if target then return answer("SkillCast",{casterId=h.id,targetId=target.id}) end
                elseif code=="overload_explode" and h.hp<=5 then
                    return answer("SkillCast",{casterId=h.id,targetId=weakest(enemies).id})
                end
            end
        end
        return answer("SkillEnd")
    end
    if view.phase=="AttackSelect" then
        local best,score,use,targets
        for _,h in ipairs(allies) do
            for _,e in ipairs(enemies) do
                local damage=e.id=="lan_dun" and math.min(h.atk,Config.normalDamageCap) or h.atk
                local active=h.cooldown==0 and defs[h.id].skill.type=="active_attack_phase"
                if h.id=="shuang_xing" and #enemies<2 then active=false end
                local value=math.min(e.hp,damage)+(e.hp<=damage and 8 or 0)+rng:NextNumber(0,4)
                if h.id=="huan_shi" then value+=2 end
                if h.id=="xuan_bao" and not e.statuses.bleeding then value+=2 end
                if e.id=="zhe_jing" and e.hp>damage then value-=3 end
                if active then value+=h.id=="ting_sun" and e.hp*.65 or damage end
                if not score or value>score then
                    best=h;score=value;use=active;targets={e.id}
                    if active and h.id=="beng_yue" then table.insert(targets,e.id)
                    elseif active and h.id=="shuang_xing" then
                        for _,second in ipairs(enemies) do if second.id~=e.id then table.insert(targets,second.id);break end end
                    end
                end
            end
        end
        return answer("AttackCommit",{attackerId=best.id,targets=targets,useSkill=use})
    end
    if view.phase=="BlockSelect" then
        -- Mix protecting a threatened unit with unpredictable legal choices.
        local target=rng:NextNumber()<.70 and weakest(allies) or allies[rng:NextInteger(1,#allies)]
        return answer("BlockCommit",{blockerId=target.id})
    end
end
return AI
