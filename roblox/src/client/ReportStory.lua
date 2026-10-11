-- A factual summary of revealed terminal events, not a claim about hidden intent.
local Identity=require(script.Parent.UnitIdentity)
local Locale=require(script.Parent.LocaleController)
local Story={}
local function name(id) return Locale.translate(Identity.name(id)) end
local function fatal(source,target,damageType)
    local types={Normal="attack",Skill="skill",Bleeding="bleed",Reflection="reflection",DeathRattle="deathrattle"}
    if Locale.isEnglish() then return name(source).."'s "..(types[damageType]or"damage").." eliminated "..name(target) end
    local cn={Normal="普攻",Skill="技能",Bleeding="流血",Reflection="反伤",DeathRattle="亡语"}
    return name(source).."的"..(cn[damageType]or"伤害").."使"..name(target).."阵亡"
end
function Story.event(event)
    local kind=event.kind
    if Locale.isEnglish() then
        local source,target=name(event.source),name(event.target)
        if kind=="Damage"then return source.." → "..target.." −"..tostring(event.effective or event.amount).." / "..(({Normal="Attack",Skill="Skill",Bleeding="Bleed",Reflection="Reflection",DeathRattle="Deathrattle"})[event.damageType]or"Damage")end
        if kind=="Heal"then return source.." → "..target.." +"..tostring(event.amount).." / Heal"end
        if kind=="Block"then return target.." blocked "..source.."'s attack"end
        if kind=="Death"then return target.." was eliminated"end
        if kind=="Execute"then return source.." executed "..target.." with Soul Reap"end
        if kind=="LinkTrigger"then return source.." fell; Life Tether took "..target.." with them"end
        if kind=="Skill"then local unit=Identity.byId[event.source];return source.." used "..Locale.translate(unit and unit.skill.name or"技能")end
        if kind=="Lock"then return target.." was locked out"end
        if kind=="CoreReveal"then local cores={red="Order",cyan="Crescent",purple="Wastes"};return "Core reveal: You · "..(cores[event.A]or"Unknown").." / Opponent · "..(cores[event.B]or"Unknown")end
        if kind=="CoreTie"then return "Same core — choose again"end
        if kind=="AttackCommitted"then return (event.owner=="A"and"You"or"Opponent").." committed an attack"end
        if kind=="ActionStart"then return (event.owner=="A"and"Your"or"Opponent's").." action began"end
        if kind=="RoundEnd"then return "Round ended"end
    end
    if kind=="Damage" then return name(event.source).." → "..name(event.target).." −"..tostring(event.effective or event.amount).." / "..(({Normal="普攻",Skill="技能",Bleeding="流血",Reflection="反伤",DeathRattle="亡语"})[event.damageType] or "伤害") end
    if kind=="Heal" then return name(event.source).." → "..name(event.target).." +"..tostring(event.amount).." / 恢复" end
    if kind=="Block" then return name(event.target).."挡住了"..name(event.source).."的攻击" end
    if kind=="Death" then return name(event.target).."阵亡" end
    if kind=="Execute" then return name(event.source).."以掠魂处决"..name(event.target) end
    if kind=="LinkTrigger" then return name(event.source).."阵亡，命线带走"..name(event.target) end
    if kind=="Skill" then local unit=Identity.byId[event.source];return name(event.source).."释放"..(unit and unit.skill.name or "技能") end
    if kind=="Lock" then return name(event.target).."被封锁" end
    if kind=="CoreReveal" then local cores={red="秩序",cyan="新月",purple="荒芜"};return "能核揭示：你 · "..(cores[event.A] or "未知").." / 对手 · "..(cores[event.B] or "未知") end
    if kind=="CoreTie" then return "能核相同，重新暗选" end
    if kind=="AttackCommitted" then return (event.owner=="A" and "你" or "对手").."已承诺进攻" end
    if kind=="ActionStart" then return (event.owner=="A" and "你" or "对手").."开始行动" end
    if kind=="RoundEnd" then return "本回合结束" end
