local Kit=require(script.Parent.InterfaceKit)
local C=require(script.Parent.PresentationConfig).Colors
local Preferences={}
local Locale=require(script.Parent.LocaleController)
function Preferences.render(parent,get,change,scale)
    local list=Kit.make("ScrollingFrame",{Name="PreferencesList",BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.fromOffset(0,420),ScrollBarThickness=3,ScrollBarImageColor3=C.Cyan},parent)
    local labels={};local toggles={}
    local languageCaption
    local function draw()
        local s=get()
        if languageCaption then languageCaption.Text="语言  "..Locale.label() end
        for key,label in pairs(labels) do label.Text=({master="主音量",sfx="音效",music="音乐"})[key].."  "..math.floor(s[key]*100+.5).."%" end
        for key,label in pairs(toggles) do
            local value=key=="large" and (s.large and "大" or "标准") or (s[key] and "开" or "关")
            label.Text=({reduced="减少镜头运动",large="界面字号",guide="作战指导"})[key].."  "..value
        end
        Kit.fit(list,scale())
    end
        for index,row in ipairs({{"master","主音量"},{"sfx","音效"},{"music","音乐"}}) do
            local y=index*60
            local label=Kit.text(list,"",.02,0,.57,0,16,C.Paper);label.Position=UDim2.new(.02,0,0,y);label.Size=UDim2.new(.57,0,0,44);labels[row[1]]=label
            for _,step in ipairs({{-1,"−",.62,"Down"},{1,"+",.81,"Up"}}) do
                local b=Kit.button(list,step[2],step[3],0,.17,0,function() change(row[1],math.clamp(math.floor(get()[row[1]]*100+.5)+step[1]*10,0,100)/100);draw() end)
                b.Position=UDim2.new(step[3],0,0,y);b.Size=UDim2.new(.17,0,0,44);b.Name=row[1]..step[4];b:SetAttribute("ControlId","Preference:"..row[1]..":"..step[4])
                for _,t in ipairs(b:GetChildren()) do
                    if t:IsA("UIPadding") then t.PaddingLeft=UDim.new(0,0);t.PaddingRight=UDim.new(0,0)
                    elseif t:IsA("TextLabel") then
                        if t.Text=="›" then t.Visible=false else t.Position=UDim2.fromOffset(0,0);t.Size=UDim2.fromScale(1,1);t.TextXAlignment=Enum.TextXAlignment.Center end
                    end
                end
            end
        end
        for index,row in ipairs({{"reduced","减少镜头运动"},{"large","界面字号"},{"guide","作战指导"}}) do
            local b=Kit.button(list,"",0,0,1,0,function() change(row[1],not get()[row[1]]);draw() end)
            b.Position=UDim2.fromOffset(0,240+(index-1)*60);b.Size=UDim2.new(1,-7,0,44);b.Name=row[1];b:SetAttribute("ControlId","Preference:"..row[1])
            for _,t in ipairs(b:GetChildren()) do if t:IsA("TextLabel") and t.Text~="›" then toggles[row[1]]=t end end
        end
    local languageButton=Kit.button(list,"",0,0,1,0,function()change("language",Locale.cycle());draw()end)
    languageButton.Name="language";languageButton:SetAttribute("ControlId","Preference:language")
    languageButton.Position=UDim2.fromOffset(0,0);languageButton.Size=UDim2.new(1,-7,0,44)
    languageCaption=languageButton.ButtonCaption
    draw();return list
end
return Preferences
