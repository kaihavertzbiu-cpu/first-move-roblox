-- Bounded polyphony preserves contact transients and independent impact tails.
local SoundService=game:GetService("SoundService")
local TweenService=game:GetService("TweenService")
local ContentProvider=game:GetService("ContentProvider")
local Config=require(script.Parent.PresentationConfig).Audio
local Music=require(script.Parent.MusicController)
local Audio={Master=.65,SFX=.7,Counts={},Loaded={},LastSources={}}
local voices={};local sequence=0;local levelSequence=0;local hoverTime=0;local clock=0
for name,count in pairs(Config.Voices) do
    voices[name]={}
    for i=1,count do
        local sound=Instance.new("Sound");sound.Name="FirstMove"..name..i;sound.Parent=SoundService
        local eq=Instance.new("EqualizerSoundEffect")
        local isInterface=name=="Hover" or name=="Interface" or name=="UIBody"
        local bands=isInterface and Config.InterfaceEQ or Config.EQ
        eq.LowGain=bands.Low;eq.MidGain=bands.Mid;eq.HighGain=bands.High;eq.Parent=sound
        if isInterface then
            local room=Instance.new("ReverbSoundEffect");room.Name="DarkInterfaceRoom"
            room.DecayTime=Config.InterfaceRoom.Decay;room.Density=Config.InterfaceRoom.Density
            room.Diffusion=Config.InterfaceRoom.Diffusion;room.DryLevel=0;room.WetLevel=Config.InterfaceRoom.Wet;room.Parent=sound
        end
        table.insert(voices[name],{sound=sound,serial=0,started=0})
    end
end
-- A failed request cannot hold up unrelated asset readiness.
for key,source in pairs(Config.Sources) do
    local sound=Instance.new("Sound");sound.Name="FirstMovePreload_"..key;sound.SoundId=source.id
    sound.Volume=0;sound.Parent=SoundService
    sound.Loaded:Connect(function() Audio.Loaded[key]=true end)
    task.spawn(function()
        pcall(function() ContentProvider:PreloadAsync({sound}) end)
        Audio.Loaded[key]=sound.IsLoaded
    end)
end
local function stop(voice)
    voice.serial+=1;if voice.fade then voice.fade:Cancel();voice.fade=nil end
    voice.sound:Stop();voice.sound.Volume=0
end
local function playLayer(cue,pitch,kind)
    local pool=voices[cue.channel];local voice=pool[1]
    for _,candidate in ipairs(pool) do
        if not candidate.sound.IsPlaying then voice=candidate;break end
        if candidate.started<voice.started then voice=candidate end
    end
    stop(voice);local serial=voice.serial;clock+=1;voice.started=clock
    local source=Config.Sources[cue.asset]
    -- Stream the intended source; never substitute a UI slider for a combat hit.
    local asset=source and source.id or "rbxasset://sounds/"..cue.asset
    Audio.LastSources[kind]=asset
    local sound=voice.sound;sound.SoundId=asset;voice.gain=cue.gain
    sound.PlaybackSpeed=pitch or cue.speed;sound.Volume=cue.gain*Audio.Master*Audio.SFX
    sound.TimePosition=cue.offset or 0;sound:Play()
    task.delay(cue.hold,function()
        if voice.serial~=serial then return end
        voice.fade=TweenService:Create(sound,TweenInfo.new(cue.fade),{Volume=0});voice.fade:Play()
        task.delay(cue.fade,function() if voice.serial==serial then stop(voice) end end)
    end)
end
function Audio.Play(kind,pitch)
    local cue=Config.Cues[kind];if not cue or cue.gain<=0 or Audio.Master*Audio.SFX==0 then return end
    if kind=="hover" then
        local now=os.clock();if now-hoverTime<Config.HoverGap then return end;hoverTime=now
    end
    if cue.channel~="Hover" and cue.channel~="Interface" and cue.channel~="UIBody" then Music.Duck(cue.hold+cue.fade) end
    Audio.LastCue=kind;Audio.Counts[kind]=(Audio.Counts[kind] or 0)+1
    playLayer(cue,pitch,kind)
    local ticket=sequence
    local levelTicket=levelSequence
    for _,layer in ipairs(Config.Layers[kind] or {}) do
        task.delay(layer.delay or 0,function()
            local valid=layer.channel=="UIBody"and levelTicket==levelSequence or layer.channel~="UIBody"and ticket==sequence
            if valid and Audio.Master*Audio.SFX>0 then playLayer(layer,nil,kind..":body") end
        end)
    end
end
function Audio.SetLevels(master,sfx)
    Audio.Master=math.clamp(master,0,1);Audio.SFX=math.clamp(sfx,0,1)
    sequence+=1
    levelSequence+=1
    -- Cancel old envelopes, including scheduled layers; next cue uses new levels.
    for _,pool in pairs(voices) do for _,voice in ipairs(pool) do stop(voice) end end
end
function Audio.Reset()
    sequence+=1;Music.Release()
    for name,pool in pairs(voices) do if name~="Hover" and name~="Interface" and name~="UIBody" then
        for _,voice in ipairs(pool) do stop(voice) end
    end end
end
function Audio.Outcome(winner)
    Audio.Reset();local ticket=sequence;Audio.Play("terminal")
    task.delay(Config.OutcomeLead,function()
        if sequence~=ticket then return end
        local cue=winner=="A" and "victory" or winner=="B" and "defeat" or "draw"
        Audio.Play(cue)
        if winner=="A" then task.delay(Config.VictorySecond,function() if sequence==ticket then Audio.Play(cue,Config.VictoryPitch) end end) end
    end)
end
return Audio
