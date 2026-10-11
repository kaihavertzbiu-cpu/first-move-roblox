-- Server-only opening migration. Combat resolution is deliberately not implemented here.
local Config = require(game:GetService("ReplicatedStorage").DeadlockShared.LegacyConfig)
local Rules = {}
local definitions = {}
for _, hero in ipairs(Config.heroes) do definitions[hero.id] = hero end
local function other(owner) return owner == "A" and "B" or "A" end
local function owns(state, owner, id)
    for _, hero in ipairs(state.rosters[owner]) do
        if hero.id == id then return hero end
    end
end
local function beginCores(state)
    state.phase = "CoreSelection"
    state.round = 1
    state.actor = nil
end
function Rules.new()
    return {revision=0, phase="Draft", round=0, draftStep=1,
        picksRemaining=Config.draft[1].picks, rosters={A={}, B={}},
        taken={}, cores={}, link=nil, events={}}
end
function Rules.actor(state)
    if state.phase == "Draft" then return Config.draft[state.draftStep].player end
    if state.phase == "LinkSetup" then return state.linkOwner end
    return state.actor
end
-- Validate completely before mutation. Owner is supplied by the server, never by a payload.
function Rules.apply(state, owner, intent)
    if owner ~= "A" and owner ~= "B" then return false, "InvalidOwner" end
    if type(intent) ~= "table" or intent.revision ~= state.revision then return false, "StaleRevision" end
    local kind = intent.kind
    if state.phase == "Draft" and kind == "DraftPick" then
        if Rules.actor(state) ~= owner then return false, "WrongActor" end
        local id = intent.heroId
        if type(id) ~= "string" or not definitions[id] then return false, "UnknownHero" end
        if state.taken[id] then return false, "HeroTaken" end
        local def = definitions[id]
        state.taken[id] = true
        table.insert(state.rosters[owner], {id=id, hp=def.maxHp, maxHp=def.maxHp,
            atk=def.atk, cooldown=0, alive=true, used=false, statuses={}})
        state.picksRemaining -= 1
        if state.picksRemaining == 0 then
            state.draftStep += 1
            local step = Config.draft[state.draftStep]
            if step then state.picksRemaining = step.picks
            else
                for _, side in ipairs({"A", "B"}) do
                    if owns(state, side, "ye_ban") then state.linkOwner = side end
                end
                if state.linkOwner then state.phase = "LinkSetup" else beginCores(state) end
            end
        end
    elseif state.phase == "LinkSetup" and kind == "LinkConfirm" then
        if owner ~= state.linkOwner then return false, "WrongActor" end
        if intent.allyId == "ye_ban" or not owns(state, owner, intent.allyId) then return false, "InvalidAlly" end
        if not owns(state, other(owner), intent.enemyId) then return false, "InvalidEnemy" end
        state.link = {owner=owner, allyId=intent.allyId, enemyId=intent.enemyId, active=true}
        beginCores(state)
    elseif state.phase == "CoreSelection" and kind == "CoreLock" then
        if type(intent.core) ~= "string" or not Config.beats[intent.core] then return false, "InvalidCore" end
        if state.cores[owner] then return false, "AlreadyLocked" end
        state.cores[owner] = intent.core
        if state.cores.A and state.cores.B then
            local a, b = state.cores.A, state.cores.B
            table.insert(state.events, {kind="CoreReveal", round=state.round, A=a, B=b})
            if a == b then
                state.cores = {}
                table.insert(state.events, {kind="CoreTie", round=state.round})
            else
                state.initiative = Config.beats[a] == b and "A" or "B"
                state.actor = state.initiative
                state.phase = "SkillPhase"
            end
        end
    else return false, "WrongPhase" end
    state.revision += 1
    return true
end
-- Explicit public projection: never clone the private state into a network response.
function Rules.view(state, owner)
    assert(owner == "A" or owner == "B", "Invalid viewer")
    local view = {revision=state.revision, phase=state.phase, round=state.round,
        actor=Rules.actor(state), initiative=state.initiative,
        picksRemaining=state.picksRemaining, rosters={A={}, B={}},
        coreLocked={A=state.cores.A ~= nil, B=state.cores.B ~= nil},
        ownCore=state.cores[owner], events={}}
    for _, side in ipairs({"A", "B"}) do
        for _, hero in ipairs(state.rosters[side]) do
            table.insert(view.rosters[side], {id=hero.id, hp=hero.hp, maxHp=hero.maxHp,
                atk=hero.atk, cooldown=hero.cooldown, alive=hero.alive, used=hero.used})
        end
    end
    if state.link and state.link.owner == owner then
        view.ownLink = {allyId=state.link.allyId, enemyId=state.link.enemyId, active=state.link.active}
    end
    for _, event in ipairs(state.events) do table.insert(view.events, table.clone(event)) end
    return view
end
return Rules
