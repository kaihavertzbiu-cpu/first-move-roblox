local TweenService=game:GetService("TweenService")
local Config=require(script.Parent.PresentationConfig)
local Audio=require(script.Parent.AudioController)
local Locale=require(script.Parent.LocaleController)
local C=Config.Colors
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    if obj:IsA("TextLabel") then
        local formatting=false
        local function optical()
            if Locale.isEnglish() then return end
            if obj:GetAttribute("NaturalGlyphs") then return end
            if formatting then return end
            local raw=obj.Text:gsub('<font size="%d+">复</font>',"复")
            if raw:find("复苏",1,true) and not raw:find("<",1,true) then
                formatting=true;obj.RichText=true
                obj.Text=raw:gsub("复",'<font size="'..math.floor(obj.TextSize*1.18+.5)..'">复</font>')
                formatting=false
            end
        end
        obj:GetPropertyChangedSignal("Text"):Connect(optical)
        obj:GetPropertyChangedSignal("TextSize"):Connect(optical);optical()
    end
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then Locale.bind(obj) end
    return obj
end
local function text(parent, value, x,y,w,h,size,color,font)
    local face=font==Enum.Font.GothamBold and Enum.FontWeight.Bold or font==Enum.Font.Gotham and Enum.FontWeight.Regular or Enum.FontWeight.SemiBold
    return make("TextLabel", {BackgroundTransparency=1,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),Text=value,TextColor3=color or C.Paper,FontFace=Font.new(Config.DossierTypography.Family,face),TextSize=size,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true},parent)
end
local function line(parent,x,y,w,color)
    return make("Frame",{BorderSizePixel=0,BackgroundColor3=color or C.Line,Position=UDim2.fromScale(x,y),Size=UDim2.new(w,0,0,1)},parent)
end
local function panel(parent,x,y,w,h,alpha,stable)
    local p = make("CanvasGroup",{Name="Panel"..(#parent:GetChildren()+1),BorderSizePixel=0,BackgroundColor3=C.Ink,BackgroundTransparency=math.min(alpha or 0.08,.035),Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),GroupTransparency=stable and 0 or 1},parent)
    make("Frame",{Name="MachinedCorner",BorderSizePixel=0,BackgroundColor3=C.Line,Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(18,2)},p)
    make("UIStroke",{Name="SurfaceEdge",Color=Color3.fromRGB(98,115,123),Thickness=1,Transparency=.68},p)
    make("UIGradient",{Name="GraphiteSurface",Rotation=90,
        Color=ColorSequence.new(Color3.fromRGB(255,255,255),Color3.fromRGB(175,187,193))},p)
    make("Frame",{Name="LowerSeam",BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(4,9,12),
        BackgroundTransparency=.2,Position=UDim2.new(0,1,1,-2),Size=UDim2.new(1,-2,0,1)},p)
    if not stable then TweenService:Create(p,TweenInfo.new(Config.PanelTime,Enum.EasingStyle.Quad),{GroupTransparency=0}):Play() end
    return p
end
local function button(parent,label,x,y,w,h,fn,primary)
    local b=make("TextButton",{Name=label,AutoButtonColor=false,BorderSizePixel=0,Text="",Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),BackgroundColor3=primary and C.Paper or C.Panel,BackgroundTransparency=primary and 0 or 0.15,Selectable=true},parent)
    make("UIGradient",{Name="MachinedSurface",Rotation=90,
        Color=ColorSequence.new(Color3.fromRGB(255,255,255),primary and Color3.fromRGB(213,220,222) or Color3.fromRGB(157,173,180))},b)
    make("UIStroke",{Name="ButtonEdge",Color=primary and C.Paper or Color3.fromRGB(104,125,135),
        Thickness=1,Transparency=primary and .4 or .65},b)
    local focus=make("Frame",{Name="FocusOutline",BackgroundTransparency=1,Size=UDim2.new(1,4,1,4),Position=UDim2.fromOffset(-2,-2)},b)
    make("UIStroke",{Color=C.Cyan,Thickness=1,Transparency=.15},focus)
    focus.Parent=nil;b.SelectionImageObject=focus
    b.Destroying:Connect(function() focus:Destroy() end)
    local padding=make("UIPadding",{PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,12)},b)
    local bevel=make("Frame",{Name="UpperBevel",BorderSizePixel=0,BackgroundColor3=primary and Color3.fromRGB(255,253,243) or Color3.fromRGB(120,144,155),
        BackgroundTransparency=primary and .25 or .55,Position=UDim2.fromOffset(-15,1),Size=UDim2.new(1,26,0,1)},b)
    local rail=make("Frame",{Name="CommandRail",BorderSizePixel=0,BackgroundColor3=primary and C.Amber or C.Muted,
        BackgroundTransparency=primary and .05 or .5,Position=UDim2.fromOffset(-15,3),Size=UDim2.new(0,2,1,-6)},b)
    make("UISizeConstraint",{MinSize=Vector2.new(Config.MinimumTarget,Config.MinimumTarget)},b)
    local caption=text(b,label,0,0,0.9,1,17,primary and C.Ink or C.Paper,Enum.Font.GothamMedium)
    caption.Name="ButtonCaption"
    local arrow=text(b,"›",0.91,0,0.09,1,24,primary and C.Ink or C.Muted)
    arrow.Name="ButtonArrow"
    local function fitCaption()
        if not caption.Parent or not arrow.Parent then return end
        local small=b.AbsoluteSize.X<150
        arrow.Visible=not small and not b:GetAttribute("HideArrow")
        local inset=b:GetAttribute("CaptionInset")
        if inset then
            caption.Position=UDim2.fromOffset(inset,0)
            caption.Size=UDim2.new(1,-inset-(arrow.Visible and 26 or 0),1,0)
        else caption.Size=UDim2.fromScale(small and 1 or .9,1) end
    end
    b:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitCaption);task.defer(fitCaption)
    b:GetAttributeChangedSignal("CaptionInset"):Connect(fitCaption)
    b:GetAttributeChangedSignal("HideArrow"):Connect(fitCaption)
    local original=b.BackgroundColor3;local hovered=false;local pressed=false;local restAlpha=b.BackgroundTransparency
    local function release()
        if pressed then b.BackgroundTransparency=restAlpha;pressed=false end
    end
    local function hover(on)
        if b:GetAttribute("Disabled") then return end
        if on and not hovered then original=b.BackgroundColor3 end
        hovered=on
        rail.BackgroundTransparency=on and 0 or primary and .05 or .5
        rail.BackgroundColor3=on and C.Cyan or primary and C.Amber or C.Muted
        TweenService:Create(b,TweenInfo.new(Config.HoverTime),{BackgroundColor3=on and (b:GetAttribute("HoverColor") or ((primary or b:GetAttribute("Selected")) and C.Cyan or Color3.fromRGB(45,63,71))) or b:GetAttribute("RestColor") or original}):Play()
        if on then Audio.Play("hover") end
    end
    b.MouseEnter:Connect(function() hover(true) end)
    b.MouseLeave:Connect(function() release();hover(false) end)
    b.SelectionGained:Connect(function() hover(true) end)
    b.SelectionLost:Connect(function() release();hover(false) end)
    b.MouseButton1Down:Connect(function() if not b:GetAttribute("Disabled") then restAlpha=b.BackgroundTransparency;pressed=true;b.BackgroundTransparency=math.min(1,restAlpha+.12) end end)
    b.MouseButton1Up:Connect(release)
    local defaultCue=label:find("返回",1,true) or label=="上一位" or label=="上一步" or label:find("取消",1,true)
    b.Activated:Connect(function() if b:GetAttribute("Disabled") then return end;Audio.Play(b:GetAttribute("AudioCue") or (defaultCue and "back" or primary and "confirm" or "select"));fn() end)
    return b
