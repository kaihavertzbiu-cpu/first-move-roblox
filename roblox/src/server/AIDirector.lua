-- Every decision accepts a public projection. No session or private attack reference.
local Shared=game.ReplicatedStorage.DeadlockShared
local Legacy=require(Shared.LegacyConfig);local Tuning=require(Shared.AIConfig)
local Basic=require(script.Parent.StandardAI);local defs={};for _,h in ipairs(Legacy.heroes) do defs[h.id]=h end
local AI={}
function AI.intent(view,owner,rng,difficulty)
    local base=Basic.intent(view,owner,rng);if difficulty~="Advanced" or not base then return base end
    local t=Tuning.Advanced;local enemy=owner=="A" and "B" or "A"
    if base.kind=="CoreLock" and rng:NextNumber()>t.coreExploration then
        local counts={red=0,cyan=0,purple=0};local seen=0
        for i=#view.events,1,-1 do local e=view.events[i];if e.kind=="CoreReveal" then counts[e[enemy]]+=1;seen+=1;if seen>=t.coreMemory then break end end end
        if seen>0 then local predicted="red";for _,c in ipairs({"cyan","purple"}) do if counts[c]>counts[predicted] then predicted=c end end;for core,beats in pairs(Legacy.beats) do if beats==predicted then base.core=core;break end end end
    elseif base.kind=="AttackCommit" then
        local blocked={};local owners={};for _,h in ipairs(view.rosters[enemy]) do owners[h.id]=true end
        for i=#view.events,1,-1 do local e=view.events[i];if e.round<view.round-t.coreMemory then break end;if e.kind=="Block" and owners[e.target] then blocked[e.target]=(blocked[e.target] or 0)+1 end end
        local enemies={};for _,h in ipairs(view.rosters[enemy]) do if h.alive then table.insert(enemies,h) end end
        local best;local score=-math.huge
        for _,h in ipairs(view.rosters[owner]) do if h.alive then for _,e in ipairs(enemies) do
            local active=h.cooldown==0 and defs[h.id].skill.type=="active_attack_phase";if h.id=="shuang_xing" and #enemies<2 then active=false end
            local damage=e.id=="lan_dun" and math.min(h.atk,Legacy.normalDamageCap) or h.atk
            if active and h.id=="beng_yue" then damage*=2 end
            local value=math.min(e.hp,damage)+(damage>=e.hp and t.killBonus or 0)+rng:NextNumber(0,t.exploration)
            if active and h.id=="ting_sun" then value+=e.hp*t.executionWeight+t.killBonus end
            if h.id=="xuan_bao" and not e.statuses.bleeding then value+=5 end
            if e.id=="zhe_jing" and e.hp>damage then value-=math.min(h.hp,Legacy.reflection or 4) end
            if h.id~="huan_shi" then value-=math.min(blocked[e.id] or 0,3)*t.blockPenalty else value+=3 end
            if value>score then score=value;best={kind="AttackCommit",revision=view.revision,attackerId=h.id,useSkill=active,targets={e.id}}
                if active and h.id=="beng_yue" then table.insert(best.targets,e.id)
                elseif active and h.id=="shuang_xing" then local second;for _,s in ipairs(enemies) do if s.id~=e.id and (not second or s.hp<second.hp) then second=s end end;table.insert(best.targets,second.id) end
            end
        end end end
        return best or base
    elseif base.kind=="BlockCommit" and rng:NextNumber()<t.weakestProtection then
        local target;for _,h in ipairs(view.rosters[owner]) do if h.alive and (not target or h.hp<target.hp) then target=h end end;base.blockerId=target.id
    end
    return base
end
return AI