end
function Story.build(view)
    local result={title=view.winner=="A" and "胜利" or view.winner=="B" and "失利" or view.winner=="Draw" and "同归于尽" or "行动结束",lines={}}
    local final=view.round;local events=view.events or {};local candidates={}
    for i,event in ipairs(events) do
        local label
        if event.kind=="Execute" then label=Story.event(event)
        elseif event.kind=="LinkTrigger" then label=Story.event(event)
        elseif event.kind=="Damage" and event.damageType=="DeathRattle" then label=Story.event(event)
        elseif event.kind=="Death" then
            local cause
            for j=i-1,1,-1 do
                local previous=events[j]
                if previous.round~=event.round then break end
                if previous.target==event.target and (previous.kind=="Damage" or previous.kind=="Execute" or previous.kind=="LinkTrigger") then cause=previous;break end
            end
            if cause and cause.kind=="Damage" and cause.damageType~="DeathRattle" then
                local types={Normal="普攻",Skill="技能",Bleeding="流血",Reflection="反伤"}
                label=fatal(cause.source,event.target,cause.damageType)
            elseif not cause then label=Story.event(event) end
        end
        if label then table.insert(candidates,{round=event.round,text=label}) end
    end
    -- Show up to three final-round facts in their actual order; earlier facts only if needed.
    local start=math.max(1,#candidates-2)
    for i=start,#candidates do table.insert(result.lines,candidates[i]) end
    if #result.lines==0 then table.insert(result.lines,{round=final,text="终局已由服务器确认"}) end
    result.subtitle=view.winner=="A" and "对手阵容全部阵亡，行动完成。" or view.winner=="B" and "己方阵容全部阵亡，行动结束。" or view.winner=="Draw" and "死亡连锁结束后，双方阵容全部阵亡。" or "等待服务器确认结果。"
    local owners={}
    for side,roster in pairs(view.rosters or {}) do for _,h in ipairs(roster) do owners[h.id]=side end end
    local lastDeath
    for i=#events,1,-1 do if events[i].kind=="Death" then lastDeath=i;break end end
    result.closing={round=final,steps={},summary="终局已由服务器确认",partial=false}
    if lastDeath then
        local first=lastDeath
        for i=lastDeath-1,1,-1 do
            local event=events[i]
            if event.round~=events[lastDeath].round or event.kind=="RoundEnd" then break end
            first=i
            if event.kind=="AttackCommitted" or event.kind=="Skill" or event.kind=="ActionStart" or event.kind=="CoreReveal" then break end
        end
        local closing=result.closing
        closing.round=events[lastDeath].round
        closing.partial=first==1 and events[first].kind~="AttackCommitted" and events[first].kind~="Skill" and events[first].kind~="ActionStart" and events[first].kind~="CoreReveal"
        local cause
        for i=lastDeath-1,first,-1 do
            local event=events[i]
            if event.target==events[lastDeath].target and (event.kind=="Damage" or event.kind=="Execute" or event.kind=="LinkTrigger") then cause=event;break end
        end
        closing.source=cause and cause.source;closing.target=events[lastDeath].target
        local summary=cause and Story.event(cause) or (Locale.isEnglish()and name(closing.target).." was eliminated. Operation ended."or name(closing.target).."阵亡，行动结束")
        if cause and cause.kind=="Damage" then
            local types={Normal="普攻",Skill="技能",Bleeding="流血",Reflection="反伤",DeathRattle="亡语"}
            summary=fatal(cause.source,closing.target,cause.damageType)
        end
        closing.summary=view.winner=="Draw" and "死亡连锁结束 · 双方阵容全部阵亡" or summary
        for i=first,lastDeath do
            local event=events[i];local label=Story.event(event)
            if label then
                if event.kind=="AttackCommitted" then label="进攻已承诺" elseif event.kind=="ActionStart" then label="行动开始" end
                local unit=event.kind=="Block" and event.target or event.source or event.target
                local side=event.owner or owners[unit]
                table.insert(closing.steps,{index=i,kind=event.kind,unit=unit,side=side,text=label})
            end
        end
    end
    return result
end
return Story
