local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Rules=require(script.Parent.MatchRules)
local AI=require(script.Parent.AIDirector)
local Data=require(script.Parent.DataService)
local Training=require(script.Parent.TrainingMatch)
local AITuning=require(ReplicatedStorage.DeadlockShared.AIConfig)
local Service={}
local sessions={}
local rates={}
local tuning={Burst=8,RequestsPerSecond=5,AIThink=.75,MaxIdLength=64}
local schemas={DraftPick={heroId="string"},LinkConfirm={allyId="string",enemyId="string"},CoreLock={core="string"},SkillEnd={},SkillCast={casterId="string",targetId="string?",secondTargetId="string?"},AttackCommit={attackerId="string",targets="targets",useSkill="boolean?"},BlockCommit={blockerId="string?"},DeathRattleTarget={targetId="string"},TrainingContinue={},TrainingRetry={}}
local function validIntent(intent)
    if type(intent)~="table" or type(intent.kind)~="string" or not schemas[intent.kind] then return false end
    if type(intent.revision)~="number" or intent.revision<0 or intent.revision%1~=0 then return false end
    local schema=schemas[intent.kind]
    for key in pairs(intent) do if key~="kind" and key~="revision" and not schema[key] then return false end end
    for key,expected in pairs(schema) do
        local value=intent[key]
        if expected:sub(-1)=="?" and value==nil then continue end
        local basic=expected:gsub("%?","")
        if basic=="targets" then
            if type(value)~="table" or #value<1 or #value>2 then return false end
            for index,id in pairs(value) do
                if type(index)~="number" or index%1~=0 or index<1 or index>#value or type(id)~="string" or #id>tuning.MaxIdLength then return false end
            end
        elseif type(value)~=basic or (basic=="string" and #value>tuning.MaxIdLength) then return false end
    end
    return true
end
local function clone(value)
    if type(value)~="table" then return value end
    local result={};for key,item in pairs(value) do result[key]=clone(item) end;return result
end
function Service.start()
    local folder=Instance.new("Folder");folder.Name="DeadlockRemotes";folder.Parent=ReplicatedStorage
    local intent=Instance.new("RemoteEvent");intent.Name="Intent";intent.Parent=folder
    local stateEvent=Instance.new("RemoteEvent");stateEvent.Name="State";stateEvent.Parent=folder
    local waiting={}
    local Projection=require(script.Parent.PlayerProjection)
    local function send(player,member,errorCode,ack,started,synced)
        local match=member.match;local owner=member.owner
        local view=Projection.view(match.state,owner);view.sessionId=match.id;view.difficulty=match.difficulty;view.mode=match.mode
        view.duration=math.floor(os.clock()-match.started)
        if match.training then view.training=Training.model(match.training) end
        if match.mode=="PvP" and match.completed then
            local other=owner=="A" and "B" or "A";local opponent=match.players[other]
            local present=opponent~=nil and opponent.Parent~=nil and opponent.Parent~=false and sessions[opponent]~=nil and sessions[opponent].match==match
            view.rematch={available=present,requested=match.rematchVotes and match.rematchVotes[owner]==true or false,opponentRequested=match.rematchVotes and match.rematchVotes[other]==true or false}
        end
        if view.report then view.report.readAttempts=match.readAttempts[owner];view.report.readHits=match.readHits[owner] end
        if view.phase=="GameOver" and match.mode~="Training" then
            for _,entry in ipairs(Data.profile(player).history)do if entry.view.sessionId==match.id then view.reward=entry.reward;break end end
        end
        stateEvent:FireClient(player,{view=view,error=errorCode,ack=ack,started=started,synced=synced})
    end
    local function broadcast(match,actingPlayer,started)
        if match.mode~="Training" and match.state.phase=="GameOver" and not match.completed then
            match.completed=true
            for owner,p in pairs(match.players) do
                local view=Projection.view(match.state,owner);view.sessionId=match.id;view.mode=match.mode;view.difficulty=match.difficulty;view.duration=math.floor(os.clock()-match.started)
                view.report.readAttempts=match.readAttempts[owner];view.report.readHits=match.readHits[owner]
                Data.complete(p,view,match.mode=="PvP" and "PvP" or match.difficulty,view.duration,match.readAttempts[owner],match.readHits[owner])
            end
        end
        for _,p in pairs(match.players) do if p.Parent and sessions[p] and sessions[p].match==match then send(p,sessions[p],nil,p==actingPlayer,started) end end
    end
    local function cancel(player,left)
        for i=#waiting,1,-1 do if waiting[i]==player then table.remove(waiting,i) end end
        local member=sessions[player]
        if member and member.match.completed then
            local match=member.match;match.players[member.owner]=nil;sessions[player]=nil
            if player.Parent then stateEvent:FireClient(player,{closed=true}) end
            for _,p in pairs(match.players) do if p.Parent and sessions[p] and sessions[p].match==match then send(p,sessions[p]) end end
            return
        end
        if member then local match=member.match;match.cancelled=true;for _,p in pairs(match.players) do
            if sessions[p] and sessions[p].match==match then sessions[p]=nil;if p.Parent then stateEvent:FireClient(p,{closed=true,abandoned=p~=player and not match.completed}) end end
        end end
        if not member and not left and player.Parent then stateEvent:FireClient(player,{closed=true}) end
    end
    local schedule
    schedule=function(match)
        if match.mode~="AI" or match.cancelled or match.scheduled or match.state.phase=="GameOver" then return end
        local aiIntent=AI.intent(Rules.view(match.state,"B"),"B",match.rng,match.difficulty)
        if not aiIntent then return end
        match.scheduled=true
        task.delay(AITuning[match.difficulty].think,function()
            match.scheduled=false
            if match.cancelled then return end
            local action=AI.intent(Rules.view(match.state,"B"),"B",match.rng,match.difficulty)
            if action then
                local nextState=clone(match.state)
                local ok,err=Rules.apply(nextState,"B",action)
                if not ok then warn("FIRST_MOVE_AI: rejected "..tostring(err));return end
                if nextState.phase=="CoreSelection" and (match.state.phase~="CoreSelection" or nextState.round~=match.state.round or (#nextState.events>#match.state.events and (nextState.events[#nextState.events] or {}).kind=="CoreTie")) then match.coreWindowRevision=nextState.revision end
                match.state=nextState;broadcast(match)
            end
            schedule(match)
        end)
    end
    local function create(players,mode,difficulty)
        local match={id=HttpService:GenerateGUID(false),state=Rules.new(),rng=Random.new(),mode=mode,difficulty=difficulty,players=players,started=os.clock(),readAttempts={A=0,B=0},readHits={A=0,B=0},coreWindowRevision=0}
        if mode=="Training" then match.state,match.training=Training.new() end
        for owner,p in pairs(players) do sessions[p]={match=match,owner=owner} end
        broadcast(match,nil,true);schedule(match)
    end
    intent.OnServerEvent:Connect(function(player,message)
        local now=os.clock();local rate=rates[player] or {time=now,tokens=tuning.Burst}
        rate.tokens=math.min(tuning.Burst,rate.tokens+(now-rate.time)*tuning.RequestsPerSecond);rate.time=now;rates[player]=rate
        if rate.tokens<1 then return end
        rate.tokens-=1
        if type(message)~="table" or type(message.command)~="string" then return end
        if message.command=="Start" then
            if sessions[player] then send(player,sessions[player],nil,true,true);return end
            for key in pairs(message) do if key~="command" and key~="mode" and key~="difficulty" then stateEvent:FireClient(player,{startError="InvalidRequest"});return end end
            local mode=message.mode or "AI";if mode~="AI" and mode~="PvP" and mode~="Training" then stateEvent:FireClient(player,{startError="InvalidMode"});return end
            if mode=="PvP" then
                for _,p in ipairs(waiting) do if p==player then stateEvent:FireClient(player,{queued=true});return end end
                local opponent
                while #waiting>0 and not opponent do local candidate=table.remove(waiting,1);if candidate.Parent and not sessions[candidate] and candidate~=player then opponent=candidate end end
                if opponent then create({A=opponent,B=player},"PvP","Standard") else table.insert(waiting,player);stateEvent:FireClient(player,{queued=true}) end
                return
            end
            if mode=="Training" then
                for i=#waiting,1,-1 do if waiting[i]==player then table.remove(waiting,i) end end
                create({A=player},"Training","Standard");return
            end
            local difficulty=message.difficulty or "Standard"
            if not AITuning[difficulty] or (difficulty=="Advanced" and Data.profile(player).stats.gamesPlayed<1) then stateEvent:FireClient(player,{startError="DifficultyLocked"});return end
            for i=#waiting,1,-1 do if waiting[i]==player then table.remove(waiting,i) end end
            create({A=player},"AI",difficulty);return
        end
        local member=sessions[player]
        if message.command=="Quit" then if not member or message.sessionId==nil or message.sessionId==member.match.id then cancel(player,false) end;return end
        if not member or message.sessionId~=member.match.id then return end
        if message.command=="Sync" then send(player,member,nil,false,false,true);return end
        local match=member.match;local owner=member.owner
        if message.command=="Restart" then
            for key in pairs(message) do if key~="command" and key~="sessionId" and key~="accept" then send(player,member,"InvalidRequest",true);return end end
            if not match.completed then send(player,member,"WrongPhase",true);return end
            if match.mode=="PvP" then
                if type(message.accept)~="boolean" then send(player,member,"InvalidRequest",true);return end
                local other=owner=="A" and "B" or "A";local opponent=match.players[other]
                if not opponent or not opponent.Parent or not sessions[opponent] or sessions[opponent].match~=match then send(player,member,"OpponentUnavailable",true);return end
                match.rematchVotes=match.rematchVotes or {};match.rematchVotes[owner]=message.accept
                if match.rematchVotes.A and match.rematchVotes.B then
                    local players={A=match.players.B,B=match.players.A};match.players={};match.cancelled=true
                    create(players,"PvP","Standard")
                else broadcast(match,player) end
                return
            end
            if match.mode~="AI" then send(player,member,"WrongPhase",true);return end
            if message.accept~=nil then send(player,member,"InvalidRequest",true);return end
            match.players[owner]=nil;sessions[player]=nil
            create({A=player},"AI",match.difficulty);return
        end
        if message.command~="Action" or not validIntent(message.intent) then send(player,member,"InvalidIntent",true);return end
        local action=clone(message.intent)
        if match.mode=="Training" then
            local nextState,nextTraining=clone(match.state),clone(match.training)
            local ok,result=Training.apply(nextState,nextTraining,action)
            if ok then
                if result=="Retry" then nextState,nextTraining=Training.new(match.state.revision+1)
                elseif result=="BlockRead" then Data.learning(player,"blockChosen");Data.learning(player,"blockRead")
                elseif result=="BlockChosen" then Data.learning(player,"blockChosen")
                elseif result=="SkillUsed" then Data.learning(player,"skillUsed")
                elseif result=="AttackCommitted" then Data.learning(player,"attackCommitted") end
                match.state,match.training=nextState,nextTraining;broadcast(match,player)
            else send(player,member,result,true) end
            return
        end
        -- Both secret core choices may arrive at the same revision. Rebase only within
        -- this core window; a tie/new round starts a new window and rejects old choices.
        if action.kind=="CoreLock" and match.state.phase=="CoreSelection" and not match.state.cores[owner] and action.revision>=match.coreWindowRevision and action.revision<=match.state.revision then action.revision=match.state.revision end
        local nextState=clone(match.state)
        local ok,err=Rules.apply(nextState,owner,action)
        if ok then
            if message.intent.kind=="BlockCommit" and message.intent.blockerId then
                match.readAttempts[owner]+=1
                for i=#match.state.events+1,#nextState.events do local e=nextState.events[i];if e.kind=="Block" and e.target==message.intent.blockerId then match.readHits[owner]+=1;break end end
            end
            if nextState.phase=="CoreSelection" and (match.state.phase~="CoreSelection" or nextState.round~=match.state.round or (#nextState.events>#match.state.events and (nextState.events[#nextState.events] or {}).kind=="CoreTie")) then match.coreWindowRevision=nextState.revision end
            match.state=nextState
        end
        if ok then broadcast(match,player);schedule(match) else send(player,member,err,true) end
    end)
    Players.PlayerRemoving:Connect(function(player) cancel(player,true);rates[player]=nil end)
    workspace:SetAttribute("MatchAvailable",true)
end
return Service
