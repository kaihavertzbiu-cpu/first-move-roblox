-- Offline Studio QA fixture only. Never insert into a published experience.
if not game:GetService("RunService"):IsStudio() then return end
local folder=game.ReplicatedStorage.FirstMovePvpQA
local records={};local progress={};local errors={}
folder.Probe.OnServerEvent:Connect(function(p,data)
 if data.error then table.insert(errors,{player=p.Name,error=data.error,phase=data.phase})end
 if data.progress then progress[p.Name]=data.progress end
 if data.terminal then
  local v=data.terminal
table.insert(records,{player=p.Name,view={sessionId=v.sessionId,phase=v.phase,round=v.round,revision=v.revision,winner=v.winner,rosters=v.rosters,report={teams=v.report.teams,completedRounds=v.report.completedRounds,finalRound=v.report.finalRound}},actions=data.actions,gui=data.gui,language=data.language,presentations=data.presentations})
  print("PVP_QA_TERMINAL",p.Name,data.terminal.sessionId,data.terminal.round,data.terminal.winner)
  if #records>=4 then
   task.delay(2,function()
    local profiles={};local Data=require(game.ServerScriptService.DeadlockServer.DataService)
    for _,player in ipairs(game.Players:GetPlayers())do local value=Data.profile(player);profiles[player.Name]={stats=value.stats,economy=value.economy,historyCount=#value.history,language=value.settings.language}end
    game:GetService("StudioTestService"):EndTest({records=records,errors=errors,profiles=profiles,scope="2 independent Studio clients; public-view planner submits real RemoteEvents; shipping battle/report UI receives state; not physical UI click or production network acceptance"})
   end)
  end
 end
end)
task.delay(260,function()game:GetService("StudioTestService"):EndTest({timeout=true,records=records,errors=errors,progress=progress})end)