end
local function textSize(base,height,scale)
    local typography=Config.Typography
    local factor=math.clamp(height/typography.ReferenceHeight,1,typography.MaximumScale)
    local minimum=base>=14 and typography.BodyMinimum or typography.MetaMinimum
    return math.floor(math.max(minimum,base*typography.OpticalScale)*factor*(scale or 1)+.5)
end
local function fit(root,scale)
    -- A scroller's own height is not the viewport. Keep settings consistent with the HUD.
    local screen=root:FindFirstAncestorWhichIsA("ScreenGui")
    local router=screen and screen:FindFirstChild("Router")
    local height=router and router.AbsoluteSize.Y or root.AbsoluteSize.Y
    for _,obj in ipairs(root:GetDescendants()) do if obj:IsA("TextLabel") then
        local base=obj:GetAttribute("BaseTextSize")
        if not base then base=obj.TextSize;obj:SetAttribute("BaseTextSize",base) end
        obj.TextSize=textSize(base,height,scale)
    end end
end
local function icon(parent,kind,x,y,size,color)
    local f=make("Frame",{Name="SystemIcon",BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(size,size)},parent)
    local function segment(ax,ay,bx,by)
        local dx,dy=(bx-ax)*size,(by-ay)*size
        make("Frame",{BorderSizePixel=0,BackgroundColor3=color or C.Muted,AnchorPoint=Vector2.new(.5,.5),
            Position=UDim2.fromOffset((ax+bx)*size/2,(ay+by)*size/2),Size=UDim2.fromOffset(math.sqrt(dx*dx+dy*dy),1.6),Rotation=math.deg(math.atan2(dy,dx))},f)
    end
    local points=kind=="Shop" and {{.18,.28,.82,.28},{.18,.28,.08,.46},{.08,.46,.92,.46},{.92,.46,.82,.28},{.18,.48,.18,.87},{.18,.87,.82,.87},{.82,.87,.82,.48},{.43,.87,.43,.64},{.43,.64,.65,.64},{.65,.64,.65,.87}}
        or kind=="Inventory" and {{.2,.3,.8,.3},{.2,.3,.2,.86},{.2,.86,.8,.86},{.8,.86,.8,.3},{.34,.3,.34,.13},{.34,.13,.66,.13},{.66,.13,.66,.3},{.2,.5,.8,.5},{.44,.5,.44,.61},{.44,.61,.56,.61},{.56,.61,.56,.5}}
        or kind=="Career" and {{.2,.18,.8,.18},{.2,.18,.24,.56},{.8,.18,.76,.56},{.24,.56,.5,.76},{.76,.56,.5,.76},{.5,.76,.5,.9},{.31,.9,.69,.9},{.22,.29,.07,.29},{.07,.29,.12,.52},{.12,.52,.25,.55},{.78,.29,.93,.29},{.93,.29,.88,.52},{.88,.52,.75,.55}}
        or {{.3,.12,.42,.24},{.42,.24,.3,.38},{.3,.38,.18,.24},{.18,.24,.3,.12},{.7,.16,.8,.27},{.8,.27,.7,.4},{.7,.4,.59,.27},{.59,.27,.7,.16},{.08,.84,.12,.6},{.12,.6,.3,.49},{.3,.49,.48,.6},{.48,.6,.52,.84},{.6,.55,.74,.5},{.74,.5,.88,.61},{.88,.61,.92,.84}}
    for _,p in ipairs(points)do segment(table.unpack(p))end
    return f
end
return {make=make,text=text,line=line,panel=panel,button=button,fit=fit,textSize=textSize,icon=icon}
