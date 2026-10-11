local Players=game:GetService("Players")
local Schema=require(script.Parent.ProfileSchema)
local Data={};local sessions={};local remote;local store
local studio=game:GetService("RunService"):IsStudio();local memory={}
local function retry(fn)
    for attempt=1,3 do local ok,value=pcall(fn);if ok then return true,value end;if attempt<3 then task.wait(2^(attempt-1)+math.random()*.25) end end
    return false
end
local function packet(s) return {profile=Schema.copy(s.profile),storage={mode=studio and "Studio" or "Cloud",status=s.status}} end
local function push(player,s) if player.Parent and remote then remote:FireClient(player,packet(s)) end end
function Data.profile(player) local s=sessions[player];return s and Schema.copy(s.profile) or Schema.new() end
function Data.flush(player)
    local s=sessions[player];if not s or s.loading or s.busy or s.readOnly or #s.ops==0 then return false end
    s.busy=true;s.status="Saving";push(player,s);local count=#s.ops;local batch={};for i=1,count do batch[i]=Schema.copy(s.ops[i]) end
    local blocked=false
    local ok,value=retry(function()
        return store:UpdateAsync("user_"..player.UserId,function(raw)
            if not Schema.writable(raw) then blocked=true;return nil end
            local p=Schema.normalize(raw);for _,op in ipairs(batch) do p=Schema.apply(p,op) end;return p
        end)
    end)
    if blocked then s.readOnly=true;s.busy=false;s.status="ReadOnly";s.ops={};push(player,s);return false end
    if ok then for _=1,count do table.remove(s.ops,1) end;s.profile=Schema.normalize(value);for _,op in ipairs(s.ops) do s.profile=Schema.apply(s.profile,op) end end
    s.busy=false;s.status=ok and (#s.ops==0 and "Saved" or "Pending") or "Unavailable";push(player,s)
    if ok and #s.ops>0 then task.defer(Data.flush,player) end
    return ok
end
local function enqueue(player,op)
    local s=sessions[player];if not s then return end
    -- Coalesce pending preferences; do not let rapid toggling create an unbounded queue.
    if op.kind=="Settings" and not s.busy then for i=#s.ops,1,-1 do if s.ops[i].kind=="Settings" then table.remove(s.ops,i) end end end
    s.profile=Schema.apply(s.profile,op)
    if s.readOnly then s.status="ReadOnly";push(player,s);return end
    table.insert(s.ops,Schema.copy(op));s.status="Pending";push(player,s)
    s.serial+=1;local ticket=s.serial;task.delay(op.kind=="Match" and 0 or 3,function() if sessions[player]==s and s.serial==ticket then Data.flush(player) end end)
end
function Data.complete(player,view,difficulty,duration,attempts,hits)
    enqueue(player,{kind="Match",entry=Schema.entry(view,difficulty,duration),readAttempts=attempts,readHits=hits})
end
function Data.learning(player,step) enqueue(player,{kind="Learning",step=step}) end
function Data.settings(player,settings)
    local valid=Schema.settings(settings,true);if not valid then return false end
    enqueue(player,{kind="Settings",settings=valid});return true
end
local function load(player)
    local s={profile=Schema.new(),ops={},loading=true,busy=false,status="Loading",serial=0};sessions[player]=s
    task.spawn(function()
        local ok,value=retry(function() return store:GetAsync("user_"..player.UserId) end)
        if sessions[player]~=s then return end
        if ok then
            s.readOnly=not Schema.writable(value)
            s.profile=Schema.normalize(value);for _,op in ipairs(s.ops) do s.profile=Schema.apply(s.profile,op) end
            if s.readOnly then s.ops={} end
        end
        s.loading=false;s.status=s.readOnly and "ReadOnly" or ok and (#s.ops>0 and "Pending" or "Saved") or "Unavailable";push(player,s)
        if #s.ops>0 then task.defer(Data.flush,player) end
    end)
end
function Data.start()
    if studio then store={GetAsync=function(_,key) return Schema.copy(memory[key]) end,UpdateAsync=function(_,key,fn) local nextValue=fn(Schema.copy(memory[key]));if nextValue~=nil then memory[key]=nextValue end;return Schema.copy(memory[key]) end}
    else store=game:GetService("DataStoreService"):GetDataStore("FirstMoveProfiles_v1") end
    local folder=Instance.new("Folder");folder.Name="FirstMoveProfile";folder.Parent=game.ReplicatedStorage
    remote=Instance.new("RemoteEvent");remote.Name="Updated";remote.Parent=folder
    local request=Instance.new("RemoteFunction");request.Name="Request";request.Parent=folder
    local rates={}
    request.OnServerInvoke=function(player,message)
        local s=sessions[player];if not s then return nil end
        if message=="Get" then
            local now=os.clock();if now-(rates[player] or -10)<.15 then return nil end;rates[player]=now
            return packet(s)
        end
        if type(message)~="table" then return nil end
        local now=os.clock();if now-(rates[player] or -10)<.15 then return packet(s) end;rates[player]=now
        if message.command=="Buy" or message.command=="Equip" then
            for key in pairs(message)do if key~="command" and key~="itemId"then return nil end end
            if s.loading or s.readOnly or s.busy or s.status=="Unavailable" then local result=packet(s);result.error="档案尚未就绪，请稍后重试";return result end
            local catalog=require(game.ReplicatedStorage.DeadlockShared.ProgressionConfig)
            local id=message.itemId
            if type(id)~="string" or (#id>40) or (id~="default" and not catalog.ById[id])then return nil end
            local e=s.profile.economy;local err
            if message.command=="Buy" then
                if id=="default" or e.owned[id]then err="已拥有此外观"
                elseif e.credits<catalog.ById[id].price then err="核晶不足，完成对局可获得核晶" end
            elseif id~="default" and not e.owned[id]then err="尚未拥有此外观" end
            if err then local result=packet(s);result.error=err;return result end
            enqueue(player,{kind=message.command,itemId=id});Data.flush(player)
            return packet(s)
        end
        if message.command~="Settings" then return nil end
        for key in pairs(message) do if key~="command" and key~="settings" then return nil end end
        if not Data.settings(player,message.settings) then return nil end;return packet(s)
    end
    Players.PlayerAdded:Connect(load);for _,p in ipairs(Players:GetPlayers()) do load(p) end
    Players.PlayerRemoving:Connect(function(p)
        rates[p]=nil;task.spawn(function() local deadline=os.clock()+24;local s=sessions[p];while s and (s.loading or s.busy) and os.clock()<deadline do task.wait(.1) end;Data.flush(p);sessions[p]=nil end)
    end)
    task.spawn(function() while task.wait(60) do for p in pairs(sessions) do task.spawn(Data.flush,p) end end end)
    game:BindToClose(function()
        local pending=0;for p in pairs(sessions) do pending+=1;task.spawn(function() local s=sessions[p];local deadline=os.clock()+23;while s and (s.loading or s.busy) and os.clock()<deadline do task.wait(.1) end;Data.flush(p);pending-=1 end) end
        local deadline=os.clock()+25;while pending>0 and os.clock()<deadline do task.wait(.1) end
    end)
end
return Data
