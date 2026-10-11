-- Studio Client only: public information, normal shipping intents, actual presentation pacing.
assert(game:GetService("RunService"):IsStudio(),"Studio-only acceptance")
local qa=assert(shared.FirstMoveAcceptance,"Attach public packet observer first")
local monitor=game.Players.LocalPlayer.PlayerScripts:FindFirstChild("FirstMoveChainQA")
local defs=require(game.ReplicatedStorage.DeadlockShared.LegacyConfig)
local priority={"ting_sun","yan_wei","bai_ji","zhui_lie","chi_guang","lan_dun","beng_yue","xuan_bao","huan_shi","shuang_xing","zhe_jing"}
local rng=Random.new(421)
local deadline=os.clock()+120;local sentRevision=-1
while os.clock()<deadline do
 local v=qa.view
 if v and v.phase=="GameOver" then break end
 if v and v.mode=="AI" and not (monitor and monitor:GetAttribute("Resolving")) then
  local action
  local own,enemy={},{}
  for _,h in ipairs(v.rosters.A) do if h.alive then table.insert(own,h) end end
  for _,h in ipairs(v.rosters.B) do if h.alive then table.insert(enemy,h) end end
  table.sort(own,function(a,b) return a.atk>b.atk end)
  table.sort(enemy,function(a,b) return a.hp>b.hp end)
  if v.phase=="CoreSelection" and not v.coreLocked.A then action={kind="CoreLock",core=({"red","cyan","purple"})[rng:NextInteger(1,3)]}
  elseif v.actor=="A" then
   if v.phase=="Draft" then
    local taken={};for _,side in ipairs({"A","B"}) do for _,h in ipairs(v.rosters[side]) do taken[h.id]=true end end
    for _,id in ipairs(priority) do if not taken[id] then action={kind="DraftPick",heroId=id};break end end
    if not action then for _,h in ipairs(defs.heroes) do if not taken[h.id] and h.id~="ye_ban" then action={kind="DraftPick",heroId=h.id};break end end end
   elseif v.phase=="SkillPhase" then
    for _,h in ipairs(own) do
     if h.cooldown==0 and not h.used and not h.statuses.blocked then
      if h.id=="yan_wei" then action={kind="SkillCast",casterId=h.id};break
      elseif h.id=="bai_ji" then
       for _,f in ipairs(own) do if f.hp<f.maxHp then action={kind="SkillCast",casterId=h.id};break end end
      elseif h.id=="chi_guang" then
       local best;for _,e in ipairs(enemy) do if not e.statuses.blocked and (not best or e.atk>best.atk) then best=e end end
       if best then action={kind="SkillCast",casterId=h.id,targetId=best.id} end
      elseif h.id=="zhui_lie" then
       local low=enemy[#enemy]
       if low and low.hp<=8 then action={kind="SkillCast",casterId=h.id,targetId=low.id,secondTargetId=enemy[1].id~=low.id and enemy[1].id or nil} end
      end
      if action then break end
     end
    end
    action=action or {kind="SkillEnd"}
   elseif v.phase=="AttackSelect" and own[1] and enemy[1] then
    local attacker=own[1]
    for _,h in ipairs(own) do if h.id=="ting_sun" and h.cooldown==0 and not h.statuses.blocked then attacker=h;break end end
    local use=attacker.cooldown==0 and not attacker.statuses.blocked and (attacker.id=="ting_sun" or attacker.id=="beng_yue" or attacker.id=="shuang_xing")
    local targets={enemy[1].id}
    if use and (attacker.id=="beng_yue" or attacker.id=="shuang_xing") then table.insert(targets,enemy[2] and enemy[2].id or enemy[1].id) end
    action={kind="AttackCommit",attackerId=attacker.id,targets=targets,useSkill=use}
   elseif v.phase=="BlockSelect" then
    local low;for _,h in ipairs(own) do if not low or h.hp<low.hp then low=h end end
    action={kind="BlockCommit",blockerId=low and low.id}
   elseif v.phase=="DeathRattleChoice" and enemy[1] then action={kind="DeathRattleTarget",targetId=enemy[1].id}
   end
  end
  if action and v.revision~=sentRevision then
   sentRevision=v.revision;action.revision=v.revision;qa.actions+=1
   game.ReplicatedStorage.DeadlockRemotes.Intent:FireServer({command="Action",sessionId=v.sessionId,intent=action})
  end
 end
 task.wait(.15)
end
local v=qa.view
if v and v.phase=="GameOver" and monitor then
 local endWait=os.clock()+20
 repeat task.wait(.03) until monitor:GetAttribute("Outcome") or os.clock()>endWait
end
local errors={};for _,p in ipairs(qa.packets) do if p.error then table.insert(errors,p.error) end end
return game:GetService("HttpService"):JSONEncode({scope="real server AI; public tactical decisions through normal remotes, paced by actual presentation; not manual play",sessionId=v and v.sessionId,phase=v and v.phase,round=v and v.round,winner=v and v.winner,revision=v and v.revision,actions=qa.actions,errors=errors,outcomeReady=monitor and monitor:GetAttribute("Outcome")})

