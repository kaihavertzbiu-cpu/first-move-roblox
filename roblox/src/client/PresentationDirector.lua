-- Consume only revealed public events in server order; presentation never delays the server.
local Audio=require(script.Parent.AudioController)
local Camera=require(script.Parent.CameraController)
local Table=require(script.Parent.TableController)
local Music=require(script.Parent.MusicController)
local Impact=require(script.Parent.ImpactPresentation)
local Timing=require(script.Parent.PresentationConfig).Resolution
local SoundConfig=require(script.Parent.PresentationConfig).Audio
local HitFeedback=require(script.Parent.PresentationConfig).HitFeedback
local Director={}
local sessionId,eventCount,terminal=nil,0,false
local queue={};local running=false;local serial=0;local terminalView;local onChanged,onEvent
local signatures={};local previous
local displayed={};local latestRosters
local function syncHeroes(rosters)
    for _,team in pairs(rosters or {}) do for _,h in ipairs(team) do displayed[h.id]={hp=h.hp,alive=h.alive,maxHp=h.maxHp} end end
end
function Director.hero(h)
    local shown=displayed[h.id]
    if not shown or not running then return h end
    local copy=table.clone(h);copy.hp=shown.hp;copy.alive=shown.alive;return copy
end
local function applyContact(e)
    local h=displayed[e.target];if not h then return end
    if e.kind=="Damage" then h.hp=math.max(0,h.hp-(e.effective or e.amount or 0))
    elseif e.kind=="Heal" then h.hp=math.min(h.maxHp,h.hp+(e.effective or e.amount or 0))
    elseif e.kind=="Execute" or e.kind=="LinkTrigger" then h.hp=0
    elseif e.kind=="Death" then h.hp=0;h.alive=false end
    e.presentedHp=h.hp;e.presentedAlive=h.alive
end
local deaths={A=0,B=0}
local function noteDeath(event)
    if event.kind=="ActionStart" or event.kind=="RoundEnd" then deaths={A=0,B=0} end
    if event.kind=="Death" and deaths[event.owner]~=nil then
        deaths[event.owner]=math.min(Timing.MaxActionDeaths,deaths[event.owner]+1)
        return deaths[event.owner]
    end
end
local cues={CoreReveal="reveal",CoreTie="reveal",Damage="hit",Heal="heal",Block="block",Death="death",LinkTrigger="link",Execute="execute",Skill="skill",Lock="lock"}
local function cue(event)
    if event.kind=="Damage" then return event.damageType=="Reflection" and "reflect" or event.damageType=="Bleeding" and "bleed" or (event.impactTier==3 and "hit_crushing" or event.impactTier==2 and "hit_heavy" or "hit") end
    if event.kind=="Skill" then return SoundConfig.SkillCues[event.code] or "skill" end
    if event.kind=="Death" and event.owner=="B" and (event.actionDeaths or 0)>1 then
        return "chain",math.min(SoundConfig.ChainPitchMaximum,SoundConfig.Cues.chain.speed+(event.actionDeaths-2)*SoundConfig.ChainPitchStep)
    end
    return cues[event.kind]
end
function Director.bind(root) Impact.bind(root) end
function Director.reset()
    serial+=1;sessionId=nil;eventCount=0;terminal=false;terminalView=nil;queue={};running=false;onChanged=nil;onEvent=nil;signatures={};previous=nil
    deaths={A=0,B=0};Audio.Reset();Impact.reset()
    displayed={};latestRosters=nil
    if Camera.CancelResolve then Camera.CancelResolve() end
    if Table.cancelPresentation then Table.cancelPresentation() end
end
function Director.resolving() return running or #queue>0 end
local function duration(event)
    if Camera.Reduced then return (event.kind=="Skill" or event.kind=="Death") and Timing.MajorMinimum or Timing.MinimumStep end
    if event.kind=="Damage" and (event.damageType=="Reflection" or event.damageType=="Bleeding" or event.damageType=="Normal" and (event.source=="huan_shi" or event.target=="lan_dun")) then return Timing.Passive end
    if event.kind=="Damage" and event.impactTier then return HitFeedback.Holds[event.impactTier] end
    return event.kind=="CoreReveal" and Timing.Core or event.kind=="Skill" and Timing.Skill or event.kind=="Block" and Timing.Block or event.kind=="Execute" and Timing.Execute or event.kind=="LinkTrigger" and Timing.Link or event.kind=="Heal" and Timing.Heal or event.kind=="Death" and ((event.actionDeaths or 0)>1 and Timing.CompactChainDeath or Timing.Death) or event.damageType=="DeathRattle" and Timing.Skill or Timing.Step
