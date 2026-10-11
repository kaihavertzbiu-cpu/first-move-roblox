return function()
    local Report=require(script.Parent.BattleReport)
    local state={phase="GameOver",winner="A",round=2,rosters={A={{id="ting_sun",alive=true,hp=7},{id="bai_ji",alive=true,hp=23}},B={{id="yan_wei",alive=false,hp=0},{id="huan_shi",alive=false,hp=0}}},events={
        {kind="CoreReveal",round=1,A="red",B="red"},{kind="CoreTie",round=1},{kind="CoreReveal",round=1,A="cyan",B="purple"},
        {kind="Damage",round=1,source="ting_sun",target="yan_wei",amount=8,effective=5},
        {kind="Death",round=1,target="yan_wei",owner="B"},
        {kind="Damage",round=1,source="yan_wei",target="ting_sun",amount=15,effective=15},
        {kind="Heal",round=1,source="bai_ji",target="ting_sun",amount=3},
        {kind="Block",round=1,source="huan_shi",target="bai_ji"},{kind="RoundEnd",round=1},
        {kind="Execute",round=2,source="ting_sun",target="huan_shi"},{kind="Death",round=2,target="huan_shi",owner="B"},
    }}
    local r=Report.build(state);local count=0
    local function check(v,label) assert(v,label);count+=1 end
    check(r.teams.A.damage==5,"Overkill must not inflate effective damage")
    check(r.teams.B.damage==15,"Dead caster's rattle belongs to its team")
    check(r.teams.A.healing==3,"Only effective heal events count")
    check(r.teams.A.blocks==1 and r.teams.B.blocks==0,"Block belongs to defender")
    check(r.teams.A.executions==1 and r.teams.A.damage==5,"Execution separate from normal damage")
    check(r.completedRounds==1 and r.finalRound==2,"Terminal partial round is not completed")
    check(r.rounds[1].ties==1 and r.rounds[1].initiative=="A","Tie retry stays in same round")
    check(r.teams.A.survivors==2 and r.teams.A.hp==30,"Survivors use terminal roster")
    check(r.turningRound==1 and r.turningDeaths==1,"Turning round ranks deaths then effective damage")
    local ok=pcall(Report.build,{phase="SkillPhase"});check(not ok,"No premature report")
    state.winner="Draw";check(Report.build(state).winner=="Draw","Draw remains distinct")
    print("FIRST_MOVE_REPORT: "..count.." assertions passed")
    return count
end
