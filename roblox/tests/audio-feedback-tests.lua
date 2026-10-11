-- Deterministic cancellation and polyphony checks. Does not play audible QA sounds.
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local config=assert(loadstring("local script,require=...\n"..modules.PresentationConfig.Source))({Parent=modules},require)
local sounds,timers,spawns={},{},{}
local now,played,checks=0,0,0
local function check(v,n) assert(v,n);checks+=1 end
local instance={new=function(class)
 local s={IsPlaying=false,IsLoaded=false,Loaded={Connect=function()end}}
 if class=="Sound" then
  function s:Play() self.IsPlaying=true;played+=1 end
  function s:Stop()self.IsPlaying=false end
  table.insert(sounds,s)
 end
 return s
end}
local services={SoundService={},ContentProvider={PreloadAsync=function()end},TweenService={Create=function(_,s,info,goal)
 return {Play=function()end,Cancel=function()end}
end}}
local scheduler={spawn=function(fn)table.insert(spawns,fn)end,delay=function(t,fn)table.insert(timers,{time=now+t,fn=fn})end}
local function advance(t)
 local untilTime=now+t
 while true do
  local nextIndex;local soon=math.huge
  for i,row in ipairs(timers)do if row.time<soon then soon=row.time;nextIndex=i end end
  if soon>untilTime then break end
  now=soon;local row=table.remove(timers,nextIndex);row.fn()
 end
 now=untilTime
end
local music={Duck=function()end,Release=function()end}
local a=assert(loadstring("local game,script,require,task,Instance=...\n"..modules.AudioController.Source))(
 {GetService=function(_,key)return services[key]end},{Parent=modules},
 function(m)if m==modules.PresentationConfig then return config else return music end end,scheduler,instance)
local count=0;for _,n in pairs(config.Audio.Voices)do count+=n end
local sourceCount=0;for _ in pairs(config.Audio.Sources)do sourceCount+=1 end
check(#sounds==count+sourceCount,"bounded pool plus production preload sources")
check(#spawns==sourceCount,"sources preload independently")
a.Play("hit");a.Play("hit");a.Play("hit")
local active=0;for _,s in ipairs(sounds)do if s.IsPlaying then active+=1 end end
check(active==3,"successive hits do not cut one another")
check(a.LastSources.hit==config.Audio.Sources.impact.id,"unloaded hit retains production source")
advance(.04);check(played==6,"each hit gets one body layer")
a.Reset();advance(2)
for _,s in ipairs(sounds)do check(not s.IsPlaying,"reset clears voice")end
local before=played;a.Play("hit");a.Reset();advance(1);check(played==before+1,"reset cancels delayed body")
a.Play("hit_crushing");a.SetLevels(0,1);before=played;advance(2);a.Play("death")
check(played==before,"mute cancels queued tails and new playback")
a.SetLevels(1,1);a.Play("hit_heavy");advance(.03);check(a.LastSources["hit_heavy:body"]==config.Audio.Sources.metal.id,"heavy body source")
a.Reset();a.Outcome("A");a.Reset();before=played;advance(3);check(played==before,"leaving result cancels outcome callbacks")
a.SetLevels(1,1)
for i=1,100 do a.Play("hit_crushing")end
advance(.04);check(#sounds==count+sourceCount,"burst cannot allocate additional voices")
active=0;for _,s in ipairs(sounds)do if s.IsPlaying then active+=1 end end
check(active<=config.Audio.Voices.Tactical+config.Audio.Voices.Body,"burst respects channel limits")
advance(3);for _,s in ipairs(sounds)do check(not s.IsPlaying,"tails finish")end
before=played;a.Play("hover");check(played==before,"hover is visually responsive without audible chatter")
a.Play("select");a.Reset();advance(.04)
check(a.LastSources.select==config.Audio.Sources.uiLatch.id,"select uses metal latch rather than slider click")
check(a.LastSources["select:body"]==config.Audio.Sources.impact.id,"select has a separate low body")
check(played==before+2,"screen transitions retain both UI layers")
check(config.Audio.Cues.select.hold+config.Audio.Cues.select.fade>=.5,"selection leaves an audible tail")
check(config.Audio.Cues.back.speed<config.Audio.Cues.confirm.speed,"return and confirm have distinct registers")
a.SetLevels(1,1);before=played;for i=1,40 do a.Play("confirm")end;advance(.04)
active=0;for _,s in ipairs(sounds)do if s.IsPlaying then active+=1 end end
check(active<=config.Audio.Voices.Interface+config.Audio.Voices.UIBody,"rapid UI clicks stay within four voices")
check(#sounds==count+sourceCount,"UI clicks do not allocate new sounds")
a.SetLevels(0,1);before=played;advance(2);check(played==before,"mute cancels pending UI layers")
return game:GetService("HttpService"):JSONEncode({passed=checks,voices=count,scope="Mock scheduling and sound lifecycle, not auditory acceptance"})
