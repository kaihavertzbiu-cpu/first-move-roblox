-- Development-only LocalScript: parent alongside a StringValue named Result in PlayerScripts.
-- Observe a new public AI/PvP session after insertion. Never embed in the shipped place.
local Players=game:GetService("Players");local Run=game:GetService("RunService")
local modules=Players.LocalPlayer.PlayerScripts:WaitForChild("DeadlockClient")
local Audio=require(modules.AudioController);local Camera=require(modules.CameraController);local Director=require(modules.PresentationDirector)
local folder=script.Parent;local result=folder.Result
local latest;local seen={};local skillCodes={};local accents={};local peak=0;local fovMin=100;local fovMax=0;local terminalBeat=false
local state=game.ReplicatedStorage.DeadlockRemotes.State.OnClientEvent:Connect(function(packet)
 if packet.view then latest=packet.view;for _,e in ipairs(latest.events) do if e.kind=="Skill" then skillCodes[e.code]=true end end end
end)
local done=false
local heartbeat
heartbeat=Run.Heartbeat:Connect(function()
 if done then return end
 local tableModel=workspace.DeadlockWorld.CommandRoom.StrategicTable
 local effects=tableModel:FindFirstChild("LocalResolutionEffects");local list=effects and effects:GetChildren() or {}
 peak=math.max(peak,#list)
 for _,p in ipairs(list) do seen[p:GetAttribute("EventKind")]=true end
 local gui=Players.LocalPlayer.PlayerGui.DeadlockUI
 local layer=gui:FindFirstChild("CinematicLayer");local g=layer and layer:FindFirstChild("ImpactPresentation")
 if g then accents[g:GetAttribute("PresentationKind")]=true end
 if Camera.Screen=="Battle" then fovMin=math.min(fovMin,workspace.CurrentCamera.FieldOfView);fovMax=math.max(fovMax,workspace.CurrentCamera.FieldOfView) end
 if latest and latest.phase=="GameOver" and g and g:GetAttribute("PresentationKind")=="Outcome" and not gui.Router:FindFirstChild("ReportBanner") then terminalBeat=true end
 if latest and latest.phase=="GameOver" and not Director.resolving() then
   done=true
   task.delay(1,function()
    local playing={};for _,s in ipairs(game.SoundService:GetDescendants()) do if s:IsA("Sound") and s.IsPlaying then table.insert(playing,s:GetFullName()) end end
    local labels=0;for _,o in ipairs(tableModel:GetDescendants()) do if o:IsA("TextLabel") or o:IsA("BillboardGui") then labels+=1 end end
    result.Value=game:GetService("HttpService"):JSONEncode({phase=latest.phase,round=latest.round,sessionId=latest.sessionId,winner=latest.winner,seen=seen,skillCodes=skillCodes,accents=accents,peakParts=peak,finalEffects=#effects:GetChildren(),labelsOnTable=labels,terminalBeatBeforeReport=terminalBeat,reportVisible=gui.Router:FindFirstChild("ReportBanner")~=nil,remainingAccent=layer and layer:FindFirstChild("ImpactPresentation")~=nil,audioCounts=Audio.Counts,cameraCounts=Camera.Counts,fovRange={fovMin,fovMax},loaded=Audio.Loaded,playing=playing})
    state:Disconnect();heartbeat:Disconnect()
   end)
 end
end)
