-- Studio regressions must pass before the match service becomes available.
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false
workspace:SetAttribute("DeadlockMilestone", "Sprint2FunctionalQA")
workspace:SetAttribute("MatchAvailable", false)
print("[FirstMove] Command Room ready. Server-authoritative match starting.")
if game:GetService("RunService"):IsStudio() then
    workspace:SetAttribute("OpeningAssertionsPassed", require(script.Parent.OpeningTests)())
    workspace:SetAttribute("CombatAssertionsPassed", require(script.Parent.CombatTests)())
    workspace:SetAttribute("ReportAssertionsPassed", require(script.Parent.BattleReportTests)())
end
require(script.Parent.DataService).start()
require(script.Parent.MatchService).start()
