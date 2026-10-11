-- Server-owned profile operations. Match IDs make retrying writes idempotent.
local Schema={Version=2,HistoryLimit=5,ReceiptLimit=64}
local Progression=require(game.ReplicatedStorage.DeadlockShared.ProgressionConfig)
local defaults={master=.65,sfx=.7,music=.35,reduced=false,large=false,guide=true,language="auto"}
local fields={gamesPlayed=0,wins=0,losses=0,draws=0,currentStreak=0,bestStreak=0,totalTurns=0,duration=0,readHits=0,readAttempts=0}
local function number(n,max) return type(n)=="number" and n==n and n>=0 and n<=max end
local function copy(t) if type(t)~="table" then return t end;local c={};for k,v in pairs(t) do c[k]=copy(v) end;return c end
Schema.copy=copy
function Schema.settings(raw,strict)
    if type(raw)~="table" then return strict and nil or copy(defaults) end
    local out=copy(defaults)
    for k,v in pairs(raw) do
        if defaults[k]==nil then if strict then return nil end
        elseif k=="language" then if v=="auto"or v=="zh-cn"or v=="en-us"then out[k]=v elseif strict then return nil end
        elseif type(defaults[k])=="boolean" then if type(v)=="boolean" then out[k]=v elseif strict then return nil end
        elseif number(v,1) then out[k]=v elseif strict then return nil end
    end
    return out
end
function Schema.new() return {schemaVersion=2,economy={credits=0,xp=0,rating=0,owned={},equipped="default"},stats=copy(fields),settings=copy(defaults),tutorialComplete=false,firstMatchCompleted=false,learning={blockChosen=false,blockRead=false,skillUsed=false,attackCommitted=false},history={},receipts={},difficulty={Standard={played=0,wins=0},Advanced={played=0,wins=0},PvP={played=0,wins=0}}} end
function Schema.writable(raw)
    return raw==nil or (type(raw)=="table" and (raw.schemaVersion==1 or raw.schemaVersion==Schema.Version))
end
local function validView(v)
    if type(v)~="table" or v.phase~="GameOver" or type(v.sessionId)~="string" or #v.sessionId>80 or (v.winner~="A" and v.winner~="B" and v.winner~="Draw") or not number(v.round,1000) then return false end
    local r=v.report;if type(r)~="table" or r.schemaVersion~=1 or type(r.rounds)~="table" or #r.rounds>100 or type(r.teams)~="table" or type(v.events)~="table" or #v.events>200 or type(v.rosters)~="table" then return false end
    for _,side in ipairs({"A","B"}) do
        if type(r.teams[side])~="table" or type(v.rosters[side])~="table" or #v.rosters[side]>5 then return false end
        for _,k in ipairs({"damage","healing","blocks","executions","hp","survivors"}) do if not number(r.teams[side][k],100000) then return false end end
        for _,h in ipairs(v.rosters[side]) do if type(h)~="table" or type(h.id)~="string" or type(h.alive)~="boolean" or not number(h.hp,1000) then return false end end
    end
    if not number(r.finalRound,1000) or not number(r.completedRounds,1000) then return false end
    for _,row in ipairs(r.rounds) do
        if type(row)~="table" or not number(row.round,1000) or not number(row.ties,10000) or type(row.fallen)~="table" or type(row.teams)~="table" then return false end
        for _,side in ipairs({"A","B"}) do if type(row.teams[side])~="table" or not number(row.teams[side].damage,100000) or not number(row.teams[side].healing,100000) then return false end end
        for _,h in ipairs(row.fallen) do if type(h)~="table" or type(h.id)~="string" or (h.owner~="A" and h.owner~="B") then return false end end
    end
    for _,e in ipairs(v.events) do if type(e)~="table" or type(e.kind)~="string" or not number(e.round,1000) then return false end end
    return true
