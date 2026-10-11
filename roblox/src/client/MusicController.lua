-- Three public-state music beds, crossfaded rather than mismatched stems layered.
local SoundService=game:GetService("SoundService")
local ContentProvider=game:GetService("ContentProvider")
local RunService=game:GetService("RunService")
local Config=require(script.Parent.PresentationConfig).Music
local Music={Master=.65,Level=Config.DefaultLevel,State="Deployment",Status="Loading",Loaded={}}
local folder=Instance.new("Folder");folder.Name="FirstMoveMusic";folder.Parent=SoundService
local voices={};local duckUntil=0;local gain=1;local sessionId;local endgame=false
local order={"Deployment","Battle","Endgame"}
function Music.stateFor(view,latched)
    if view.mode=="Training" or view.phase=="Draft" or view.phase=="LinkSetup" then return "Deployment",false end
    if view.phase=="GameOver" then return nil,latched end
    local counts={A=0,B=0}
    for side,list in pairs(view.rosters) do for _,h in ipairs(list) do if h.alive then counts[side]+=1 end end end
    local critical=latched or math.min(counts.A,counts.B)<=Config.EndgameSide or counts.A+counts.B<=Config.EndgameTotal
    return critical and "Endgame" or "Battle",critical
end
local function chosen()
    if Music.Loaded[Music.State] then return Music.State end
    for _,key in ipairs(order) do if Music.Loaded[key] then return key end end
end
local function target(key)
    return chosen()==key and Config.Gains[key]*Music.Master*Music.Level*gain or 0
end
function Music.SetLevels(master,level)
    Music.Master=math.clamp(master,0,1);Music.Level=math.clamp(level,0,1)
    if Music.Master*Music.Level==0 then for _,v in pairs(voices) do v.sound.Volume=0;v.sound:Stop() end end
end
function Music.SetScreen(screen)
    if screen=="Battle" or screen=="Training" then return end
    Music.State="Deployment";gain=(screen=="HistoryReport" or screen=="Record") and Config.ResultGain or 1
    sessionId=nil;endgame=false;duckUntil=0
end
function Music.Update(view)
    if sessionId~=view.sessionId then sessionId=view.sessionId;endgame=false end
    local nextState;nextState,endgame=Music.stateFor(view,endgame)
    if nextState then Music.State=nextState;gain=view.mode=="Training" and Config.TrainingGain or 1 end
end
function Music.Result()
    Music.State="Deployment";gain=Config.ResultGain
end
function Music.Duck(hold)
    duckUntil=math.max(duckUntil,os.clock()+hold)
end
function Music.Release() duckUntil=0 end
for _,key in ipairs(order) do
    local sound=Instance.new("Sound");sound.Name=key;sound.SoundId=Config.Sources[key].id
    sound.Volume=0;sound.Looped=true;sound.Parent=folder
    local eq=Instance.new("EqualizerSoundEffect");eq.LowGain=Config.EQ.Low;eq.MidGain=Config.EQ.Mid;eq.HighGain=Config.EQ.High;eq.Parent=sound
    voices[key]={sound=sound}
    sound.Loaded:Connect(function() Music.Loaded[key]=true;Music.Status="Ready" end)
end
task.spawn(function()
    local list={};for _,key in ipairs(order) do table.insert(list,voices[key].sound) end
    pcall(function() ContentProvider:PreloadAsync(list) end)
    for key,v in pairs(voices) do Music.Loaded[key]=v.sound.IsLoaded end
    Music.Status=chosen() and "Ready" or "Unavailable"
end)
RunService.Heartbeat:Connect(function(dt)
    if not folder.Parent then return end
    local ducked=os.clock()<duckUntil
    for key,v in pairs(voices) do
        local desired=target(key)*(ducked and Config.DuckGain or 1)
        v.target=desired
        if desired>0 and not v.sound.IsPlaying then v.sound:Play() end
        local seconds=ducked and Config.DuckAttack or desired>v.sound.Volume and Config.DuckRelease or Config.Crossfade
        v.sound.Volume+=(desired-v.sound.Volume)*(1-math.exp(-dt/seconds))
        if desired==0 and v.sound.Volume<Config.StopThreshold then v.sound.Volume=0;if v.sound.IsPlaying then v.sound:Stop() end end
    end
end)
return Music
