-- Original, bounded spatial feedback. Only already-revealed events may enter here.
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Config=require(script.Parent.PresentationConfig)
local C,F=Config.Colors,Config.TableFeedback
local Effects={}
local supported={Damage=true,Heal=true,Execute=true,LinkTrigger=true,Death=true,Block=true,Lock=true,Skill=true}
function Effects.new(parent)
    local folder=Instance.new("Folder");folder.Name="LocalResolutionEffects";folder.Parent=parent
    local self={Folder=folder,Counts={},PeakParts=0}
    local active={}
    local function part(kind,color,size,cf,alpha,lifetime)
        local children=folder:GetChildren()
        if #children>=F.MaximumParts then children[1]:Destroy() end
        local p=Instance.new("Part")
        p.Name="Revealed"..kind;p:SetAttribute("EventKind",kind)
        p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
        p.Material=Enum.Material.Neon;p.Color=color;p.Transparency=alpha;p.Size=size;p.CFrame=cf;p.Parent=folder
        active[p]={}
        p.Destroying:Connect(function() for _,t in ipairs(active[p] or {}) do t:Cancel() end;active[p]=nil end)
        Debris:AddItem(p,lifetime+F.Tail)
        self.PeakParts=math.max(self.PeakParts,#folder:GetChildren())
        return p
    end
    local function animate(p,time,goal,reduced)
        if reduced then return end
        local t=TweenService:Create(p,TweenInfo.new(time,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),goal)
        table.insert(active[p],t);t:Play()
    end
    local function segment(kind,a,b,color,time,reduced,alpha)
        local length=(b-a).Magnitude;if length<.01 then return end
        local p=part(kind,color,Vector3.new(F.LineWidth,F.LineWidth,length),CFrame.lookAt((a+b)/2,b),alpha or .45,time)
        animate(p,time,{Transparency=1},reduced);return p
    end
    local function ring(kind,position,color,time,reduced,lift,radius,expand,segments)
        local center=Vector3.new(position.X,F.SurfaceY,position.Z)
        local steps=reduced and 4 or segments or F.Segments
        radius=radius or F.Radius
        for i=0,steps-1 do
            local a,b=i*2*math.pi/steps,(i+.78)*2*math.pi/steps
            local p=segment(kind,center+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius),center+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius),color,time,reduced)
            if p and not reduced then
                local nextRadius=expand or radius
                local offset=(p.Position-center)*(nextRadius/radius)
                animate(p,time,{CFrame=CFrame.new(center+offset+Vector3.new(0,lift or 0,0))*p.CFrame.Rotation,Size=Vector3.new(F.LineWidth,F.LineWidth,p.Size.Z*nextRadius/radius),Transparency=1},false)
            end
        end
    end
    local function brackets(kind,position,color,time,reduced,close)
        for _,axis in ipairs({Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1)}) do
            local center=Vector3.new(position.X,F.SurfaceY,position.Z)
            local a=center+axis*F.Radius;local b=center+axis*(F.Radius+.16)
            local p=segment(kind,a,b,color,time,reduced,.28)
            if p and not reduced then animate(p,time,{CFrame=p.CFrame+axis*(close and -F.Radius*.75 or F.Radius*.6),Transparency=1},false) end
        end
    end
    local function travel(event,source,target,color,time,reduced,broken)
        if not source or source==target then return end
        local a,b=source.Position,target.Position
        if broken then
            for i=0,4 do segment(event.kind,a:Lerp(b,i/5),a:Lerp(b,(i+.6)/5),color,time,reduced,.55) end
        else segment(event.kind,a,b,color,time,reduced,.62) end
        if reduced then return end
        local p=part(event.kind,color,Vector3.new(.10,.10,.10),CFrame.new(a),.22,time)
        p.Shape=Enum.PartType.Ball
        animate(p,time,{CFrame=CFrame.new(b)},false)
        animate(p,time,{Transparency=1},false)
    end
    local function shards(kind,position,color,time,reduced,count)
        if reduced then return end
        for i=1,count or F.ShardCount do
            local angle=i*math.pi*2/(count or F.ShardCount)
            local axis=Vector3.new(math.cos(angle),0,math.sin(angle))
            local p=part(kind,color,Vector3.new(.035,.16,.035),CFrame.new(position+axis*.12),.23,time)
            animate(p,time,{CFrame=CFrame.new(position+axis*F.ShardTravel+Vector3.new(0,F.ShardHeight*(i%2==0 and 1 or .5),0))*CFrame.Angles(0,angle,math.pi*.35),Size=Vector3.new(.02,.05,.02),Transparency=1},false)
        end
    end
    local skills={group_heal=true,stasis_lock=true,thunder_judgment=true,rail_shot=true,fury_press=true,final_barrage=true,overload_explode=true}
    local function cast(event,source,time,reduced)
        if not source or not skills[event.code] then return false end
        local center=source.Position
        local code=event.code
        local color=code=="group_heal" and C.Cyan or code=="stasis_lock" and F.LinkColor or C.Amber
        if reduced then ring("Skill",center,color,time,true);return true end
        if code=="group_heal" then
            ring("Skill",center,C.Cyan,time,false,.6,F.SkillRadius,F.SkillRadius*1.4)
            ring("Skill",center+Vector3.new(0,.25,0),C.Paper,time,false,.35,F.SkillRadius*.6,F.SkillRadius)
            for i=0,2 do
                local angle=i*math.pi*2/3
                local p=part("Skill",C.Cyan,Vector3.new(.045,.36,.045),CFrame.new(center+Vector3.new(math.cos(angle)*.4,-.2,math.sin(angle)*.4)),.3,time)
                animate(p,time,{CFrame=p.CFrame+Vector3.new(0,.9,0),Size=Vector3.new(.02,.12,.02),Transparency=1},false)
            end
        elseif code=="rail_shot" or code=="fury_press" then
            for _,side in ipairs({-1,1}) do
                local p=part("Skill",color,Vector3.new(code=="fury_press" and .18 or .055,.65,.055),CFrame.new(center+Vector3.new(side*.3,.1,0)),.25,time)
                animate(p,time,{CFrame=p.CFrame+Vector3.new(side*.14,.6,0),Size=Vector3.new(.035,1.1,.035),Transparency=1},false)
            end
            brackets("Skill",center,color,time,false,true)
        elseif code=="stasis_lock" then
          for i=0,3 do
                local angle=i*math.pi/2
                local p=part("Skill",F.LinkColor,Vector3.new(.045,.55,.045),CFrame.new(center+Vector3.new(math.cos(angle)*.55,0,math.sin(angle)*.55)),.23,time)
                animate(p,time,{CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*.25,.2,math.sin(angle)*.25)),Transparency=1},false)
            end
        elseif code=="thunder_judgment" then
            for i=0,2 do
                local a,b=i*math.pi*2/3,(i+1)*math.pi*2/3
                local p=segment("Skill",center+Vector3.new(math.cos(a)*F.SkillRadius,.35,math.sin(a)*F.SkillRadius),center+Vector3.new(math.cos(b)*F.SkillRadius,.35,math.sin(b)*F.SkillRadius),C.Paper,time,false,.20)
                animate(p,time,{CFrame=p.CFrame+Vector3.new(0,.6,0),Transparency=1},false)
            end
        else
            ring("Skill",center,color,time,false,.15,F.SkillRadius,code=="final_barrage" and 1.5 or 1.1)
            shards("Skill",center,color,time,false,code=="final_barrage" and 6 or 4)
        end
        return true
    end
    function self.approach(event,source,target,hold,reduced)
        if source and target then travel(event,source,target,C.Amber,hold,reduced) end
    end
    function self.present(event,source,target,hold,reduced)
        if not supported[event.kind] then return false end
        local time=reduced and F.ReducedTime or math.clamp(hold or .3,F.MinimumTime,F.MaximumTime)
        if event.kind=="Skill" then
            local emitted=cast(event,source,time,reduced)
            if emitted then self.Counts.Skill=(self.Counts.Skill or 0)+1 end
            return emitted
        end
        if not target then return false end
        self.Counts[event.kind]=(self.Counts[event.kind] or 0)+1
        local kind=event.kind
        if kind=="Damage" then
            local color=event.damageType=="Reflection" and C.Paper or event.damageType=="Bleeding" and F.BleedColor or C.Amber
            if event.damageType~="Bleeding" and not event.approached then travel(event,source,target,color,time,reduced) end
            brackets(kind,target.Position,color,time,reduced,false)
            if event.impactTier and event.impactTier>=2 then
                ring(kind,target.Position,C.Amber,time,reduced,0,F.Radius,Config.HitFeedback.Radii[event.impactTier])
                shards(kind,target.Position,C.Paper,time,reduced,event.impactTier==3 and 6 or 3)
            end
            if event.damageType=="DeathRattle" then
                ring(kind,target.Position,C.Paper,time,reduced,0,F.Radius,F.ShockRadius)
                shards(kind,target.Position,C.Amber,time,reduced)
            elseif event.skillCode=="fury_press" then
                ring(kind,target.Position,C.Amber,time,reduced,0,F.Radius,F.ShockRadius)
                shards(kind,target.Position,C.Amber,time,reduced,4)
            elseif event.skillCode=="rail_shot" and source and not reduced then
                for _,side in ipairs({-1,1}) do segment(kind,source.Position+Vector3.new(side*.09,0,0),target.Position+Vector3.new(side*.09,0,0),C.Paper,time,false,.35) end
            elseif event.damageType=="Reflection" then ring(kind,target.Position,C.Paper,time,reduced,.15) end
        elseif kind=="Heal" then
            travel(event,source,target,C.Cyan,time,reduced)
            ring(kind,target.Position,C.Cyan,time,reduced,.3)
        elseif kind=="Execute" then
            if not event.approached then travel(event,source,target,C.Amber,time,reduced) end
            brackets(kind,target.Position,C.Paper,time,reduced,true)
            if not reduced then
                for _,angle in ipairs({25,-55}) do
                    local cut=part(kind,C.Paper,Vector3.new(.06,1.65,.04),target.CFrame*CFrame.Angles(0,0,math.rad(angle)),.18,time)
                    animate(cut,time,{Size=Vector3.new(.015,2.15,.02),CFrame=cut.CFrame+Vector3.new(0,-.18,0),Transparency=1},false)
                end
                ring(kind,target.Position,C.Amber,time,false,0,F.Radius,F.ShockRadius)
            end
        elseif kind=="LinkTrigger" then
            travel(event,source,target,F.LinkColor,time,reduced,true)
            brackets(kind,target.Position,F.LinkColor,time,reduced,true)
        elseif kind=="Death" then
            if reduced then brackets(kind,target.Position,C.Muted,time,true,true)
            else
                for i=-1,1 do
                    local p=part(kind,C.Muted,Vector3.new(.045,target.Size.Y*.65,.045),target.CFrame+Vector3.new(i*.15,0,0),.55,time)
                    animate(p,time,{Size=Vector3.new(.045,.05,.045),CFrame=CFrame.new(target.Position+Vector3.new(i*.20,-.3,0)),Transparency=1},false)
                end
                ring(kind,target.Position,event.owner=="B" and C.Amber or C.Cyan,time,false,0,F.Radius,F.ShockRadius)
                shards(kind,target.Position,event.owner=="B" and C.Amber or C.Cyan,time,false)
            end
        elseif kind=="Block" then
            if reduced then ring(kind,target.Position,C.Cyan,time,true)
            else
                local direction=source and (source.Position-target.Position)*Vector3.new(1,0,1) or Vector3.new(0,0,-1)
                direction=direction.Magnitude>.01 and direction.Unit or Vector3.new(0,0,-1)
                local face=CFrame.lookAt(target.Position+direction*.2,target.Position+direction)
                local shield={{-.5,.20},{-.36,.60},{.36,.60},{.5,.20},{.30,-.50},{-.30,-.50}}
                for i,a in ipairs(shield) do
                    local b=shield[i%#shield+1]
                    local p=segment(kind,face:PointToWorldSpace(Vector3.new(a[1],a[2],0)),face:PointToWorldSpace(Vector3.new(b[1],b[2],0)),C.Cyan,time,false,.20)
                    if p then animate(p,time,{CFrame=p.CFrame+direction*.22,Transparency=1},false) end
                end
                local p=part(kind,C.Cyan,Vector3.new(.84,.94,.025),face,.90,time)
                animate(p,time,{CFrame=p.CFrame+direction*.22,Transparency=1},false)
            end
        elseif kind=="Lock" then brackets(kind,target.Position,C.Amber,time,reduced,true) end
        return true
    end
    function self.outcome(winner,hold,reduced)
        local time=reduced and F.ReducedTime or math.clamp(hold,F.MinimumTime,F.MaximumTime)
        local color=winner=="A" and C.Cyan or winner=="B" and C.Muted or C.Amber
        self.Counts.Outcome=(self.Counts.Outcome or 0)+1
        ring("Outcome",Vector3.new(0,F.SurfaceY,0),color,time,reduced,.25,1.2,F.OutcomeRadius,F.OutcomeSegments)
        if not reduced then
            local center=Vector3.new(0,5.1,winner=="A" and -2.4 or 2.4)
            local core=part("Outcome",color,Vector3.new(.9,.9,.9),CFrame.new(center)*CFrame.Angles(0,math.pi/4,math.pi/4),.15,time)
            animate(core,time*.35,{Size=Vector3.new(.08,.08,.08),Transparency=1},false)
            for i=0,11 do
                  local angle=i*math.pi/6
                  local center=Vector3.new(0,5.1,winner=="A" and -2.4 or 2.4)
                  local p=part("Outcome",color,Vector3.new(.18,.7,.22),CFrame.new(center)*CFrame.Angles(angle,angle,angle),.12,time)
                  animate(p,time,{CFrame=CFrame.new(center+Vector3.new(math.cos(angle)*3.2,winner=="A" and 1.5 or -1.1,math.sin(angle)*2.2))*CFrame.Angles(angle*3,angle*2,angle),Transparency=1},false)
            end
        end
    end
    function self.reset()
        for _,p in ipairs(folder:GetChildren()) do p:Destroy() end
    end
    return self
end
return Effects
