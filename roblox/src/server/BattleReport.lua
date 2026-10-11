-- Derived on the server after terminal resolution; never accepts client statistics.
local Config=require(game:GetService("ReplicatedStorage").DeadlockShared.LegacyConfig)
local Report={}
local function totals()
    return {damage=0,healing=0,blocks=0,executions=0,links=0,skills=0,survivors=0,hp=0}
end
function Report.build(state)
    assert(state.phase=="GameOver","Report requires terminal state")
    local result={schemaVersion=1,winner=state.winner,finalRound=state.round,completedRounds=0,teams={A=totals(),B=totals()},rounds={}}
    local owners,roundMap={},{}
    for _,side in ipairs({"A","B"}) do for _,h in ipairs(state.rosters[side]) do
        owners[h.id]=side
        if h.alive then result.teams[side].survivors+=1;result.teams[side].hp+=h.hp end
    end end
    for _,e in ipairs(state.events) do
        if e.round<1 then continue end
        local row=roundMap[e.round]
        if not row then row={round=e.round,ties=0,teams={A=totals(),B=totals()},fallen={}};roundMap[e.round]=row;table.insert(result.rounds,row) end
        local side=owners[e.source]
        local key,amount
        if e.kind=="Damage" then key="damage";amount=e.effective
        elseif e.kind=="Heal" then key="healing";amount=e.amount
        elseif e.kind=="Block" then key="blocks";amount=1;side=owners[e.target]
        elseif e.kind=="Execute" then key="executions";amount=1
        elseif e.kind=="LinkTrigger" then key="links";amount=1
        elseif e.kind=="Skill" then key="skills";amount=1
        elseif e.kind=="Death" then table.insert(row.fallen,{id=e.target,owner=owners[e.target]})
        elseif e.kind=="RoundEnd" then result.completedRounds+=1;row.completed=true
        elseif e.kind=="CoreTie" then row.ties+=1
        elseif e.kind=="CoreReveal" and e.A~=e.B then row.initiative=Config.beats[e.A]==e.B and "A" or "B";row.cores={A=e.A,B=e.B}
        end
        if key and side then result.teams[side][key]+=amount;row.teams[side][key]+=amount end
    end
    local turning
    for _,row in ipairs(result.rounds) do
        if not turning or #row.fallen>#turning.fallen or (#row.fallen==#turning.fallen and row.teams.A.damage+row.teams.B.damage>turning.teams.A.damage+turning.teams.B.damage) then turning=row end
    end
    if turning then result.turningRound=turning.round;result.turningDeaths=#turning.fallen end
    return result
end
return Report
