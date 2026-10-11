-- Deterministic impact framing; no random shake, roll, gameplay delay or private state.
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Config=require(script.Parent.PresentationConfig)
local Camera={Reduced=false,Counts={}}
local target=Instance.new("CFrameValue");target.Value=Config.Camera.Menu
local fov=Instance.new("NumberValue");fov.Value=Config.Camera.Fov
local impact=Instance.new("NumberValue")
local tween,fovTween,impactTween;local serial=0;local focusX=0
function Camera.CancelResolve()
    serial+=1;if impactTween then impactTween:Cancel() end;impact.Value=0;focusX=0
end
function Camera.Set(screen,winner)
    if tween then tween:Cancel() end
    Camera.Screen=screen;Camera.CancelResolve()
    local destination=Camera.Reduced and screen=="Result" and Config.Camera.Battle or Config.Camera[screen] or Config.Camera.Menu
    local duration=Camera.Reduced and 0 or screen=="Result" and Config.Camera.ResultTime or Config.CameraTime
    local nextFov=screen=="Menu" and Config.Camera.MenuFov or Config.Camera.Fov
    if screen=="Result" and not Camera.Reduced then nextFov=winner=="B" and Config.Camera.DefeatFov or Config.Camera.ResultFov end
    if fovTween then fovTween:Cancel() end
    fovTween=TweenService:Create(fov,TweenInfo.new(duration,Enum.EasingStyle.Sine),{Value=nextFov});fovTween:Play()
    tween=TweenService:Create(target,TweenInfo.new(duration,Enum.EasingStyle.Sine),{Value=destination});tween:Play()
end
function Camera.Resolve(event,position,hold)
    if Camera.Reduced or Camera.Screen~="Battle" then return end
    local kind=event and event.kind or "Death"
    local weight=Config.Camera.ImpactWeights[kind]
    if event and event.impactTier then weight=Config.HitFeedback.Weights[event.impactTier] end
    if not weight then return end
    if event and event.damageType=="Bleeding" then return end
    serial+=1;local ticket=serial
    if impactTween then impactTween:Cancel() end
    focusX=position and math.clamp(position.X/6,-1,1) or 0
    Camera.Counts[kind]=(Camera.Counts[kind] or 0)+1
    local attack=math.min(Config.Camera.ResolveIn,(hold or .3)*.3)
    impactTween=TweenService:Create(impact,TweenInfo.new(attack,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Value=weight});impactTween:Play()
    task.delay(attack,function()
        if serial~=ticket then return end
        local release=math.min(Config.Camera.ResolveOut,math.max(.08,(hold or .3)-attack))
        impactTween=TweenService:Create(impact,TweenInfo.new(release,Enum.EasingStyle.Sine),{Value=0});impactTween:Play()
    end)
end
RunService:BindToRenderStep("DeadlockCamera",Enum.RenderPriority.Camera.Value+1,function()
    local cam=workspace.CurrentCamera;if not cam then return end
    cam.CameraType=Enum.CameraType.Scriptable
    local amount=Camera.Reduced and 0 or impact.Value
    cam.FieldOfView=fov.Value-amount*Config.Camera.ResolveFov
    local drift=not Camera.Reduced and Camera.Screen~="Battle" and Camera.Screen~="Result" and math.sin(os.clock()*.16)*.13 or 0
    cam.CFrame=target.Value*CFrame.new(drift+focusX*Config.Camera.ResolvePan*amount,0,-Config.Camera.ResolvePush*amount)*CFrame.Angles(0,-focusX*math.rad(Config.Camera.ResolveFocus)*amount,0)
    cam.Focus=CFrame.new(0,4.8,0)
end)
return Camera
