-- Original illustration assets; the same authored face crop is used in every small slot.
-- Asset availability never blocks battle input or creates gameplay geometry.
local Assets=require(script.Parent.PortraitAssets)
local Identity=require(script.Parent.UnitIdentity)
local ContentProvider=game:GetService("ContentProvider")
local Portrait={}
local requested={}
function Portrait.render(parent,id,position,size,alive,framing)
    local def=Identity.byId[id];if not def then return end
    local asset=Assets.Units[id]
    local frame=Instance.new("ImageLabel")
    frame.Name="UnitPortrait";frame.BackgroundTransparency=1;frame.Position=position;frame.Size=size;frame.Active=false
    frame:SetAttribute("UnitId",id);frame:SetAttribute("PortraitParts",0)
    frame:SetAttribute("PortraitSource",asset and "OriginalIllustration" or "InsigniaFallback")
    frame:SetAttribute("AssetLoaded",false)
    local mode=framing or "Face";frame:SetAttribute("Framing",mode)
    frame.ImageColor3=alive==false and Color3.fromRGB(129,142,147) or Color3.new(1,1,1)
    frame.ImageTransparency=alive==false and .30 or 0
    if asset then
        frame.Image=asset.Image
        frame.ClipsDescendants=true
        -- Roblox may resize uploaded textures. Crop in normalized source coordinates.
        local art=Instance.new("ImageLabel");art.Name="Artwork";art.BackgroundTransparency=1
        art.Image=asset.Image;art.ScaleType=Enum.ScaleType.Stretch
        art.ImageColor3=frame.ImageColor3;art.ImageTransparency=frame.ImageTransparency
        art.Parent=frame;frame.ImageTransparency=1
        local function showCrop(x,y,w,h)
            art.Size=UDim2.fromScale(asset.Width/w,asset.Height/h)
            art.Position=UDim2.fromScale(-x/w,-y/h)
        end
        frame.ScaleType=mode=="Full" and Enum.ScaleType.Fit or Enum.ScaleType.Crop
        local crop=mode=="Full" and asset.Full or mode=="Hero" and asset.Hero or asset.Face
        frame.ImageRectOffset=Vector2.new(crop[1],crop[2]);frame.ImageRectSize=Vector2.new(crop[3],crop[4])
        showCrop(crop[1],crop[2],crop[3],crop[4])
        if mode=="Face" then
            local function fitFace()
                local v=frame.AbsoluteSize;if v.X<=0 or v.Y<=0 then return end
                local w=math.min(crop[3],crop[4]*v.X/v.Y);local h=w*v.Y/v.X
                showCrop(crop[1]+(crop[3]-w)/2,crop[2]+(crop[4]-h)/2,w,h)
            end
            frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitFace);task.defer(fitFace)
        end
        if mode=="Full" then art.Size=UDim2.fromScale(1,1);art.Position=UDim2.fromScale(0,0);art.ScaleType=Enum.ScaleType.Fit end
        if mode=="Hero" then
            local function fitHero()
                local view=frame.AbsoluteSize;if view.X<=0 or view.Y<=0 then return end
                -- Crop from the head's safe top, rather than centre-cropping away the face.
                local ratio=view.X/view.Y
                local height=math.min(asset.Height-crop[2],asset.Width/ratio)
                local width=math.min(asset.Width,height*ratio)
                local center=asset.Face[1]+asset.Face[3]/2
                frame.ImageRectOffset=Vector2.new(math.floor(math.clamp(center-width/2,0,asset.Width-width)),crop[2])
                frame.ImageRectSize=Vector2.new(math.floor(width),math.floor(height))
                showCrop(frame.ImageRectOffset.X,crop[2],width,height)
            end
            frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitHero)
            task.defer(fitHero)
        end
    end
    local fallback=Instance.new("Frame");fallback.Name="PortraitFallback";fallback.BackgroundTransparency=1
    fallback.AnchorPoint=Vector2.new(.5,.5);fallback.Position=UDim2.fromScale(.5,.5);fallback.Size=UDim2.fromScale(.68,.68);fallback.Parent=frame
    local aspect=Instance.new("UIAspectRatioConstraint");aspect.AspectRatio=1;aspect.Parent=fallback
    local color=alive==false and Color3.fromRGB(129,142,147) or Color3.fromRGB(202,187,151)
    for _,path in ipairs(def.paths) do for i=1,#path-1 do
        local a,b=path[i],path[i+1];local dx,dy=b[1]-a[1],b[2]-a[2]
        local line=Instance.new("Frame");line.Name="InsigniaLine";line.BorderSizePixel=0;line.BackgroundColor3=color
        line.AnchorPoint=Vector2.new(.5,.5);line.Position=UDim2.fromScale((a[1]+b[1])/2,(a[2]+b[2])/2)
        line.Size=UDim2.new(math.sqrt(dx*dx+dy*dy),0,0,2);line.Rotation=math.deg(math.atan2(dy,dx));line.Parent=fallback
    end end
    local function sync()
        local art=frame:FindFirstChild("Artwork")
        local loaded=asset~=nil and (art and art.IsLoaded or frame.IsLoaded)
        frame:SetAttribute("AssetLoaded",loaded)
        -- Insignia belongs in the log, never on top of an authored portrait.
        -- Rebuilding a HUD must not flash a symbol while a cached texture attaches.
        fallback.Visible=asset==nil
    end
    frame:GetPropertyChangedSignal("IsLoaded"):Connect(sync)
    frame:GetPropertyChangedSignal("ZIndex"):Connect(function()
        local art=frame:FindFirstChild("Artwork");if art then art.ZIndex=frame.ZIndex end
        fallback.ZIndex=frame.ZIndex+1
        for _,child in ipairs(fallback:GetChildren()) do if child:IsA("GuiObject") then child.ZIndex=frame.ZIndex+1 end end
    end)
    frame.Parent=parent;sync()
    -- IsLoaded changes are not consistently signalled by the engine. A bounded,
    -- instance-local watcher also covers cached textures and slow first loads.
    if asset and not frame:GetAttribute("AssetLoaded") then
        task.spawn(function()
            for _=1,120 do
                task.wait(.25)
                if not frame.Parent then return end
                sync();if frame:GetAttribute("AssetLoaded") then return end
            end
        end)
    end
    if asset and not requested[asset.Image] then
        requested[asset.Image]=true
        task.spawn(function()
            -- A rejected or slow texture keeps its readable insignia fallback. No waiting on the UI thread.
            local ok=pcall(function() ContentProvider:PreloadAsync({asset.Image}) end)
            if not ok then requested[asset.Image]=nil end
        end)
    end
    return frame
end
return Portrait
