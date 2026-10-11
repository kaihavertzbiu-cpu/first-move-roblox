local Rules = require(script.Parent.OpeningRules)
local Config = require(game:GetService("ReplicatedStorage").DeadlockShared.LegacyConfig)
return function()
    local checks = 0
    local function check(value, label)
        assert(value, "FIRST_MOVE_TEST: "..label)
        checks += 1
    end
    local state = Rules.new()
    local function apply(owner, intent)
        intent.revision = state.revision
        return Rules.apply(state, owner, intent)
    end
    check(not apply("B", {kind="DraftPick",heroId="ting_sun"}) and state.revision == 0, "wrong actor rejected atomically")
    check(apply("A", {kind="DraftPick",heroId="ting_sun"}), "first pick")
    check(not apply("B", {kind="DraftPick",heroId="ting_sun"}) and state.revision == 1, "duplicate rejected atomically")
    for i=2,10 do check(apply(Rules.actor(state), {kind="DraftPick",heroId=Config.heroes[i].id}), "snake pick "..i) end
    check(#state.rosters.A == 5 and #state.rosters.B == 5 and state.phase == "LinkSetup", "five per side and link gate")
    local owner = state.linkOwner
    local enemy = owner == "A" and "B" or "A"
    check(not apply(owner, {kind="LinkConfirm",allyId="ye_ban",enemyId=state.rosters[enemy][1].id}), "link cannot bind its source")
    local allyId
    for _, h in ipairs(state.rosters[owner]) do if h.id ~= "ye_ban" then allyId=h.id;break end end
    check(apply(owner, {kind="LinkConfirm",allyId=allyId,enemyId=state.rosters[enemy][1].id}), "valid private link")
    check(Rules.view(state, enemy).ownLink == nil and Rules.view(state, owner).ownLink ~= nil, "enemy link remains secret")
    check(apply("A", {kind="CoreLock",core="red"}), "first core locks")
    local hidden = Rules.view(state, "B")
    check(hidden.ownCore == nil and hidden.cores == nil and #hidden.events == 0 and hidden.coreLocked.A, "unrevealed enemy core never projected")
    check(not apply("A", {kind="CoreLock",core="cyan"}), "locked commitment cannot be overwritten")
    check(apply("B", {kind="CoreLock",core="red"}) and state.round == 1 and state.phase == "CoreSelection" and next(state.cores) == nil, "tie reselects without round advance")
    local revision = state.revision
    check(not Rules.apply(state, "A", {kind="CoreLock",core="cyan",revision=revision-1}) and state.revision == revision, "stale request has no effect")
    check(not apply("A", {kind="CoreLock",core="bogus"}), "invalid core rejected")
    check(apply("A", {kind="CoreLock",core="cyan"}) and apply("B", {kind="CoreLock",core="purple"}) and state.actor == "A" and state.phase == "SkillPhase", "source core relation selects first actor")
    local view=Rules.view(state,"A")
    view.rosters.A[1].hp=0
    check(state.rosters.A[1].hp == state.rosters.A[1].maxHp, "projection is isolated from authority")
    check(not apply("A", {kind="DraftPick",heroId="zhui_lie"}), "wrong phase rejected")
    print("FIRST_MOVE_TEST: "..checks.." opening assertions passed")
    return checks
end
