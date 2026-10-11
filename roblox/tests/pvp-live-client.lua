local Players=game:GetService("Players")
local p=Players.LocalPlayer
local shared=game.ReplicatedStorage:WaitForChild("FirstMovePvpQA")
local probe=shared:WaitForChild("Probe")
local AI=require(shared.Planner)
local modules=p:WaitForChild("PlayerScripts"):WaitForChild("DeadlockClient")
local battle=require(modules.BattleController)
local director=require(modules.PresentationDirector)
local remote=game.ReplicatedStorage:WaitForChild("DeadlockRemotes")
local view;local sessions={};local last;local rng=Random.new(math.abs(p.UserId)+51);local actions=0
remote.State.OnClientEvent:Connect(function(message)
 if message.view then view=message.view end
 if message.error then probe:FireServer({error=message.error,phase=view and view.phase})end
end)
task.wait(5)
battle.Mode="PvP";battle.start()
local started=os.clock()
while os.clock()-started<240 do
 task.wait(.25)
 if view and not director.resolving()then
  if view.phase=="GameOver"then
   if not sessions[view.sessionId]then
    sessions[view.sessionId]=true
    probe:FireServer({terminal=view,actions=actions,gui=p.PlayerGui:FindFirstChild("DeadlockUI")~=nil})
    if not last then last=view.sessionId;task.wait(2);battle.again()end
   end
  else
   local intent=AI.intent(view,"A",rng)
   if intent then
    remote.Intent:FireServer({command="Action",sessionId=view.sessionId,intent=intent});actions+=1
    probe:FireServer({progress={session=view.sessionId,phase=view.phase,revision=view.revision,round=view.round},actions=actions})
    task.wait(.35)
   end
  end
 end
end
probe:FireServer({error="ClientTimeout"})

