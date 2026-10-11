-- Run only in a Studio Client after starting an AI game through the menu.
-- Real remotes/server/AI/UI; scripted public-information decisions, not manual play.
assert(game:GetService("RunService"):IsStudio(),"Studio-only acceptance")
local qa=assert(shared.FirstMoveAcceptance,"Attach public packet observer first")
local defs=require(game.ReplicatedStorage.DeadlockShared.LegacyConfig)
local rng=Random.new(208)
local deadline=os.clock()+18;local sentRevision=-1;local sentCoreRound=-1
while os.clock()<deadline do
    local v=qa.view
    if v and v.phase=="GameOver" then break end
    if v and v.mode=="AI" then
        local action
        local own,enemy={},{}
        for _,h in ipairs(v.rosters.A) do if h.alive then table.insert(own,h) end end
        for _,h in ipairs(v.rosters.B) do if h.alive then table.insert(enemy,h) end end
        table.sort(own,function(a,b) return a.atk>b.atk end);table.sort(enemy,function(a,b) return a.hp<b.hp end)
        if v.phase=="CoreSelection" and not v.coreLocked.A then action={kind="CoreLock",core=({"red","cyan","purple"})[rng:NextInteger(1,3)]}
        elseif v.actor=="A" then
            if v.phase=="Draft" then
                local taken={};for _,side in ipairs({"A","B"}) do for _,h in ipairs(v.rosters[side]) do taken[h.id]=true end end
                for _,h in ipairs(defs.heroes) do if not taken[h.id] and h.id~="ye_ban" then action={kind="DraftPick",heroId=h.id};break end end
            elseif v.phase=="SkillPhase" then action={kind="SkillEnd"}
            elseif v.phase=="AttackSelect" and own[1] and enemy[1] then
                local h=own[1];action={kind="AttackCommit",attackerId=h.id,targets={enemy[1].id},useSkill=h.id=="ting_sun" and h.cooldown==0 and not h.statuses.blocked}
            elseif v.phase=="BlockSelect" then action={kind="BlockCommit"}
            elseif v.phase=="DeathRattleChoice" and enemy[1] then action={kind="DeathRattleTarget",targetId=enemy[1].id} end
        end
        if action and (v.revision~=sentRevision or v.phase=="CoreSelection" and v.round~=sentCoreRound) then
            sentRevision=v.revision;sentCoreRound=v.round;action.revision=v.revision;qa.actions+=1
            game.ReplicatedStorage.DeadlockRemotes.Intent:FireServer({command="Action",sessionId=v.sessionId,intent=action})
        end
    end
    task.wait(.25)
end
local errors={};for _,p in ipairs(qa.packets) do if p.error then table.insert(errors,p.error) end end
local v=qa.view
return game:GetService("HttpService"):JSONEncode({scope="Studio client scripted public decisions through shipping remotes",sessionId=v and v.sessionId,phase=v and v.phase,round=v and v.round,winner=v and v.winner,revision=v and v.revision,actions=qa.actions,packets=#qa.packets,errors=errors})
