local Profile={Value=nil,Storage={mode="Cloud",status="Loading"},Changed=Instance.new("BindableEvent")}
local request;local desired;local serial=0
local function accept(packet)
    if type(packet)~="table" or type(packet.profile)~="table" then return end
    if desired then packet.profile.settings=table.clone(desired) end
    Profile.Value=packet.profile;Profile.Storage=packet.storage;Profile.Changed:Fire()
end
function Profile.start()
    task.spawn(function()
        local folder=game.ReplicatedStorage:WaitForChild("FirstMoveProfile",15)
        if not folder then Profile.Storage.status="Unavailable";Profile.Changed:Fire();return end
        request=folder:WaitForChild("Request");folder.Updated.OnClientEvent:Connect(accept)
        local ok,packet=pcall(function() return request:InvokeServer("Get") end)
        if ok then accept(packet) else Profile.Storage.status="Unavailable";Profile.Changed:Fire() end
    end)
end
function Profile.save(settings)
    desired=table.clone(settings);serial+=1;local ticket=serial
    task.delay(.4,function()
        if serial~=ticket or not request then return end
        local ok,packet=pcall(function() return request:InvokeServer({command="Settings",settings=desired}) end)
        if ok then if serial==ticket then desired=nil end;accept(packet) else Profile.Storage.status="Unavailable";Profile.Changed:Fire() end
    end)
end
function Profile.statusText()
    if Profile.Storage.status=="ReadOnly" then return "档案版本受保护 · 本次进度暂不写入" end
    if Profile.Storage.mode=="Studio" then return "Studio 试玩 · 记录仅在本次测试内保留" end
    return ({Loading="正在读取行动档案…",Saving="正在保存…",Pending="有记录待保存",Saved="行动档案已保存",Unavailable="云端暂不可用 · 可以继续对局"})[Profile.Storage.status] or "正在同步…"
end
function Profile.action(command,itemId,done)
    if not request then if done then done("档案正在读取")end;return end
    task.spawn(function()
        local ok,packet=pcall(function()return request:InvokeServer({command=command,itemId=itemId})end)
        if ok and packet then accept(packet)end
        if done then done(not ok and "连接失败，请重试" or not packet and "请求未被接受" or packet.error or packet.storage.status=="Unavailable" and "保存待重试，请勿重复兑换" or "已更新")end
    end)
end
return Profile
