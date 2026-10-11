-- Teaching scenarios execute the shipping rules. They never create competitive results.
local Rules=require(script.Parent.MatchRules)
local Training={}
local picks={"lan_dun","xuan_bao","shuang_xing","bai_ji","beng_yue","chi_guang","huan_shi","zhe_jing","ting_sun","zhui_lie"}
local owners={"A","B","B","A","A","B","B","A","A","B"}
local function apply(state,owner,action)
    action.revision=state.revision
    local ok,err=Rules.apply(state,owner,action);assert(ok,err)
end
function Training.new(revision)
    local state=Rules.new()
    for i,id in ipairs(picks) do apply(state,owners[i],{kind="DraftPick",heroId=id}) end
    apply(state,"A",{kind="CoreLock",core="red"})
    apply(state,"B",{kind="CoreLock",core="purple"})
    -- The injured support exercise is established by a real prior rules round.
    apply(state,"B",{kind="SkillEnd"})
    apply(state,"B",{kind="AttackCommit",attackerId="shuang_xing",targets={"lan_dun"},useSkill=false})
    apply(state,"A",{kind="BlockCommit"})
    apply(state,"A",{kind="SkillEnd"})
    apply(state,"A",{kind="AttackCommit",attackerId="lan_dun",targets={"xuan_bao"},useSkill=false})
    apply(state,"B",{kind="BlockCommit"})
    apply(state,"A",{kind="CoreLock",core="red"})
    apply(state,"B",{kind="CoreLock",core="purple"})
    apply(state,"B",{kind="SkillEnd"})
    apply(state,"B",{kind="AttackCommit",attackerId="shuang_xing",targets={"bai_ji"},useSkill=false})
    if revision then state.revision=math.max(state.revision,revision) end
    return state,{step=1,feedback=nil,complete=false,hit=false,skillUsed=false}
end
function Training.model(t)
    local model
    if t.complete then model={step=4,feedback="complete",title="训练完成",body="你保护了复苏、用技能恢复了哨卫，并完成进攻承诺。技能窗口与普攻是两次不同的决策；攻击技能还要独立启用。正式对局中，你需要自己判断对手意图。",complete=true}
    elseif t.feedback then model={step=1,feedback=t.hit and "success" or "miss",title=t.hit and "格挡命中" or "格挡未命中",body=t.hit and "你让复苏保护自己，正好挡住了双轨的攻击。接下来练习恢复受伤的哨卫。" or "格挡只保护你选中的那名单位，不会替队友承伤。观察教学提示，再试一次。",complete=false}
    elseif t.step==1 then model={step=1,title="保护支援单位",body="教学对手倾向攻击支援单位。复苏负责恢复；点选它，再确认格挡。哨卫已在前一回合受伤，稍后将练习恢复。",complete=false}
    elseif t.step==2 then model={step=2,title="恢复哨卫",body="哨卫现在为 23 / 26 生命。选择复苏，再释放修复脉冲，恢复所有受伤的己方单位。使用技能后仍有一次普攻。",complete=false,requiredCaster="bai_ji"}
    else model={step=3,title="承诺进攻",body="哨卫已恢复至 26 / 26，复苏进入 3 回合冷却。进入攻击阶段，选择进攻单位和目标。可试选夺魄，再启用掠魂；不启用则是普通攻击。教学对手会格挡荒行，选择其他目标观察命中。",attackBody="选择进攻单位与目标。可启用掠魂；普通攻击不会自动使用技能。教学对手会格挡荒行。",complete=false} end
    model.total=3;model.skillUsed=t.skillUsed
    return model
end
function Training.apply(state,t,action)
    if action.revision~=state.revision then return false,"StaleRevision" end
    if action.kind=="TrainingRetry" then
        if not t.feedback or t.hit or t.complete then return false,"WrongPhase" end
        return true,"Retry"
    end
    if action.kind=="TrainingContinue" then
        if not t.feedback or not t.hit or t.complete then return false,"WrongPhase" end
        t.feedback=nil;t.step=2;state.revision+=1;return true
    end
    if t.feedback or t.complete then return false,"TrainingFeedback" end
    if t.step==1 and action.kind~="BlockCommit" then return false,"WrongPhase" end
    if t.step==2 and (action.kind~="SkillCast" or action.casterId~="bai_ji") then return false,"TrainingSkillRequired" end
    if t.step==3 and action.kind~="SkillCast" and action.kind~="SkillEnd" and action.kind~="AttackCommit" then return false,"WrongPhase" end
    local before=#state.events
    local ok,err=Rules.apply(state,"A",action);if not ok then return false,err end
    if t.step==1 then
        t.feedback=true
        for i=before+1,#state.events do if state.events[i].kind=="Block" and state.events[i].target=="bai_ji" then t.hit=true end end
        return true,t.hit and "BlockRead" or "BlockChosen"
    elseif t.step==2 then
        t.skillUsed=true;t.step=3;return true,"SkillUsed"
    elseif action.kind=="AttackCommit" then
        apply(state,"B",{kind="BlockCommit",blockerId="zhui_lie"})
        t.complete=true;return true,"AttackCommitted"
    end
    return true
end
return Training
