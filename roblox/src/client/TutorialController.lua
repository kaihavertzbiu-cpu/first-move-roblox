-- A dismissible field guide driven only by the same public view as the HUD.
-- It never sends actions, pauses the server or changes the rules.
local Legacy=require(game:GetService("ReplicatedStorage"):WaitForChild("DeadlockShared").LegacyConfig)
local C=require(script.Parent.PresentationConfig).Colors
local defs=require(script.Parent.UnitIdentity).byId
local Tutorial={Enabled=true}
local function hero(view,id)
    for _,h in ipairs(view.rosters.A) do if h.id==id then return h end end
end
function Tutorial.model(view,s)
    if view.training then
        local t=view.training
        local body=t.complete and "正式对手不会公开它准备攻击谁。训练提示不会出现在正式对局中。" or t.feedback=="miss" and "格挡不会替队友承伤。选择哪一名，就保护哪一名。" or t.feedback=="success" and "格挡成功不造成伤害。接下来恢复前一回合受伤的哨卫。" or t.step==2 and "释放后进入冷却，但不会消耗普攻机会。选择复苏，观察哨卫的生命恢复。" or t.step==3 and "先进入攻击阶段，再选择进攻单位。攻击技能需要独立启用；普攻不会自动消耗它。" or "先观察角色用途。复苏负责恢复，是这次教学场景要保护的支援单位。"
        return {title="记住这一点",body=body,checks={},tip=""}
    end
    local phase=view.phase;local mine=view.actor=="A"
    local m={title="观察对手",body="对手正在行动。留意生命和冷却变化。",checks={},tip=""}
    local function check(label,done) table.insert(m.checks,{label=label,done=done and true or false}) end
    if phase=="Draft" then
        m.title="01 / 建立阵容"
        m.body=mine and "先点单位查看能力，再确认入队。当前还可选 "..view.picksRemaining.." 名；双方不能重复选择同一单位。" or "对手正在选人。观察它的阵容，准备下一次选择。"
        check("查看一名单位的能力",s.hero~=nil)
        check("己方已入队 "..#view.rosters.A.." / 5",#view.rosters.A==5)
        m.tip="蛇形选人：首选方先选 1 名，之后双方轮流选 2 名，最后另一方选 1 名。"
    elseif phase=="LinkSetup" then
        m.title="02 / 隐藏命线"
        m.body=mine and "先选己方其他单位，再选敌方单位。己方绑定单位阵亡时，敌方绑定单位也会阵亡。" or "对手正在布置命线。敌方绑定目标不会向你揭示。"
        check("选择己方单位（不能是缚命）",s.ally and s.ally~="ye_ban")
        check("选择敌方绑定目标",s.target~=nil)
        m.tip="命线触发条件是绑定单位阵亡；不是每次受伤。"
    elseif phase=="CoreSelection" then
        m.title="03 / 争夺先攻"
        m.body="秩序克新月，新月克荒芜，荒芜克秩序。锁定前只能看到自己的选择。"
        check("选择一种能核",s.core~=nil or view.coreLocked.A)
        check("锁定后等待双方揭示",view.coreLocked.A)
        m.tip="同核会重新暗选。后攻方仍有一次行动，先攻不等于多一次攻击。"
    elseif phase=="SkillPhase" then
        m.title="04 / 技能窗口"
        m.body=mine and "技能与普攻分开：可先使用当前可用的技能，也可直接进入攻击阶段。" or "对手在使用技能。先观察已经揭示的效果，再准备格挡。"
        local h=hero(view,s.ally);local def=h and defs[h.id]
        check("选择己方单位，查看技能",h~=nil)
        if def then
            if h.used then m.tip=def.name.."的限定技已耗尽，本局不能再次使用。"
            elseif h.cooldown>0 then m.tip=def.name.."还需冷却 "..h.cooldown.." 回合；每完整回合结束后递减。"
            elseif h.statuses.blocked then m.tip="该单位的技能窗口被封锁；普通攻击仍可选择它。"
            elseif def.skill.type=="active_attack_phase" then m.tip="该技能在攻击阶段启用。先进入攻击，再选择是否使用。"
            elseif def.skill.isPassive then m.tip="被动能力自动触发，无需手动释放。"
            elseif h.id=="zhui_lie" then m.tip="先选①目标，再选不同的②目标。①被击杀后才会续算②；仅剩一个敌人时不需②。"
            elseif h.id=="yan_wei" then m.tip="自毁会让残影立即阵亡并触发亡语；这不是普通伤害技能。"
            else m.tip=def.skill.description end
        else m.tip="看清技能的触发阶段、冷却或限定次数，再决定是否使用。" end
    elseif phase=="AttackSelect" then
        m.title="05 / 承诺进攻"
        m.body=mine and "先选己方进攻单位，再选敌方目标。承诺后，对手会暗选格挡，随后才揭示攻击。" or "对手正在选择攻击；它的单位与目标尚未揭示。"
        check("选择进攻单位",s.ally~=nil);check("选择①目标",s.target~=nil)
        local double=s.useSkill and (s.ally=="beng_yue" or s.ally=="shuang_xing")
        if double then
            check("选择②目标",s.second~=nil)
            m.tip=s.ally=="beng_yue" and "重锤可双击同一目标：再次点①即可标为①②；也可选另一个目标。" or "双轨攻击两名不同敌人，对方只能保护其中一名。仅剩一名敌人时不能启用。"
        else m.tip="攻击技能有独立开关。普通攻击不会自动消耗攻击技能的冷却。" end
    elseif phase=="BlockSelect" then
        m.title="06 / 预判格挡"
        m.body=mine and "攻击已承诺，目标仍未知。让一名己方单位保护自己，或选择放弃格挡。" or "你的攻击已承诺。等待对手暗选格挡后一起揭示。"
        check("选择一名己方格挡单位",s.ally~=nil)
        m.tip="格挡只保护所选单位；低语普攻无法格挡。防守方仅剩一名单位时，跳过格挡阶段。"
    elseif phase=="DeathRattleChoice" then
        m.title="07 / 亡语续算"
        m.body=mine and "残影虽已阵亡，仍需选择一个存活敌人承受 "..Legacy.damage.deathRattle.." 点直伤。" or "对手正在选择亡语目标。选择后会继续尚未结束的结算。"
        check("选择亡语目标",s.target~=nil)
        m.tip="亡语不可格挡。剩余攻击、命线与连锁结算仍会继续，直到队列处理完毕。"
    end
    if not mine and phase~="CoreSelection" then m.checks={} end
    return m
end
function Tutorial.render(ui,parent,view,selection)
    local m=Tutorial.model(view,selection)
    local list=ui.make("ScrollingFrame",{Name="FieldGuide",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromScale(.09,.24),Size=UDim2.fromScale(.84,.38),AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollBarImageColor3=C.Cyan},parent)
    ui.make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8)},list)
    local order=0
    local function row(value,size,color)
        local t=ui.text(list,value,0,0,1,0,size,color)
        order+=1;t.LayoutOrder=order;t.Size=UDim2.new(1,-7,0,0);t.AutomaticSize=Enum.AutomaticSize.Y;t.TextYAlignment=Enum.TextYAlignment.Top
    end
    row(m.title,16,C.Paper)
    row(m.body,14,C.Muted)
    for _,item in ipairs(m.checks) do row((item.done and "✓  " or "·  ")..item.label,14,item.done and C.Cyan or C.Paper) end
    if m.tip~="" then row(m.tip,14,C.Muted) end
end
return Tutorial
