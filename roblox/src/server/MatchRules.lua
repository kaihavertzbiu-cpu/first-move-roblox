local Opening=require(script.Parent.OpeningRules)
local Combat=require(script.Parent.CombatRules)
local Report=require(script.Parent.BattleReport)
local Match={new=Opening.new}
function Match.apply(state,owner,intent)
    if owner~="A" and owner~="B" then return false,"InvalidOwner" end
    if type(intent)~="table" or intent.revision~=state.revision then return false,"StaleRevision" end
    if state.phase=="Draft" or state.phase=="LinkSetup" or state.phase=="CoreSelection" then
        local ok,err=Opening.apply(state,owner,intent)
        if ok and state.phase=="SkillPhase" then Combat.beginRound(state) end
        return ok,err
    end
    local ok,err=Combat.apply(state,owner,intent)
    if ok then state.revision+=1 end
    return ok,err
end
function Match.view(state,owner)
    local view=Opening.view(state,owner)
    view.winner=state.winner
    if state.phase=="GameOver" then view.report=Report.build(state) end
    if state.pending then view.choice={owner=state.pending.owner,source=state.pending.source} end
    if state.attack and state.attack.owner==owner then
        view.ownAttack={attackerId=state.attack.attackerId,targets=table.clone(state.attack.targets),useSkill=state.attack.useSkill}
    end
    for _,side in ipairs({"A","B"}) do
        for i,h in ipairs(state.rosters[side]) do view.rosters[side][i].statuses=table.clone(h.statuses) end
    end
    return view
end
return Match
