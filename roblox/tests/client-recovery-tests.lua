-- Functional controller tests with fake transport, scheduler and GUI objects.
-- Callback coverage is not hardware input or visual acceptance.
local source=game.StarterPlayer.StarterPlayerScripts.DeadlockClient
local Identity=require(source.UnitIdentity)
local Presentation=require(source.PresentationConfig)
local checks={};local delayed={};local sent={};local latestSelection;local route;local closeCount=0
local localBusy=false
local menuActive=false;local inputService={GamepadEnabled=false}
local clock=0
local function check(name,value) assert(value,name);table.insert(checks,name) end
local function object(class,props,parent)
    local o={ClassName=class,Name=class,Font=Enum.Font.Gotham,Visible=true,Selectable=true,AbsoluteSize=Vector2.new(400,600),AbsolutePosition=Vector2.zero,children={},attributes={}}
    for k,v in pairs(props or {}) do o[k]=v end
    o.Parent=parent;if parent then table.insert(parent.children,o) end
    function o:IsA(c) return self.ClassName==c end
    function o:GetChildren() return self.children end
    function o:GetDescendants() local a={};local function walk(p) for _,c in ipairs(p.children) do table.insert(a,c);walk(c) end end;walk(self);return a end
    function o:SetAttribute(k,v) self.attributes[k]=v end
    function o:GetAttribute(k) return self.attributes[k] end
    function o:ClearAllChildren() for _,c in ipairs(self.children) do c.Parent=nil end;self.children={} end
    function o:IsDescendantOf(p) local c=self.Parent;while c do if c==p then return true end;c=c.Parent end;return false end
    function o:Destroy() if self.Parent then for i,c in ipairs(self.Parent.children) do if c==self then table.remove(self.Parent.children,i);break end end end;self.Parent=nil end
    return o
