local Kit=require(script.Parent.InterfaceKit)
local H={}
local careerPage="战绩"
-- Layout is measured from the usable viewport. Transactions remain server owned.
function H.render(ctx,kind)
    local root,C,P=ctx.root,ctx.colors,ctx.progression
    local make,text,button=Kit.make,Kit.text,Kit.button
    local W,Hh=root.AbsoluteSize.X,root.AbsoluteSize.Y
    local narrow=W<620;local compact=Hh<540
    local e,stats=ctx.economy(),ctx.stats()
    local owned=e.owned or {}
    local p=make("Frame",{Name="PlayerHub",BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(10,18,24),BackgroundTransparency=.055,
        Position=UDim2.fromScale(.035,.06),Size=UDim2.fromScale(.93,.88)},root)
    make("UIGradient",{Rotation=30,Color=ColorSequence.new(Color3.fromRGB(210,228,239),Color3.fromRGB(118,139,160))},p)
    local pw,ph=W*.93,Hh*.88
    local pad=narrow and 12 or 24
    local function label(parent,value,x,y,w,h,size,color,bold)
        local t=text(parent,value,0,0,0,0,size or 18,color or C.Paper,bold and Enum.Font.GothamBold or Enum.Font.GothamMedium)
        t.Position=UDim2.fromOffset(x,y);t.Size=UDim2.fromOffset(w,h);return t
    end
    local function rect(parent,name,x,y,w,h,color,alpha)
        return make("Frame",{Name=name,BorderSizePixel=0,BackgroundColor3=color or C.Panel,BackgroundTransparency=alpha or 0,
            Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h)},parent)
    end
    local function rule(parent,x,y,w,color,alpha) return rect(parent,"FineRule",x,y,w,1,color or C.Line,alpha or .35) end
    local function skin(b,primary,tint)
        b.BackgroundColor3=primary and Color3.fromRGB(42,76,86)or Color3.fromRGB(22,33,43)
        b:SetAttribute("RestColor",b.BackgroundColor3);b.BackgroundTransparency=primary and .04 or .28
        b.ButtonEdge.Transparency=primary and .42 or .82;b.ButtonEdge.Color=tint or C.Cyan
        b.CommandRail.Visible=false;b.UpperBevel.Visible=false;b.MachinedSurface.Enabled=false
        b:SetAttribute("HideArrow",true)
        b.ButtonCaption.TextColor3=C.Paper;b.ButtonCaption.Font=Enum.Font.GothamBold
        return b
    end
    local function control(parent,caption,x,y,w,fn,primary)
        local b=skin(button(parent,caption,0,0,0,0,fn,primary),primary)
        b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,44);return b
    end
    local function meter(parent,x,y,w,fraction,color)
        local track=rect(parent,"ProgressTrack",x,y,w,3,C.Line,.30)
        make("Frame",{Name="ProgressFill",BackgroundColor3=color or C.Cyan,BorderSizePixel=0,
            Size=UDim2.fromScale(math.clamp(fraction,0,1),1)},track)
    end
    local titles={Shop="补给商店",Inventory="我的收藏",Career="指挥官生涯",Friends="好友大厅"}
    label(p,titles[kind],pad,7,pw*.65,38,narrow and 24 or 28,C.Paper,true)
    local wallet=label(p,tostring(e.credits).." 核晶",pw*.7,11,pw*.3-pad,30,16,C.Cyan,true)
    wallet.TextXAlignment=Enum.TextXAlignment.Right
    local tw=(pw-pad*2)/4
    for i,row in ipairs({{"商店","Shop"},{"背包","Inventory"},{"生涯","Career"},{"好友","Friends"}})do
        local b=control(p,row[1],pad+(i-1)*tw,48,tw-4,function()ctx.navigate(row[2])end)
        b:SetAttribute("Selected",kind==row[2]);b:SetAttribute("ControlId",row[2]);b.BackgroundTransparency=1;b.ButtonEdge.Transparency=1
        b.UIPadding.PaddingLeft=UDim.new(0,8);b.UIPadding.PaddingRight=UDim.new(0,4)
        b.ButtonCaption.TextColor3=kind==row[2]and C.Paper or C.Muted
        if not narrow then Kit.icon(b,row[2],0,9,24,kind==row[2]and C.Cyan or C.Muted);b:SetAttribute("CaptionInset",34)end
        rule(b,0,43,tw-4,kind==row[2]and C.Cyan or C.Line,kind==row[2]and 0 or .6)
    end
    local bodyY=104;local bodyH=math.max(88,ph-bodyY-62);local bodyW=pw-pad*2
    local footerActionW=math.min(340,bodyW-(narrow and 144 or 196))
    local footerActionX=pad+bodyW-footerActionW
    local body=make("ScrollingFrame",{Name="HubContent",BackgroundTransparency=1,BorderSizePixel=0,
        Position=UDim2.fromOffset(pad,bodyY),Size=UDim2.fromOffset(bodyW,bodyH),CanvasSize=UDim2.fromOffset(0,0),
        ScrollBarThickness=3,ScrollBarImageColor3=C.Cyan,ScrollingDirection=Enum.ScrollingDirection.Y,ClipsDescendants=true},p)
    local function sheet(name,x,y,w,h)
        local f=rect(body,name,x,y,w,h,Color3.fromRGB(20,31,40),.28)
        rule(f,0,0,w,C.Line,.5);return f
    end
    local contentHeight=bodyH
    if kind=="Shop"or kind=="Inventory"then
        local items={}
        if kind=="Inventory"then table.insert(items,{id="default",name="初始印记",price=0,color={185,201,209}})end
        for _,item in ipairs(P.Items)do if kind=="Shop"or owned[item.id]then table.insert(items,item)end end
        local selected=items[1];for _,item in ipairs(items)do if item.id==ctx.selected()then selected=item end end
        local galleryW=narrow and bodyW or math.floor(bodyW*.37)
        local gap=20;local previewX=narrow and 0 or galleryW+gap
        local previewY=narrow and 0 or 0;local previewW=narrow and bodyW or bodyW-galleryW-gap
        local previewH=narrow and 270 or math.max(bodyH,142)
        local hero=sheet("CosmeticPreview",previewX,previewY,previewW,previewH)
        if not narrow and bodyH>=142 then hero.Parent=p;hero.Position=UDim2.fromOffset(pad+previewX,bodyY);body.Size=UDim2.fromOffset(galleryW,bodyH)end
        local tint=Color3.fromRGB(table.unpack(selected.color))
        local emblemSize=narrow and 110 or math.min(previewH-56,previewW*.39,248)
        local emblem=ctx.badge(hero,8,8,emblemSize,1,tint,selected.id)
        emblem.Position=UDim2.fromOffset(12,narrow and 16 or math.max(8,(previewH-emblemSize)/2-8))
        local tx=narrow and 142 or math.floor(previewW*.44)
        local infoW=previewW-tx-16
        label(hero,"身份印记",tx,10,infoW,22,14,tint)
        label(hero,selected.name,tx,37,infoW,40,narrow and 24 or compact and 24 or 32,C.Paper,true)
        if previewH>=240 then label(hero,"指挥室身份条配色",tx,84,infoW,26,14,C.Muted)end
        local actual=rect(hero,"EquippedPreview",narrow and 16 or tx,narrow and 136 or previewH-112,
            narrow and previewW-32 or infoW,46,C.Ink,.02)
        rect(actual,"IdentityAccent",0,0,3,46,tint,0)
        label(actual,"Lv."..P.level(e.xp).."  ·  "..P.rank(e.rating),12,7,actual.Size.X.Offset-24,32,18,tint,true)
        local has=selected.id=="default"or owned[selected.id]
        local equipped=e.equipped==selected.id;local afford=e.credits>=selected.price
        local caption=ctx.busy()and "正在同步…"or equipped and "已装备"or has and "装备印记"or afford and "兑换 · "..selected.price.." 核晶"or "还差 "..(selected.price-e.credits).." 核晶"
        local actionX=narrow and 16 or tx
        local buy=control(p,caption,footerActionX,ph-52,footerActionW,
            function()ctx.transact(has and "Equip"or"Buy",selected.id)end,true)
        buy:SetAttribute("ControlId","CollectionAction");buy:SetAttribute("ItemId",selected.id)
        buy:SetAttribute("Disabled",ctx.busy()or equipped or not has and not afford)
        buy.Selectable=not buy:GetAttribute("Disabled")
        if not buy.Selectable then buy.BackgroundTransparency=.45;buy.ButtonCaption.TextColor3=C.Muted end
        local galleryY=narrow and previewH+20 or 0
        label(body,kind=="Shop"and "印记收藏"or"已拥有 · "..#items,0,galleryY,galleryW,26,16,C.Muted,true)
        local rowH=narrow and 82 or math.max(50,math.min(128,(bodyH-36-(#items-1)*8)/#items))
        for i,item in ipairs(items)do
            local y=galleryY+36+(i-1)*(rowH+8)
            local choose=control(body,item.name,0,y,galleryW,function()ctx.select(item.id,kind)end)
            choose.Name="CollectionItem"..i;choose.Size=UDim2.fromOffset(galleryW,rowH);choose:SetAttribute("ControlId","Preview:"..item.id)
            choose:SetAttribute("ItemId",item.id);choose:SetAttribute("Selected",item.id==selected.id)
            choose.ButtonCaption.Visible=false;choose.ButtonArrow.Visible=false;choose.UIPadding.PaddingLeft=UDim.new(0,0);choose.UIPadding.PaddingRight=UDim.new(0,0)
            choose.BackgroundTransparency=item.id==selected.id and .08 or .62
            local color=Color3.fromRGB(table.unpack(item.color))
            choose.ButtonEdge.Transparency=item.id==selected.id and .2 or .85;choose.ButtonEdge.Color=color
            local size=math.min(76,rowH-12);ctx.badge(choose,6,(rowH-size)/2,size,1,color,item.id)
            local lx=size+20;label(choose,item.name,lx,math.max(2,rowH/2-27),galleryW-lx-8,24,rowH<64 and 18 or 20,C.Paper,true)
            local status=e.equipped==item.id and "已装备"or(item.id=="default"or owned[item.id])and "已收藏"or item.price.." 核晶"
            label(choose,status,lx,rowH/2+3,galleryW-lx-8,20,14,color)
        end
        contentHeight=narrow and math.max(previewH,galleryY+36+#items*(rowH+8)-8)or galleryY+36+#items*(rowH+8)-8
    elseif kind=="Career"then
        local tier=1;for i,r in ipairs(P.Ranks)do if e.rating>=r[1]then tier=i end end
        local rank,nextRank=P.Ranks[tier],P.Ranks[tier+1]
        local leftW=narrow and bodyW or math.floor(bodyW*.42)
        local heroH=narrow and 274 or math.max(190,bodyH)
        local hero=sheet("RankShowcase",0,0,leftW,heroH)
        if not narrow and bodyH>=190 then hero.Parent=p;hero.Position=UDim2.fromOffset(pad,bodyY)end
        local horizontal=not narrow and heroH<300
        local size=narrow and 132 or horizontal and math.min(heroH-56,leftW*.45)or math.min(196,heroH-126)
        ctx.badge(hero,horizontal and 8 or (leftW-size)/2,8,size,tier,C.Amber)
        local tx=horizontal and size+24 or 12
        local name=label(hero,rank[2],tx,horizontal and 30 or size+16,leftW-tx-12,36,28,C.Paper,true)
        name.TextXAlignment=horizontal and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        local score=label(hero,tostring(e.rating).." 分",tx,horizontal and 74 or size+52,leftW-tx-12,26,18,C.Muted)
        score.TextXAlignment=name.TextXAlignment
        local progressY=heroH-44
        label(hero,nextRank and "晋升 "..nextRank[2].." · 还差 "..(nextRank[1]-e.rating).." 分"or"已达最高段位",16,progressY,leftW-32,28,14,C.Muted)
        meter(hero,16,progressY+33,leftW-32,nextRank and (e.rating-rank[1])/(nextRank[1]-rank[1])or 1,C.Amber)
        local rx=narrow and 0 or leftW+20;local ry=narrow and heroH+20 or 0
        local rw=narrow and bodyW or bodyW-rx
        for i,title in ipairs({"战绩","成就","段位"})do
            local b=control(body,title,rx+(i-1)*rw/3,ry,rw/3-4,function()careerPage=title;ctx.navigate("Career")end)
            b:SetAttribute("ControlId","Career:"..title);b.BackgroundTransparency=1;b.ButtonEdge.Transparency=1
            b.ButtonCaption.TextColor3=careerPage==title and C.Paper or C.Muted
            rule(b,0,43,rw/3-4,careerPage==title and C.Cyan or C.Line,careerPage==title and 0 or .6)
        end
        if careerPage=="战绩"then
        local data=sheet("CareerStats",rx,ry+54,rw,compact and 70 or 100)
        for i,row in ipairs({{"对局",stats.gamesPlayed or 0},{"胜利",stats.wins or 0},{"最高连胜",stats.bestStreak or 0}})do
            local x=(i-1)*rw/3+12;label(data,tostring(row[2]),x,compact and 0 or 10,rw/3-20,40,28,C.Paper,true)
            label(data,row[1],x,compact and 41 or 58,rw/3-20,24,14,C.Muted)
        end
        local xpY=ry+(compact and 136 or 166)
        local xp=sheet("Experience",rx,xpY,rw,compact and 66 or 86)
        label(xp,"指挥官 Lv."..P.level(e.xp),12,8,rw*.62-12,30,20,C.Paper,true)
        local value=label(xp,(e.xp%P.XPPerLevel).." / "..P.XPPerLevel, rw*.64,9,rw*.36-12,28,14,C.Cyan)
        value.TextXAlignment=Enum.TextXAlignment.Right;meter(xp,12,compact and 52 or 62,rw-24,(e.xp%P.XPPerLevel)/P.XPPerLevel,C.Cyan)
        contentHeight=math.max(narrow and heroH or 0,xpY+xp.Size.Y.Offset)
        elseif careerPage=="成就"then
        local ah=narrow and 106 or compact and math.max(44,(bodyH-56-16)/3)or 78
        local ag=narrow and 12 or 8
        for i,row in ipairs({{"首战告捷","赢得 1 场对局",stats.wins or 0,1},{"久经战阵","完成 10 场对局",stats.gamesPlayed or 0,10},{"洞悉先机","成功预判格挡 10 次",stats.readHits or 0,10}})do
            local y=ry+56+(i-1)*(ah+ag);local earned=row[3]>=row[4]
            local card=sheet("Achievement"..i,rx,y,rw,ah)
            local bs=math.min(60,ah-8);local lx=bs+18;local dense=ah<64
            ctx.badge(card,4,4,bs,i,earned and C.Amber or C.Muted,"achievement")
            label(card,row[1],lx,dense and 0 or 5,rw-lx-14,dense and 24 or 30,dense and 18 or 20,earned and C.Paper or C.Muted,true)
            label(card,row[2],lx,dense and 24 or 40,narrow and rw-lx-14 or rw-lx-100,narrow and 38 or dense and 20 or 26,dense and 12 or 14,C.Muted)
            local progress=label(card,earned and "已达成"or math.min(row[3],row[4]).." / "..row[4],rw-88,narrow and 78 or dense and 24 or 40,76,dense and 20 or 26,dense and 12 or 14,earned and C.Amber or C.Muted)
            progress.TextXAlignment=Enum.TextXAlignment.Right
        end
        contentHeight=ry+56+3*(ah+ag)-ag
        else
        local pathY=ry+56
        local path=sheet("RankPath",rx,pathY,rw,narrow and 112 or 138)
        for i,r in ipairs(P.Ranks)do
            local sw=rw/5;local bs=narrow and 48 or math.min(78,sw-12)
            ctx.badge(path,(i-1)*sw+(sw-bs)/2,4,bs,i,i==tier and C.Amber or C.Muted)
            local name2=label(path,r[2],(i-1)*sw+2,bs+8,sw-4,26,14,i==tier and C.Paper or C.Muted)
            name2.TextXAlignment=Enum.TextXAlignment.Center
        end
        contentHeight=pathY+path.Size.Y.Offset
        end
    else
        local leftW=narrow and bodyW or math.floor(bodyW*.40)
        local leadH=narrow and 214 or math.max(198,bodyH)
        local lead=sheet("FriendLobby",0,0,leftW,leadH)
        Kit.icon(lead,"Friends",18,12,44,C.Cyan)
        label(lead,"并肩入局",18,64,leftW-36,40,28,C.Paper,true)
        label(lead,"邀请好友，进入同一大厅。",18,110,leftW-36,46,16,C.Muted)
        control(p,"邀请好友",footerActionX,ph-52,footerActionW,ctx.invite,true):SetAttribute("ControlId","InviteFriend")
        local rx=narrow and 0 or leftW+20;local ry=narrow and leadH+20 or 0
        local rw=narrow and bodyW or bodyW-rx
        local players=ctx.players:GetPlayers()
        label(body,"当前大厅 · "..#players,rx,ry,rw,30,18,C.Paper,true)
        for i,player in ipairs(players)do
            local card=sheet("LobbyPlayer"..i,rx,ry+42+(i-1)*78,rw,66)
            Kit.icon(card,"Friends",10,15,32,C.Muted)
            local name=label(card,player.DisplayName,58,4,rw-74,30,20,C.Paper,true)
            name:SetAttribute("LocaleIgnore",true)
            name.TextWrapped=false;name.TextTruncate=Enum.TextTruncate.AtEnd
            label(card,player==ctx.players.LocalPlayer and "你"or"已在大厅",58,34,rw-74,24,14,C.Cyan)
        end
        if #players<=1 then label(body,"好友加入后会出现在这里。",rx,ry+42+math.max(#players,1)*78,rw,38,16,C.Muted)end
        local actionY=ry+42+math.max(#players,1)*78+(#players<=1 and 48 or 8)
        control(body,"进入双人对峙",rx,actionY,rw,ctx.startPVP,true):SetAttribute("ControlId","FriendPVP")
        contentHeight=math.max(leadH,actionY+44)
    end
    body.CanvasSize=UDim2.fromOffset(0,contentHeight)
    task.defer(function()if body.Parent then body.CanvasPosition=Vector2.new(0,ctx.scroll())end end)
    body:SetAttribute("LayoutOwned",true)
    rule(p,pad,ph-62,bodyW,C.Line,.55)
    local paired=kind=="Shop"or kind=="Inventory"or kind=="Friends"
    local back=control(p,"返回指挥室",pad,ph-52,narrow and (paired and 132 or bodyW)or 180,ctx.back)
    back:SetAttribute("ControlId","HubBack")
    if ctx.notice()~=""then
        local room=bodyW-196-(paired and footerActionW+16 or 0)
        local above=narrow or room<240
        local x=above and pad or pad+196
        local status=label(p,ctx.notice(),x,above and ph-90 or ph-52,above and bodyW or room,30,14,C.Cyan)
        status.Name="HubStatus";status.BackgroundColor3=C.Ink;status.BackgroundTransparency=.02
    end
end
return H