end
local function completed(ticket)
    if ticket~=serial then return end
    running=false
    syncHeroes(latestRosters)
    if onChanged then onChanged() end
end
local function finish(ticket)
    if ticket~=serial then return end
    if terminalView and not terminal then
        terminal=true
        local hold=Camera.Reduced and Timing.MajorMinimum or Timing.Outcome
        Camera.Set("Result",terminalView.winner);Music.Result();Audio.Outcome(terminalView.winner)
        if Table.outcome then Table.outcome(terminalView.winner,hold) end
        Impact.outcome(terminalView.winner,terminalView.round or 0,hold,Camera.Reduced)
        task.delay(hold,function() completed(ticket) end)
    else completed(ticket) end
end
local function step(ticket)
    if ticket~=serial then return end
    local item=table.remove(queue,1)
    if not item then
        if terminalView and not terminal then task.delay(Camera.Reduced and 0 or Timing.TerminalPause,function() finish(ticket) end)
        else finish(ticket) end
        return
    end
    local hold=Camera.Reduced and duration(item.event) or item.duration
    local e=item.event
    local attack=not Camera.Reduced and e.source and e.target and e.source~=e.target
        and (e.kind=="Block" or e.kind=="Execute" or e.kind=="Damage" and e.damageType~="Bleeding" and e.damageType~="Reflection")
    local lead=attack and math.min(Timing.ContactLead,hold*.32) or 0
    if lead>0 and Table.approach then Table.approach(e,lead) end
    local function contact()
        if serial~=ticket then return end
        applyContact(e)
        e.approached=lead>0
        if Impact.contact and (e.kind=="Damage" or e.kind=="Block" or e.kind=="Execute" or e.kind=="Heal" or e.kind=="Lock") then Impact.contact(e,Camera.Reduced) end
        Audio.Play(cue(e));Table.present(e,hold-lead);Impact.present(e,hold-lead,Camera.Reduced)
        if onEvent then onEvent(e,hold-lead,item.index) end
        Camera.Resolve(e,Table.focus and Table.focus(e),hold-lead)
    end
    if lead>0 then task.delay(lead,contact) else contact() end
    task.delay(hold,function() step(ticket) end)
end
function Director.update(view,changed,revealed)
    if view.sessionId~=sessionId or #view.events<eventCount then
        Director.reset();sessionId=view.sessionId;eventCount=#view.events;Camera.Set("Battle")
        syncHeroes(view.rosters)
        for _,event in ipairs(view.events) do noteDeath(event) end
        previous=view.events[#view.events]
    end
    latestRosters=view.rosters
    for _,team in pairs(view.rosters or {}) do for _,h in ipairs(team) do if not displayed[h.id] then displayed[h.id]={hp=h.hp,alive=h.alive,maxHp=h.maxHp} end end end
    onChanged=changed;onEvent=revealed;Music.Update(view)
    local batch={};local total=0
    for i=eventCount+1,#view.events do
        local public=view.events[i]
        if public.kind=="ActionStart" or public.kind=="RoundEnd" or public.kind=="AttackCommitted" then signatures={} end
        local event=table.clone(public)
        if event.kind=="Damage" and event.damageType~="Bleeding" and event.damageType~="Reflection" then
            local damage=event.effective or event.amount or 0
            event.impactTier=damage>=HitFeedback.Crushing and 3 or damage>=HitFeedback.Heavy and 2 or 1
        end
        event.actionDeaths=noteDeath(public)
        if event.kind=="Skill" then signatures[event.source]=event.code end
        if event.kind=="Damage" and event.damageType=="Normal" then event.skillCode=signatures[event.source] end
        if event.kind=="Death" and previous and previous.target==event.target then
            event.cause=(previous.kind=="Execute" or previous.kind=="LinkTrigger") and previous.kind or nil
        end
        if cues[event.kind] then local hold=duration(event);table.insert(batch,{event=event,duration=hold,index=i});total+=hold end
        previous=public
    end
    eventCount=#view.events
    local factor=total>Timing.BatchBudget and Timing.BatchBudget/total or 1
    for _,item in ipairs(batch) do
        local minimum=(item.event.kind=="Skill" or item.event.kind=="Death" or item.event.kind=="Execute") and Timing.MajorMinimum or Timing.MinimumStep
        item.duration=math.max(minimum,item.duration*factor);table.insert(queue,item)
    end
    if view.phase=="GameOver" then terminalView=view end
    if not running and (#queue>0 or terminalView and not terminal) then running=true;local ticket=serial;task.defer(function() step(ticket) end) end
end
return Director
