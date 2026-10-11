local P={Currency="核晶",XPPerLevel=200,WinCredits=60,LossCredits=20,WinXP=100,LossXP=40,RankWin=25,RankLoss=15}
P.Items={
    {id="signal_cyan",name="新月信标",price=120,description="指挥室身份条 · 冷青配色",color={103,207,216}},
    {id="signal_amber",name="秩序印记",price=120,description="指挥室身份条 · 琥珀配色",color={219,177,100}},
    {id="signal_violet",name="荒芜回声",price=180,description="指挥室身份条 · 紫灰配色",color={174,164,206}},
}
P.ById={};for _,item in ipairs(P.Items)do P.ById[item.id]=item end
P.Ranks={{0,"见习"},{100,"哨兵"},{250,"战术官"},{500,"指挥官"},{900,"执政官"}}
function P.rank(points)local name=P.Ranks[1][2];for _,r in ipairs(P.Ranks)do if points>=r[1]then name=r[2]end end;return name end
function P.level(xp)return 1+math.floor(xp/P.XPPerLevel)end
return P
