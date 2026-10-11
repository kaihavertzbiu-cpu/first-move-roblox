-- Product names and original vector insignia. Stable legacy IDs and rules stay intact.
local Legacy=require(game:GetService("ReplicatedStorage"):WaitForChild("DeadlockShared").LegacyConfig)
local Identity={heroes={},byId={}}
local entries={
    ting_sun={name="夺魄",english="REAPER",role="命中处决",paths={{{.18,.12},{.78,.12},{.78,.3},{.53,.53},{.53,.88}},{{.2,.3},{.42,.52},{.42,.88}},{{.3,.7},{.66,.7}}}},
    lan_dun={name="哨卫",english="WARDEN",role="普攻减伤",paths={{{.18,.17},{.5,.07},{.82,.17},{.78,.62},{.5,.92},{.22,.62},{.18,.17}},{{.5,.26},{.5,.72}},{{.34,.45},{.66,.45}}}},
    ye_ban={name="缚命",english="TETHER",role="命线连锁",paths={{{.08,.35},{.3,.13},{.55,.38},{.33,.62},{.08,.35}},{{.45,.62},{.68,.38},{.92,.65},{.7,.87},{.45,.62}},{{.3,.36},{.7,.64}}}},
    yan_wei={name="残影",english="ECHO",role="自毁亡语",paths={{{.5,.07},{.5,.31}},{{.5,.69},{.5,.93}},{{.07,.5},{.31,.5}},{{.69,.5},{.93,.5}},{{.2,.2},{.34,.34}},{{.66,.66},{.8,.8}},{{.2,.8},{.34,.66}},{{.66,.34},{.8,.2}},{{.5,.34},{.66,.5},{.5,.66},{.34,.5},{.5,.34}}}},
    bai_ji={name="复苏",english="MENDER",role="全队恢复",paths={{{.35,.1},{.65,.1},{.65,.35},{.9,.35},{.9,.65},{.65,.65},{.65,.9},{.35,.9},{.35,.65},{.1,.65},{.1,.35},{.35,.35},{.35,.1}}}},
    shuang_xing={name="双轨",english="TWINRAIL",role="异目标双击",paths={{{.2,.85},{.2,.15},{.36,.3}},{{.7,.85},{.7,.15},{.86,.3}},{{.1,.6},{.32,.6}},{{.6,.6},{.82,.6}}}},
    chi_guang={name="静锁",english="LOCKOUT",role="技能封锁",paths={{{.2,.42},{.8,.42},{.8,.85},{.2,.85},{.2,.42}},{{.32,.42},{.32,.15},{.68,.15},{.68,.42}},{{.5,.57},{.5,.72}}}},
    zhe_jing={name="棱镜",english="PRISM",role="受击反伤",paths={{{.5,.07},{.89,.5},{.5,.93},{.11,.5},{.5,.07}},{{.39,.29},{.23,.5},{.39,.71}},{{.61,.29},{.77,.5},{.61,.71}}}},
    beng_yue={name="重锤",english="MAUL",role="自由双击",paths={{{.12,.12},{.88,.12},{.88,.4},{.12,.4},{.12,.12}},{{.41,.4},{.41,.88},{.59,.88},{.59,.4}},{{.26,.25},{.74,.25}}}},
    huan_shi={name="低语",english="WHISPER",role="无法格挡",paths={{{.08,.5},{.89,.5}},{{.67,.27},{.9,.5},{.67,.73}},{{.24,.15},{.38,.15},{.38,.34}},{{.38,.66},{.38,.85},{.24,.85}}}},
    zhui_lie={name="荒行",english="OUTRIDER",role="限定追杀",paths={{{.08,.62},{.31,.39},{.53,.62}},{{.42,.62},{.65,.39},{.88,.62}},{{.31,.39},{.31,.13},{.52,.13}},{{.65,.62},{.65,.87},{.85,.87}}}},
    xuan_bao={name="蚀痕",english="CORRODE",role="命中流血",paths={{{.5,.08},{.19,.52},{.19,.73},{.36,.9},{.64,.9},{.81,.73},{.81,.52},{.5,.08}},{{.5,.4},{.5,.61}},{{.5,.75},{.5,.8}}}},
}
for _,source in ipairs(Legacy.heroes) do
    local item=table.clone(source);local entry=assert(entries[source.id],"Missing unit identity")
    item.name=entry.name;item.english=entry.english;item.role=entry.role;item.paths=entry.paths
    item.legacyName=source.name;item.skill=table.clone(source.skill)
    Identity.byId[item.id]=item;table.insert(Identity.heroes,item)
