local Layout={}
local C=require(script.Parent.PresentationConfig).Colors
local function place(obj,x,y,w,h) if obj then obj.Position=UDim2.fromScale(x,y);obj.Size=UDim2.fromScale(w,h) end end
local function scrollBody(panel)
    if not panel or panel:FindFirstChild("PanelBody") then return end
    local labels={};local kicker,title,divider
    for _,child in ipairs(panel:GetChildren()) do
        if child:IsA("TextLabel") then
            if child.Position.Y.Scale>=.33 then table.insert(labels,child)
            elseif child.Position.Y.Scale>=.10 then title=child else kicker=child end
        elseif child:IsA("Frame") and math.abs(child.Position.Y.Scale-.30)<.001 then divider=child
        elseif child:IsA("Frame") and child.Position.Y.Scale>=.33 then child:Destroy() end
    end
    local list=Instance.new("ScrollingFrame");list.Name="PanelBody";list.BackgroundTransparency=1;list.BorderSizePixel=0;list.ScrollBarThickness=3;list.ScrollBarImageColor3=C.Cyan;list.Parent=panel
    for _,label in ipairs(labels) do label.Parent=list;label.TextYAlignment=Enum.TextYAlignment.Top end
    local function measure()
        local width=math.max(panel.AbsoluteSize.X*.86-8,1)
        local service=game:GetService("TextService")
        local titleHeight=title and math.max(36,math.ceil(service:GetTextSize(title.ContentText,title.TextSize,title.Font,Vector2.new(width,100000)).Y)+4) or 36
        local top=44+titleHeight+16
        if kicker then kicker.Position=UDim2.new(.07,0,0,10);kicker.Size=UDim2.new(.86,0,0,24) end
        if title then title.Position=UDim2.new(.07,0,0,40);title.Size=UDim2.new(.86,0,0,titleHeight) end
        if divider then divider.Position=UDim2.new(.07,0,0,top-8) end
        list.Position=UDim2.new(.07,0,0,top);list.Size=UDim2.new(.86,0,1,-top-64)
        local y=0
        for _,label in ipairs(labels) do
            local height=math.ceil(service:GetTextSize(label.ContentText,label.TextSize,label.Font,Vector2.new(width,100000)).Y)+4
            label.Position=UDim2.fromOffset(0,y);label.Size=UDim2.new(1,-8,0,height);y+=height+12
        end
        list.CanvasSize=UDim2.fromOffset(0,y)
    end
    panel:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure)
    for _,label in ipairs(labels) do label:GetPropertyChangedSignal("TextSize"):Connect(measure) end
    if title then title:GetPropertyChangedSignal("TextSize"):Connect(measure) end
    task.defer(measure)
end
function Layout.apply(root,screen)
    if screen=="Menu" or screen=="Character" or screen=="Setup" then return end -- These screens measure their own layout.
    local landscape=root.AbsoluteSize.X<900 and root.AbsoluteSize.Y<540 and root.AbsoluteSize.X>root.AbsoluteSize.Y
    if root.AbsoluteSize.X>=760 and not landscape then return end
    local panels={};for _,p in ipairs(root:GetChildren()) do if p:IsA("CanvasGroup") then table.insert(panels,p) end end
    local first,second=panels[1],panels[2]
    if screen=="Title" then place(first,.035,.15,.93,.70)
    elseif screen=="Menu" then
        place(first,.035,.10,.57,.80);place(second,.64,.16,.33,.40)
        place(root:FindFirstChild("CREDITS"),.64,.79,.33,.065)
        for _,t in ipairs(root:GetChildren()) do if t:IsA("TextLabel")then local source=t:GetAttribute("LocaleSource")or t.Text;if source=="AXIOM CORE"or source=="争夺先攻  /  隐藏意图  /  读取反制"then t.Visible=false end end end
    elseif screen=="Briefing" then
        place(first,.035,.11,landscape and .60 or .93,landscape and .79 or .68);scrollBody(first)
        for _,b in ipairs(root:GetChildren()) do if b:IsA("TextButton") then if b.Name=="开始行动" then place(b,landscape and .67 or .51,landscape and .74 or .82,landscape and .295 or .455,.075) else place(b,landscape and .67 or .035,landscape and .53 or .82,landscape and .295 or .45,.075) end end end
    elseif screen=="Record" then
        place(first,.035,.10,landscape and .46 or .93,landscape and .80 or .42);place(second,landscape and .525 or .035,landscape and .10 or .55,landscape and .44 or .93,landscape and .80 or .35);scrollBody(first)
    elseif screen=="Archive" then
        place(first,.035,.10,landscape and .46 or .93,landscape and .80 or .43);place(second,landscape and .525 or .035,landscape and .10 or .56,landscape and .44 or .93,landscape and .80 or .34);scrollBody(first)
    elseif screen=="Settings" or screen=="Credits" or screen=="Abandoned" or screen=="Connecting" or screen=="Waiting" then place(first,.035,.12,.93,.77) end
end
return Layout
