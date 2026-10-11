-- Real GUI and TweenService; automatically cleaned, no profile/match mutation.
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local unit=require(modules.UnitPresentation)
local identity=require(modules.UnitIdentity)
local kit=assert(loadstring("local script,require=...\n"..modules.InterfaceKit.Source))({Parent=modules},function(m)
 if m==modules.AudioController then return {Play=function()end}end;return require(m)
end)
local gui=Instance.new("ScreenGui");gui.Name="FirstMoveCardReactionQA";gui.Parent=game.CoreGui
local checks=0
local function check(v,name)assert(v,name);checks+=1 end
local ok,err=pcall(function()
 for _,size in ipairs({Vector2.new(110,90),Vector2.new(180,126)})do
  local b=Instance.new("TextButton");b.Size=UDim2.fromOffset(size.X,size.Y);b.Parent=gui
  task.wait()
  local h={id="bai_ji",hp=23,maxHp=23,alive=true,atk=4}
  unit.roster(kit,b,h,identity.byId.bai_ji,"A","",false)
  local portrait=b.UnitPortrait;local pos=portrait.Position
  unit.react(b,{kind="Damage",impactTier=3,presentedHp=11,presentedAlive=true},.3,false)
  check(b.HealthValue.Text=="11 / 23","actual HP text at contact")
  check(portrait.Position~=pos,"portrait recoil at contact")
  task.wait(.35)
  check(not b:FindFirstChild("CardReaction") and portrait.Position==pos,"recoil restores and cleans")
  check(math.abs(b.HealthTrack.HealthFill.Size.X.Scale-11/23)<.001,"health fill converges")
  unit.react(b,{kind="Death",presentedHp=0,presentedAlive=false},.4,false)
  check(#b.CardReaction:GetChildren()==6,"six authored portrait fragments")
  check(not portrait.Visible and b.HealthValue.Text=="阵亡","whole portrait hidden only during fracture")
  check(b:GetAttribute("Disabled") and not b.Selectable,"dead card cannot be targeted")
  task.wait(.45)
  check(portrait.Visible and not b:FindFirstChild("CardReaction"),"fracture cleans to persistent dead portrait")
  check(math.abs(portrait.Artwork.ImageTransparency-.55)<.001,"dead portrait stays subdued")
  unit.react(b,{kind="Death",presentedHp=0,presentedAlive=false},.2,true)
  check(#b.CardReaction:GetChildren()==0 and portrait.Visible,"reduced motion omits moving fragments")
  b:Destroy()
 end
 -- Early destruction cannot leave floating clones or deferred access errors.
 local b=Instance.new("TextButton");b.Size=UDim2.fromOffset(180,126);b.Parent=gui;task.wait()
 unit.roster(kit,b,{id="bai_ji",hp=23,maxHp=23,alive=true,atk=4},identity.byId.bai_ji,"A","",false)
 unit.react(b,{kind="Death",presentedHp=0,presentedAlive=false},.4,false);b:Destroy();task.wait(.5)
 check(#gui:GetChildren()==0,"screen exit destroys all fragments")
end)
gui:Destroy();if not ok then error(err)end
return game.HttpService:JSONEncode({passed=checks,scope="Real GUI/tween fixture; not natural battle or hardware acceptance"})