end
local gui=object("ScreenGui");local root=object("Frame",{Name="Router",AbsoluteSize=Vector2.new(390,780),Size=UDim2.fromScale(1,1),Position=UDim2.fromScale(0,0)},gui)
local Kit={make=object,fit=function() end}
function Kit.text(p,value,x,y,w,h,size) return object("TextLabel",{Text=value,TextSize=size,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h)},p) end
function Kit.panel(p,x,y,w,h) return object("CanvasGroup",{Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h)},p) end
function Kit.line(p,x,y,w) return object("Frame",{Position=UDim2.fromScale(x,y),Size=UDim2.new(w,0,0,1)},p) end
function Kit.button(p,label,x,y,w,h,fn) local b=object("TextButton",{Name=label,Position=UDim2.fromScale(x,y),Size=UDim2.fromScale(w,h),callback=fn},p);Kit.text(b,label,0,0,1,1,17);return b end
local function find(id,container) for _,b in ipairs((container or gui):GetDescendants()) do if b:IsA("TextButton") and (b:GetAttribute("ControlId")==id or b.Name==id) then return b end end end
local function click(id) local b=assert(find(id),"Missing control "..id);assert(not b:GetAttribute("Disabled"),"Disabled "..id);b.callback() end
local guiService={};local state={OnClientEvent={Connect=function(self,fn) self.callback=fn end}}
local intent={FireServer=function(_,payload) table.insert(sent,payload) end}
local remotes={State=state,WaitForChild=function(_,name) return name=="Intent" and intent or state end}
local shared={ProductConfig="ProductConfig"}
local replicated={WaitForChild=function(_,name) return name=="DeadlockShared" and shared or remotes end}
local fakeGame={GetService=function(_,name) return ({ReplicatedStorage=replicated,GuiService=guiService,UserInputService=inputService,TextService=game:GetService("TextService")})[name] end}
local dependencies={[source.UnitIdentity]=Identity,[source.PresentationConfig]=Presentation,ProductConfig={EnglishName="FIRST MOVE"},[source.TableController]={reset=function() end,update=function(_,s) latestSelection=table.clone(s) end},[source.ReportController]={render=function() end},[source.UnitPresentation]={draft=function() end,roster=function() end},[source.TutorialController]={Enabled=false,render=function() end},[source.PresentationDirector]={reset=function() end,update=function() end,resolving=function() return false end},[source.InterfaceKit]=Kit,[source.AudioController]={Play=function() end}}
dependencies[source.CameraController]={Reduced=false}
dependencies[source.PresentationDirector].resolving=function() return localBusy end
local function loadModule(module) return assert(loadstring("local game,script,require,task,os=...\n"..module.Source))(fakeGame,{Parent=source},function(k) return assert(dependencies[k],"Unexpected dependency") end,{delay=function(seconds,fn) table.insert(delayed,{seconds=seconds,fn=fn}) end},{clock=function() return clock end}) end
-- Use shipping typography with fake audio, keeping the Edit DataModel untouched.
Kit.textSize=loadModule(source.InterfaceKit).textSize
local Battle=loadModule(source.BattleController)
local ui={root=root,make=Kit.make,text=Kit.text,button=Kit.button,panel=Kit.panel,line=Kit.line,chrome=function() end,fit=function() end,route=function(v) route=v end,closeMenu=function() closeCount+=1 end,openMenu=function() end,menuActive=function() return menuActive end}
Battle.init(ui);Battle.start()
check("Connecting counts as in progress",Battle.inProgress())
check("Start renders connecting state",root:GetAttribute("Screen")=="Connecting" and sent[#sent].command=="Start")
check("Start timeout uses configured duration",delayed[#delayed].seconds==Presentation.Network.StartTimeout)
delayed[#delayed].fn();check("Slow connection offers retry",find("Reconnect")~=nil)
inputService.GamepadEnabled=true;guiService.SelectedObject=find("Reconnect");Battle.refresh()
check("Connecting resize preserves retry navigation",guiService.SelectedObject==find("Reconnect"))
inputService.GamepadEnabled=false
click("Reconnect");check("Retry requests Start only",sent[#sent].command=="Start")
local function view(phase,revision,actor) return {sessionId="same-session",phase=phase,revision=revision,actor=actor,round=1,coreLocked={A=false,B=false},rosters={A={},B={}},events={}} end
local function named(label) for _,o in ipairs(root:GetDescendants()) do if o.Name==label then return o end end end
Battle.Mode="PvP";Battle.start();local connectTimer=delayed[#delayed]
state.OnClientEvent.callback({queued=true});local queueTimer=delayed[#delayed]
check("Queue begins a readable clock",named("QueueElapsed").Text=="已等待 00:00" and Battle.inProgress())
connectTimer.fn();check("Connecting timeout cannot replace confirmed queue",root:GetAttribute("Screen")=="Waiting")
clock=31;queueTimer.fn()
check("Long queue offers truthful same-server guidance",named("QueueElapsed").Text=="已等待 00:31" and named("QueueGuidance").Text:find("暂时还没有对手",1,true)~=nil)
inputService.GamepadEnabled=true;guiService.SelectedObject=find("Quit")
Battle.refresh();check("Queue refresh preserves elapsed time and selected cancel",named("QueueElapsed").Text=="已等待 00:31" and guiService.SelectedObject==find("Quit"))
local beforeTimer=#delayed;queueTimer.fn();check("Replaced timer cannot spawn another loop",#delayed==beforeTimer)
state.OnClientEvent.callback({queued=true});check("Repeated queue acknowledgement does not restart time",named("QueueElapsed").Text=="已等待 00:31")
local cancelButton=find("Quit");local practiceButton=find("QueuePractice");local lastTick=delayed[#delayed];local countBeforeSwitch=#sent
click("QueuePractice")
check("Practice switch is one atomic Start without Quit",#sent==countBeforeSwitch+1 and sent[#sent].command=="Start" and sent[#sent].mode=="AI" and sent[#sent].difficulty=="Standard")
check("Practice switch shows connection and supports retry",root:GetAttribute("Screen")=="Connecting" and Battle.Mode=="AI")
local afterSwitch=#sent;practiceButton.callback();cancelButton.callback();lastTick.fn()
check("Stale queue buttons and timer cannot affect switched session",#sent==afterSwitch and root:GetAttribute("Screen")=="Connecting")
delayed[#delayed].fn();click("Reconnect");check("Slow practice switch retries AI",sent[#sent].mode=="AI" and sent[#sent].command=="Start")
local paired=view("Draft",0,"A");paired.mode="PvP"
state.OnClientEvent.callback({view=paired,started=true})
check("Pairing race respects returned live PvP",root:GetAttribute("Screen")=="Battle" and Battle.active())
Battle.quit();clock=70;Battle.Mode="PvP";Battle.start();state.OnClientEvent.callback({queued=true})
check("New queue starts its own timer",named("QueueElapsed").Text=="已等待 00:00")
local quitTick=delayed[#delayed];click("Quit");local afterQuit=#delayed;quitTick.fn()
check("Queue cancel stops timer and clears local session",not Battle.active() and route=="Menu" and #delayed==afterQuit and sent[#sent].sessionId==nil)
inputService.GamepadEnabled=false;Battle.Mode="AI";Battle.start()
local v=view("CoreSelection",10,nil);state.OnClientEvent.callback({view=v,started=true})
click("ActionDrawer");check("Compact drawer opens details",find("Core:cyan").Parent.Visible==true)
click("Core:cyan");check("Core preselection recorded",latestSelection.core=="cyan")
local newer=view("CoreSelection",11,nil);newer.coreLocked.B=true
state.OnClientEvent.callback({view=newer})
check("Opponent core update preserves preselection",latestSelection.core=="cyan")
Battle.refresh();check("Refresh preserves selection",latestSelection.core=="cyan")
click("PrimaryAction");check("Core action submits selected value",sent[#sent].intent.core=="cyan" and sent[#sent].intent.revision==11)
check("Action timeout uses configured duration",delayed[#delayed].seconds==Presentation.Network.ActionTimeout)
delayed[#delayed].fn();check("Slow action offers Sync",find("SyncState")~=nil)
click("SyncState");check("Recovery sends Sync without action",sent[#sent].command=="Sync" and sent[#sent].intent==nil)
state.OnClientEvent.callback({view=newer,synced=true});check("Sync preserves secret preselection",latestSelection.core=="cyan" and not find("PrimaryAction"):GetAttribute("Disabled"))
local overlayControl=object("TextButton",{Name="QASettingsFocus"},gui);guiService.SelectedObject=overlayControl;menuActive=true;inputService.GamepadEnabled=true
state.OnClientEvent.callback({view=view("CoreSelection",12,nil)})
check("Live state does not steal modal gamepad focus",guiService.SelectedObject==overlayControl)
check("Live state keeps covered battle controls unselectable",not find("PrimaryAction").Selectable and not find("Core:cyan").Selectable)
menuActive=false;overlayControl:Destroy();Battle.refresh()
check("Returning restores battle navigation and preselection",find("PrimaryAction").Selectable and latestSelection.core=="cyan" and guiService.SelectedObject:IsDescendantOf(root))
inputService.GamepadEnabled=false
localBusy=true;Battle.refresh();local countBefore=#sent
check("Presentation beat disables the next action",find("PrimaryAction"):GetAttribute("Disabled"))
find("PrimaryAction").callback();check("A stale click cannot submit ahead of the beat",#sent==countBefore)
localBusy=false;Battle.refresh();check("Finishing presentation restores the planned action",not find("PrimaryAction"):GetAttribute("Disabled") and latestSelection.core=="cyan")
local draft=view("Draft",20,"A");state.OnClientEvent.callback({view=draft,started=true})
click(Identity.heroes[1].name.."\n"..Identity.heroes[1].atk.." ATK · "..Identity.heroes[1].maxHp.." HP")
check("Draft selection opens compact details",latestSelection.hero==Identity.heroes[1].id and find("PrimaryAction").Parent.ZIndex==10)
local accepted=view("Draft",21,"A");accepted.rosters.A={{id=Identity.heroes[1].id}}
state.OnClientEvent.callback({view=accepted,synced=true})
check("Sync clears stale accepted same-actor draft",latestSelection.hero==nil and find("PrimaryAction"):GetAttribute("Disabled"))
local staleTimer=delayed[#delayed];state.OnClientEvent.callback({view=accepted,ack=true});staleTimer.fn()
check("Ack cancels stale timeout callback",find("SyncState")==nil)
click("GuidePanel");check("Compact guide opens",find("GuideToggle").Parent.Visible)
click("GuideToggle");check("Compact guide closes",not find("GuideToggle").Parent.Visible)
local terminal=view("GameOver",22,nil);terminal.winner="A";state.OnClientEvent.callback({view=terminal})
check("Completed report is not an unfinished match",Battle.active() and not Battle.inProgress())
check("Terminal dismisses session overlay",closeCount==1)
Battle.quit();check("Quit cancels local session",not Battle.active() and route=="Menu" and sent[#sent].command=="Quit")
Battle.start();Battle.quit();check("Connecting cancel works without GUID",sent[#sent].command=="Quit" and sent[#sent].sessionId==nil)
local Preferences=loadModule(source.PreferencesView);dependencies[source.PreferencesView]=Preferences
local Menu=loadModule(source.SessionMenu)
local prefs={master=.65,sfx=.7,music=.35,reduced=false,large=false,guide=true};local resumes,quits=0,0
local function context() return {root=root,getPreferences=function() return table.clone(prefs) end,changePreference=function(k,v) prefs[k]=v end,scale=function() return prefs.large and 1.12 or 1 end,resume=function() resumes+=1 end,quit=function() quits+=1 end} end
local returnAnchor=Kit.button(root,"QAResumeAnchor",0,0,1,1,function() end);returnAnchor:SetAttribute("ControlId","QAResumeAnchor");guiService.SelectedObject=returnAnchor
Menu.open(context());check("Session overlay opens above live Router",Menu.active() and find("SessionResume").Parent.Parent.Parent==gui)
check("Opening modal removes covered controls from navigation",not returnAnchor.Selectable)
local focusedVolume=find("Preference:master:Down");guiService.SelectedObject=focusedVolume
click("Preference:master:Down");check("Volume down changes ten percentage points",math.abs(prefs.master-.55)<.00001)
check("Adjusting volume retains the selected control",guiService.SelectedObject==focusedVolume and focusedVolume.Parent~=nil and find("Preference:master:Down")==focusedVolume)
for _=1,8 do click("Preference:master:Down") end;check("Volume clamps to mute",prefs.master==0)
for _=1,12 do click("Preference:master:Up") end;check("Volume clamps to maximum",prefs.master==1)
click("Preference:sfx:Down");check("SFX preference independent",prefs.sfx==.6 and prefs.master==1)
click("Preference:music:Down");check("Music preference independent",prefs.music==.25 and prefs.sfx==.6 and prefs.master==1)
for _,key in ipairs({"reduced","large","guide"}) do local old=prefs[key];click("Preference:"..key);check("Toggle "..key,prefs[key]==not old) end
click("SessionQuit");check("Exit requires explicit confirmation",Menu.active() and quits==0 and find("SessionConfirmQuit")~=nil)
click("SessionResume");check("Cancel confirmation resumes",not Menu.active() and resumes==1 and quits==0)
check("Closing modal restores the original navigation focus",returnAnchor.Selectable and guiService.SelectedObject==returnAnchor)
Menu.open(context());click("SessionQuit");click("SessionConfirmQuit");check("Confirmed exit invokes quit once",not Menu.active() and quits==1)
Menu.open(context());Menu.close(false);check("Route cleanup does not resume battle",not Menu.active() and resumes==1)
return game:GetService("HttpService"):JSONEncode({scope="shipping controller callbacks with fake GUI/transport; no hardware or visual acceptance",passed=#checks,checks=checks})