end
function Schema.normalize(raw)
    local p=Schema.new();if type(raw)~="table" or not Schema.writable(raw) then return p end
    local e=raw.economy
    if type(e)=="table" then
        for _,k in ipairs({"credits","xp","rating"})do if number(e[k],100000000)then p.economy[k]=math.floor(e[k])end end
        if type(e.owned)=="table" then for id in pairs(Progression.ById)do if e.owned[id]==true then p.economy.owned[id]=true end end end
        if type(e.equipped)=="string" and p.economy.owned[e.equipped] then p.economy.equipped=e.equipped end
    end
    p.settings=Schema.settings(raw.settings)
    -- Old tutorialComplete meant "a match ended". Only explicit learning steps prove training.
    if type(raw.learning)=="table" then for k in pairs(p.learning) do p.learning[k]=raw.learning[k]==true end end
    p.tutorialComplete=p.learning.blockRead and p.learning.attackCommitted
    p.firstMatchCompleted=raw.firstMatchCompleted==true or (type(raw.stats)=="table" and number(raw.stats.gamesPlayed,100000000) and raw.stats.gamesPlayed>0) or false
    if type(raw.stats)=="table" then for k in pairs(fields) do if number(raw.stats[k],100000000) then p.stats[k]=math.floor(raw.stats[k]) end end end
    for _,name in ipairs({"Standard","Advanced","PvP"}) do local d=type(raw.difficulty)=="table" and raw.difficulty[name];if type(d)=="table" and number(d.played,10000000) and number(d.wins,d.played) then p.difficulty[name]=copy(d) end end
    if type(raw.receipts)=="table" then for _,id in ipairs(raw.receipts) do if type(id)=="string" and #id<=80 then table.insert(p.receipts,id);if #p.receipts==Schema.ReceiptLimit then break end end end end
    if type(raw.history)=="table" then for _,row in ipairs(raw.history) do if type(row)=="table" and validView(row.view) and number(row.duration,21600) and (row.difficulty=="Standard" or row.difficulty=="Advanced" or row.difficulty=="PvP") and number(row.finishedAt,10000000000) then table.insert(p.history,copy(row));if #p.history==Schema.HistoryLimit then break end end end end
    p.stats.readHits=math.min(p.stats.readHits,p.stats.readAttempts)
    return p
end
function Schema.apply(raw,op)
    if not Schema.writable(raw) then return copy(raw) end
    local p=Schema.normalize(raw)
    if type(op)~="table" then return p end
    if op.kind=="Buy" then
        local item=type(op.itemId)=="string" and Progression.ById[op.itemId]
        if item and not p.economy.owned[item.id] and p.economy.credits>=item.price then
            p.economy.credits-=item.price;p.economy.owned[item.id]=true
        end;return p
    end
    if op.kind=="Equip" then
        if op.itemId=="default" or type(op.itemId)=="string" and p.economy.owned[op.itemId] then p.economy.equipped=op.itemId end
        return p
    end
    if op.kind=="Settings" then local s=Schema.settings(op.settings,true);if s then p.settings=s end;return p end
    if op.kind=="Learning" then
        if p.learning[op.step]~=nil then p.learning[op.step]=true end
        p.tutorialComplete=p.learning.blockRead and p.learning.attackCommitted
        return p
    end
    if op.kind~="Match" or type(op.entry)~="table" or not validView(op.entry.view) then return p end
    local v=op.entry.view;for _,id in ipairs(p.receipts) do if id==v.sessionId then return p end end
    local win=v.winner=="A"
    local credits=win and Progression.WinCredits or Progression.LossCredits
    local xp=win and Progression.WinXP or Progression.LossXP
    p.economy.credits+=credits;p.economy.xp+=xp
    local before=p.economy.rating
    if op.entry.difficulty=="PvP" and v.winner~="Draw" then p.economy.rating=math.max(0,before+(win and Progression.RankWin or -Progression.RankLoss))end
    op=copy(op);op.entry.reward={credits=credits,xp=xp,rating=p.economy.rating-before}
    op.entry.view.reward=copy(op.entry.reward)
    table.insert(p.receipts,1,v.sessionId);while #p.receipts>Schema.ReceiptLimit do table.remove(p.receipts) end
    local s=p.stats;s.gamesPlayed+=1;s.totalTurns+=v.round;s.duration+=op.entry.duration
    local outcome=v.winner=="A" and "wins" or v.winner=="B" and "losses" or "draws";s[outcome]+=1
    s.currentStreak=v.winner=="A" and s.currentStreak+1 or 0;s.bestStreak=math.max(s.bestStreak,s.currentStreak)
    s.readAttempts+=op.readAttempts;s.readHits+=math.min(op.readHits,op.readAttempts)
    local d=p.difficulty[op.entry.difficulty];d.played+=1;if v.winner=="A" then d.wins+=1 end
    p.firstMatchCompleted=true;table.insert(p.history,1,copy(op.entry));while #p.history>Schema.HistoryLimit do table.remove(p.history) end
    return p
end
function Schema.entry(view,difficulty,duration)
    local v=copy(view);while #v.events>200 do table.remove(v.events,1) end;while #v.report.rounds>100 do table.remove(v.report.rounds,1) end
    return {view=v,difficulty=difficulty,duration=math.clamp(math.floor(duration),0,21600),finishedAt=os.time()}
end
return Schema
