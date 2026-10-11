local T=require(game.StarterPlayer.StarterPlayerScripts.DeadlockClient.TutorialController)
local Rules=require(game.ServerScriptService.DeadlockServer.MatchRules)
local P=require(game.ServerScriptService.DeadlockServer.PlayerProjection)
local checks={}
local state=Rules.new()
local function check(n,v) assert(v,n);table.insert(checks,n) end
for _,side in ipairs({"A","B"}) do
 local v=P.view(state,side);local m=T.model(v,{})
 check(side.." draft guidance does not assume viewer is first",m.tip:find("首选方",1,true)~=nil and m.tip:find("你 1",1,true)==nil)
 check(side.." turn guidance follows mirrored actor",(v.actor=="A" and m.body:find("当前还可选 1 名",1,true)~=nil) or (v.actor=="B" and m.body:find("对手正在选人",1,true)~=nil))
end
assert(Rules.apply(state,"A",{kind="DraftPick",heroId="lan_dun",revision=state.revision}))
local v=P.view(state,"B");local m=T.model(v,{})
check("Second picker sees own remaining picks",v.actor=="A" and m.body:find("当前还可选 2 名",1,true)~=nil)
return game.HttpService:JSONEncode({scope="Shipping field guide with actual mirrored draft projections; no native PvP inputs",passed=#checks,checks=checks})
