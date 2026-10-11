-- Real Roblox instances/tweens in a disposable table clone. No match/profile writes.
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local config=require(modules.PresentationConfig)
local checks={}
local function check(label,ok) assert(ok,label);table.insert(checks,label) end
local function load(module,fakeGame,dependencies)
    return assert(loadstring("local game,workspace,script,require=...\n"..module.Source))(fakeGame or game,workspace,{Parent=modules},function(m) return assert(dependencies[m],"Unexpected dependency") end)
end
local effects=load(modules.ResolutionEffects,game,{[modules.PresentationConfig]=config})
local clone=workspace.DeadlockWorld.CommandRoom.StrategicTable:Clone()
clone.Name="FirstMoveResolutionQA";clone.Parent=workspace;clone:PivotTo(clone:GetPivot()+Vector3.new(100,0,0))
local result
local ok,err=pcall(function()
    local fakeWorkspace={WaitForChild=function() return {CommandRoom={WaitForChild=function() return clone end}} end}
    local fakeGame={GetService=function(_,name)
        if name=="RunService" then return {Heartbeat={Connect=function() end}} end
        return game:GetService(name)
    end}
    local tableSource=assert(loadstring("local game,workspace,script,require=...\n"..modules.TableController.Source))
    local t=tableSource(fakeGame,fakeWorkspace,{Parent=modules},function(m) return ({[modules.PresentationConfig]=config,[modules.ResolutionEffects]=effects})[m] end)
    local a=clone["Unit hologram A 1"];local b=clone["Unit hologram B 1"]
    local view={sessionId="fixture",events={},rosters={A={{id="first",alive=true}},B={{id="second",alive=true}}}}
    t.update(view,{})
    view.rosters.A[1].alive=false;view.rosters.B[1].alive=false
    view.events={{kind="Damage",source="second",target="first"},{kind="Death",target="first"},{kind="LinkTrigger",source="first",target="second"},{kind="Death",target="second"}}
    t.update(view,{})
    check("New public deaths wait for their presentation step",a.Transparency<.3 and b.Transparency<.3)
    t.present(view.events[2],.3)
    check("First death dims only its own contact",a.Transparency>.8 and b.Transparency<.3)
    t.update(view,{})
    check("HUD redraw retains queued linked death",a.Transparency>.8 and b.Transparency<.3)
    t.present(view.events[3],.42);t.present(view.events[4],.3)
    check("Linked contact dims after the link event",b.Transparency>.8)
    t.cancelPresentation();check("Cancellation clears temporary table effects",#clone.LocalResolutionEffects:GetChildren()==0)
    view.events={};view.rosters.A[1].alive=true;view.rosters.B[1].alive=true;t.update(view,{})
    check("Training rewind restores fresh contact state",a.Transparency<.3 and b.Transparency<.3)
    t.present({kind="Execute",source="first",target="second"},.42)
    t.SetReduced(true)
    check("Reduced motion cancels current animated effects",#clone.LocalResolutionEffects:GetChildren()==0)
    check("Reduced motion hides the continuous scan",clone.LocalScanSweep.Transparency==1)
    t.present({kind="Block",target="first"},.04)
    local static=clone.LocalResolutionEffects:GetChildren()
    check("Reduced motion retains static semantic feedback",#static==4)
    local before=static[1].CFrame;task.wait(.05)
    check("Reduced feedback does not move",static[1].CFrame==before)
    t.reset()
    view.sessionId="joining";view.events={{kind="Death",target="second"}};view.rosters.B[1].alive=false;t.update(view,{})
    check("Joining historical deaths does not pretend contacts are alive",b.Transparency>.8 and #clone.LocalResolutionEffects:GetChildren()==0)
    local holder=Instance.new("Folder");holder.Name="Stress";holder.Parent=clone
    local fx=effects.new(holder)
    for _,kind in ipairs({"Damage","Heal","Block","Execute","LinkTrigger","Death","Lock"}) do
        fx.reset();check(kind.." produces a distinct public cue",fx.present({kind=kind,source="first",target="second"},a,b,.3,false))
        check(kind.." has bounded geometry",#fx.Folder:GetChildren()>0 and #fx.Folder:GetChildren()<=config.TableFeedback.MaximumParts)
        for _,p in ipairs(fx.Folder:GetChildren()) do
            check(kind.." is nonphysical and label-free",p:IsA("BasePart") and p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery and #p:GetChildren()==0)
        end
    end
    fx.reset();check("Unrevealed setup emits no link",not fx.present({kind="LinkSetup"},a,b,.3,false) and #fx.Folder:GetChildren()==0)
    check("Unknown target is ignored",not fx.present({kind="Damage"},a,nil,.3,false))
    for _,code in ipairs({"group_heal","stasis_lock","thunder_judgment","rail_shot","fury_press","final_barrage","overload_explode"}) do
        fx.reset();check(code.." has public source-only casting geometry",fx.present({kind="Skill",code=code},a,nil,.3,false) and #fx.Folder:GetChildren()>0)
    end
    fx.reset();check("Unknown skill code has no fabricated visual",not fx.present({kind="Skill",code="private"},a,nil,.3,false) and #fx.Folder:GetChildren()==0)
    fx.outcome("A",.3,false);check("Outcome spatial geometry remains bounded",#fx.Folder:GetChildren()>0 and #fx.Folder:GetChildren()<=config.TableFeedback.MaximumParts)
    fx.reset();fx.outcome("B",.3,true);check("Reduced outcome is a static four-segment cue",#fx.Folder:GetChildren()==4)
    for i=1,100 do fx.present({kind=i%2==0 and "Heal" or "LinkTrigger"},a,b,.3,false) end
    check("Burst stress remains within fixed part budget",fx.PeakParts<=config.TableFeedback.MaximumParts and #fx.Folder:GetChildren()<=config.TableFeedback.MaximumParts)
    task.wait(.5);check("Debris releases all completed burst geometry",#fx.Folder:GetChildren()==0)
    fx.present({kind="Execute"},a,b,.3,false);fx.reset()
    check("Reset cancels active geometry immediately",#fx.Folder:GetChildren()==0)
    result={scope="disposable table clone; real Roblox parts/tweens, simulated revealed events, no player match/profile changes",passed=#checks,peakParts=fx.PeakParts,checks=checks}
end)
clone:Destroy();if not ok then error(err) end
return game:GetService("HttpService"):JSONEncode(result)