end
-- Descriptions use the same display names everywhere, including passive exceptions.
for _,item in ipairs(Identity.heroes) do
    local description=item.skill.description
    for _,source in ipairs(Legacy.heroes) do description=description:gsub(source.name,Identity.byId[source.id].name) end
    item.skill.description=description
end
Identity.byId.yan_wei.skill.name="终响"
Identity.byId.bai_ji.skill.name="修复脉冲"
Identity.byId.shuang_xing.skill.description="攻击阶段：分别攻击两名不同的存活敌人。对方只能选择一名角色格挡，无法同时挡住两次攻击。敌方仅剩一人时无法启用此技能，仍可普通攻击。"
Identity.byId.xuan_bao.skill.description="普攻命中使目标持续流血，无回合数限制。在蚀痕所属方每回合行动开始前，目标受到 3 点不可格挡伤害；持续至目标或蚀痕阵亡。重复命中不叠加流血层数。"
function Identity.name(id) return Identity.byId[id] and Identity.byId[id].name or "未选择" end
Identity.factions={survivor="秩序 · 穹城议会",anomaly="新月 · 共鸣体",wasteland="荒芜 · 断链者"}
Identity.world="天穹熄灭后，三方争夺维持城市的能核。秩序握有新月的约束密钥；新月的共鸣能侵入荒芜的改造躯体；荒芜携带的断链噪声能击穿秩序网络。因此秩序克新月、新月克荒芜、荒芜克秩序。新月以自由为筹码拉拢荒芜，却试图唤醒地下的母体『无冕者』。能核是指挥官每回合选择的技术，并不限制角色组队。"
local stories={
ting_sun="无冕者的追索器。面具里没有面孔，只有一份不断更新的失联名单。它把命中称为回收。",
lan_dun="曾守卫穹城最后一道闸门。议会要求他保护能核，他却将撤离的人群挡在盾后。如今他仍在偿还那次抗命的代价。",
ye_ban="共鸣网络中逃出的连接节点。它无法理解生死，只能把两个生命视为同一个信号。母体正沿着它留下的命线寻找出口。",
yan_wei="一次失败的剥离实验留下的余响。她记得自己有一个名字，却只听见爆裂后的回声。每次主动过载，都是一次拒绝被回收的声明。",
bai_ji="穹城地下诊所的工程医师。她的修复脉冲最初用于救助断链者，也因此失去了议会执照。她医治伤者，从不问能核的颜色。",
shuang_xing="荒芜车队的双轨枪手。两支发射器来自互为仇敌的工坊，她坚持让它们瞄准不同目标：活下去的人，才有机会继续谈判。",
chi_guang="掌管约束密钥的前审查官。发现封锁名单包含平民后，她带走一枚密钥离开穹城。她能关闭异常能力，也知道谁下达了第一道封锁令。",
zhe_jing="坠落实验室里醒来的反射体。镜面中保存着创造者最后的攻击轨迹。它没有报复的概念，只会把伤害送回原处。",
beng_yue="荒芜矿坑的重载实验幸存者。液压锤曾用来开山，如今砸向奴役工人的闸门。断链噪声让他自由，也让他的力量愈发难以控制。",
huan_shi="曾替议会传递秘密命令的相位信使。她的武器与声音一样穿过防线。她正在追查那道让自己故乡陷入沉默的命令。",
zhui_lie="荒芜边境的猎路人。他不为议会或母体效忠，只为仍在迁徙的车队清除追兵。每次追杀都预留第二条路线。",
xuan_bao="被遗弃的能核净化器。腐蚀液曾用于清除污染，如今它把所有独立生命都判作污染。它仍在执行无冕者留下的最后一条指令。",
}
for id,story in pairs(stories) do Identity.byId[id].story=story end
return Identity
