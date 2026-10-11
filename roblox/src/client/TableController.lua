-- Presentation only. These animations do not imply unseen gameplay information.
local RunService = game:GetService("RunService")
local Presentation = require(script.Parent.PresentationConfig)
local Feedback = Presentation.TableFeedback
local world = workspace:WaitForChild("DeadlockWorld")
local tableModel = world.CommandRoom:WaitForChild("StrategicTable")
local Table = {Reduced = false}
local contacts, byId, sessionId, eventCount = {}, {}, nil, 0
local recordsById={}
local effects=require(script.Parent.ResolutionEffects).new(tableModel)
for _,side in ipairs({"A","B"}) do
    contacts[side]={}
    for i=1,5 do
        local p=tableModel:WaitForChild("Unit hologram "..side.." "..i)
        contacts[side][i]={Part=p,Size=p.Size,CFrame=p.CFrame,Color=p.Color}
    end
end
function Table.reset()
    byId={};recordsById={};sessionId=nil;eventCount=0;effects.reset()
    for _,list in pairs(contacts) do for _,record in ipairs(list) do
        record.Part.Size=record.Size;record.Part.CFrame=record.CFrame
        record.Part.Color=record.Color;record.Part.Transparency=.15
        record.Id=nil;record.Alive=nil;record.PresentedAlive=nil;record.PendingDeath=false
    end end
end
-- Receives the same public projection as the HUD. Never reads private match state.
function Table.present(event,hold)
    if event.kind=="Death" then
        local record=recordsById[event.target]
        if record then record.PresentedAlive=false;record.PendingDeath=false;record.Part.Transparency=Feedback.DeadTransparency end
    end
    effects.present(event,byId[event.source],byId[event.target],hold,Table.Reduced)
end
function Table.approach(event,hold)
    effects.approach(event,byId[event.source],byId[event.target],hold,Table.Reduced)
end
function Table.focus(event)
    local p=byId[event.target] or byId[event.source]
    return p and p.Position
end
function Table.outcome(winner,hold)
    effects.outcome(winner,hold,Table.Reduced)
end
function Table.cancelPresentation()
    effects.reset()
    for _,record in pairs(recordsById) do
        record.PendingDeath=false;record.PresentedAlive=record.Alive
        record.Part.Transparency=record.Alive and Feedback.ContactTransparency or Feedback.DeadTransparency
    end
end
function Table.update(view,selection)
    if sessionId~=view.sessionId or #view.events<eventCount then Table.reset();sessionId=view.sessionId end
    local deaths={};for i=eventCount+1,#view.events do local e=view.events[i];if e.kind=="Death" then deaths[e.target]=true end end
    eventCount=#view.events;byId={};recordsById={}
    for _,side in ipairs({"A","B"}) do for i,record in ipairs(contacts[side]) do
        local h=view.rosters[side][i];local p=record.Part
        if h then
            byId[h.id]=p
            recordsById[h.id]=record
            if record.Id~=h.id then record.PresentedAlive=h.alive;record.PendingDeath=false
            elseif h.alive then record.PresentedAlive=true;record.PendingDeath=false
            elseif deaths[h.id] and record.PresentedAlive then record.PendingDeath=true
            elseif not record.PendingDeath then record.PresentedAlive=false end
            record.Id=h.id;record.Alive=h.alive
            -- The table stays spatial and quiet. Identity, HP and order live in the HUD.
            p.Size=record.Size;p.CFrame=record.CFrame
            local picked=selection.ally==h.id or selection.target==h.id or selection.second==h.id
            local color=picked and Presentation.Colors.Paper or record.Color
            p.Color=color;p.Transparency=record.PresentedAlive and Feedback.ContactTransparency or Feedback.DeadTransparency
        else p.Transparency=.9 end
    end end
end
local coreParts = {}
local pivot = CFrame.new(0, 5.55, 0)
for _,p in ipairs(tableModel:GetDescendants()) do
    if p:IsA("BasePart") and (p.Name == "Core lattice" or p.Name == "Core equator" or p.Name == "Axiom nucleus") then
        table.insert(coreParts, {Part = p, Offset = pivot:ToObjectSpace(p.CFrame)})
    end
end
local sweep = Instance.new("Part")
sweep.Name = "LocalScanSweep"
sweep.Anchored = true
sweep.CanCollide = false
sweep.CanQuery = false
sweep.CanTouch = false
sweep.Material = Enum.Material.Neon
sweep.Color = Color3.fromRGB(75, 141, 147)
sweep.Transparency = 0.65
sweep.Size = Vector3.new(7.3, 0.02, 0.045)
sweep.Parent = tableModel
function Table.SetReduced(value)
    value=value and true or false
    if Table.Reduced==value then return end
    Table.Reduced=value
    Table.cancelPresentation()
    sweep.Transparency=Table.Reduced and 1 or .65
end
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if Table.Reduced then return end
    local rotation = pivot * CFrame.Angles(0, elapsed * 0.08, 0)
    for _,record in ipairs(coreParts) do
        record.Part.CFrame = rotation * record.Offset
    end
    sweep.CFrame = CFrame.new(0, 4.095, 0) * CFrame.Angles(0, elapsed * 0.14, 0)
end)
return Table
