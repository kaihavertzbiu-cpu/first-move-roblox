-- Real HUD geometry and camera interpolation in disposable fixtures; not hardware QA.
local qa=Instance.new("Folder");qa.Name="CinematicLocaleQA";qa.Parent=game.ServerStorage
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient:Clone();modules.Parent=qa
local locale=require(modules.LocaleController);locale.Set("zh-cn")
local config=require(modules.PresentationConfig)
local identity=require(modules.UnitIdentity)
local checks={};local function check(name,value) assert(value,name);table.insert(checks,name) end
local function load(m,fakeGame,fakeWorkspace,deps)
    return assert(loadstring("local game,workspace,script,require=...\n"..m.Source))(fakeGame or game,fakeWorkspace or workspace,{Parent=modules},function(k) return assert(deps[k],"Unexpected dependency") end)
end
local gui=Instance.new("ScreenGui");gui.Name="FirstMoveCinematicQA";gui.IgnoreGuiInset=true;gui.Parent=game.CoreGui
local root=Instance.new("Frame");root.BackgroundTransparency=1;root.Parent=gui
local impact=load(modules.ImpactPresentation,game,workspace,{[modules.LocaleController]=locale,[modules.PresentationConfig]=config,[modules.UnitIdentity]=identity,[modules.UnitPortrait]=require(modules.UnitPortrait)})
local render;local fakeCam={};local fakeGame={GetService=function(_,service)
    if service=="RunService" then return {BindToRenderStep=function(_,_,_,fn) render=fn end} end
    return game:GetService(service)
end}
local camera=load(modules.CameraController,fakeGame,{CurrentCamera=fakeCam},{[modules.PresentationConfig]=config})
local ok,err=pcall(function()
    impact.bind(root)
    for _,size in ipairs({Vector2.new(390,722),Vector2.new(676,560),Vector2.new(750,303),Vector2.new(844,332),Vector2.new(1280,722)}) do
        root.Size=UDim2.fromOffset(size.X,size.Y);task.wait(.02)
        for _,event in ipairs({{kind="Skill",source="shuang_xing"},{kind="Death",target="chi_guang",owner="B",cause="LinkTrigger"}}) do
            impact.present(event,1,true);task.wait(.02)
            local g=gui.CinematicLayer.ImpactPresentation
            check("Accent inside "..size.X.."x"..size.Y,g.AbsolutePosition.X>=root.AbsolutePosition.X and g.AbsolutePosition.Y>=root.AbsolutePosition.Y and g.AbsolutePosition.X+g.AbsoluteSize.X<=root.AbsolutePosition.X+size.X+1 and g.AbsolutePosition.Y+g.AbsoluteSize.Y<=root.AbsolutePosition.Y+size.Y+1)
            check("Accent does not capture gameplay input",not g.Active)
            local title=g.ImpactTitle
            if event.kind=="Skill" and size.Y>=380 then
                local portrait=g:FindFirstChild("UnitPortrait")
                check("Cast portrait visible without capturing input",portrait and portrait:IsA("ImageLabel") and not portrait.Active and portrait.AbsolutePosition.X+portrait.AbsoluteSize.X<title.AbsolutePosition.X)
            end
            check("Accent title readable and untruncated",title.TextSize>=20 and title.TextBounds.X<=title.AbsoluteSize.X+1 and title.TextBounds.Y<=title.AbsoluteSize.Y+1)
            if size.Y<380 then check("Short landscape stays above roster",g.AbsolutePosition.Y+g.AbsoluteSize.Y<=root.AbsolutePosition.Y+74) end
            impact.reset();check("Reset destroys previous accent",not gui.CinematicLayer:FindFirstChild("ImpactPresentation"))
        end
        impact.outcome("A",12,1,true);task.wait(.02)
        local g=gui.CinematicLayer.ImpactPresentation
        check("Outcome fits viewport",g.AbsolutePosition.X>=root.AbsolutePosition.X and g.AbsolutePosition.Y>=root.AbsolutePosition.Y and g.AbsolutePosition.X+g.AbsoluteSize.X<=root.AbsolutePosition.X+size.X+1 and g.AbsolutePosition.Y+g.AbsoluteSize.Y<=root.AbsolutePosition.Y+size.Y+1)
        impact.reset()
        impact.present({kind="Death",target="chi_guang",owner="B",actionDeaths=2},1,true);task.wait(.02)
        local chain=gui.CinematicLayer.ImpactPresentation
        check("Double kill uses a readable factual title",chain.ImpactTitle.Text=="双重击破" and chain.ImpactTitle.TextBounds.X<=chain.ImpactTitle.AbsoluteSize.X+1)
        impact.reset()
    end
    impact.present({kind="Skill",source="bai_ji"},.35,false);impact.reset();task.wait(.6)
    check("Cancelled accent cannot resurrect",not gui.CinematicLayer:FindFirstChild("ImpactPresentation"))
    camera.Set("Battle");task.wait(.8);render();local baseline=fakeCam.CFrame
    camera.Resolve({kind="Death"},Vector3.new(6,4,0),.62);task.wait(.09);render()
    check("Death has perceptible bounded camera push",(fakeCam.CFrame.Position-baseline.Position).Magnitude>.3 and (fakeCam.CFrame.Position-baseline.Position).Magnitude<1)
    check("Impact has bounded FOV focus",fakeCam.FieldOfView<config.Camera.Fov and fakeCam.FieldOfView>=config.Camera.Fov-config.Camera.ResolveFov)
    camera.CancelResolve();render();check("Camera cancellation restores base",(fakeCam.CFrame.Position-baseline.Position).Magnitude<.001 and fakeCam.FieldOfView==config.Camera.Fov)
    camera.Reduced=true;camera.Resolve({kind="Death"},Vector3.new(6,4,0),.62);task.wait(.12);render()
    check("Reduced motion has no camera impulse",(fakeCam.CFrame.Position-baseline.Position).Magnitude<.001)
    camera.Reduced=false;camera.Set("Result","B");task.wait(1.2);render()
    check("Defeat ends with a distinct wider frame",math.abs(fakeCam.FieldOfView-config.Camera.DefeatFov)<.001)
    camera.Set("Result","A");task.wait(1.2);render()
    check("Victory ends with the closer result frame",math.abs(fakeCam.FieldOfView-config.Camera.ResultFov)<.001)
    impact.outcome("A",12,1,true);task.wait(.02)
    local winning=gui.CinematicLayer.ImpactPresentation
    check("Victory emblem and title remain separate",winning.OutcomeEmblem:GetAttribute("Winner")=="A" and winning.OutcomeEmblem.AbsolutePosition.Y+winning.OutcomeEmblem.AbsoluteSize.Y<winning.ImpactTitle.AbsolutePosition.Y)
    impact.outcome("B",12,1,true);task.wait(.02)
    check("Defeat has a separate emblem",gui.CinematicLayer.ImpactPresentation.OutcomeEmblem:GetAttribute("Winner")=="B")
    impact.outcome(nil,12,1,true);task.wait(.02)
    check("Draw has a separate emblem and honest title",gui.CinematicLayer.ImpactPresentation.OutcomeEmblem:GetAttribute("Winner")=="Draw" and gui.CinematicLayer.ImpactPresentation.ImpactTitle.Text=="同归于尽")
end)
impact.reset();gui:Destroy();camera.CancelResolve();qa:Destroy()
if not ok then error(err) end
return game:GetService("HttpService"):JSONEncode({scope="disposable GUI and camera fixtures; real TweenService, no physical device or subjective quality evidence",passed=#checks,checks=checks})
