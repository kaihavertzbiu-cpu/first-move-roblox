assert(game:GetService("RunService"):IsStudio(),"Studio-only monitor")
local player=game.Players.LocalPlayer
local modules=player.PlayerScripts:WaitForChild("DeadlockClient")
local Director=require(modules.PresentationDirector);local Audio=require(modules.AudioController);local Impact=require(modules.ImpactPresentation)
local startAudio=table.clone(Audio.Counts);local folder=script.Parent
local latest;local titles={};local seen={};local peak=0;local beat=false;local done=false
local state=game.ReplicatedStorage.DeadlockRemotes.State.OnClientEvent:Connect(function(m) if m.view then latest=m.view end end)
local heartbeat
heartbeat=game:GetService("RunService").Heartbeat:Connect(function()
 folder:SetAttribute("Resolving",Director.resolving())
 if done then return end
 local tableModel=workspace.DeadlockWorld.CommandRoom.StrategicTable
 local fx=tableModel:FindFirstChild("LocalResolutionEffects");local list=fx and fx:GetChildren() or {}
 peak=math.max(peak,#list);for _,p in ipairs(list) do seen[p:GetAttribute("EventKind")]=true end
 local gui=player.PlayerGui.DeadlockUI;local layer=gui:FindFirstChild("CinematicLayer");local group=layer and layer:FindFirstChild("ImpactPresentation")
 if group then
  local title=group:FindFirstChild("ImpactTitle")
  if title then titles[title.Text]=true end
  if group:GetAttribute("PresentationKind")=="Outcome" then folder:SetAttribute("Outcome",true);beat=not gui.Router:FindFirstChild("ReportBanner") end
 end
 if latest and latest.phase=="GameOver" and not Director.resolving() then
  done=true
  task.delay(.6,function()
   local delta={};for k,v in pairs(Audio.Counts) do delta[k]=v-(startAudio[k] or 0) end
   local labels=0;for _,o in ipairs(tableModel:GetDescendants()) do if o:IsA("TextLabel") or o:IsA("BillboardGui") then labels+=1 end end
   folder.Result.Value=game:GetService("HttpService"):JSONEncode({scope="real AI client/server; only public views and local presentation observed",sessionId=latest.sessionId,round=latest.round,winner=latest.winner,titles=titles,seen=seen,peakParts=peak,finalParts=#fx:GetChildren(),labelsOnTable=labels,impactCounts=Impact.Counts,audioDelta=delta,beatBeforeReport=beat,reportVisible=gui.Router:FindFirstChild("ReportBanner")~=nil,remainingAccent=layer:FindFirstChild("ImpactPresentation")~=nil,phase=latest.phase})
   state:Disconnect();heartbeat:Disconnect()
  end)
 end
end)
