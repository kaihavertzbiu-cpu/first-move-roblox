const fs=require('fs'),path=require('path');
const root=__dirname;
const product=JSON.parse(fs.readFileSync(path.join(root,'product.json'),'utf8'));
let seq=0;
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const prop=(type,name,value)=>`<${type} name="${name}">${value}</${type}>`;
const str=(n,v)=>prop('string',n,esc(v));
const num=(n,v)=>prop('float',n,v);
const bool=(n,v)=>prop('bool',n,v?'true':'false');
const token=(n,v)=>prop('token',n,v);
const vec=(n,v)=>prop('Vector3',n,`<X>${v[0]}</X><Y>${v[1]}</Y><Z>${v[2]}</Z>`);
const col=(n,v)=>prop('Color3',n,`<R>${v[0]/255}</R><G>${v[1]/255}</G><B>${v[2]/255}</B>`);
function cf(p,r=[1,0,0,0,1,0,0,0,1]){return prop('CoordinateFrame','CFrame',`<X>${p[0]}</X><Y>${p[1]}</Y><Z>${p[2]}</Z>`+r.map((v,i)=>`<R${Math.floor(i/3)}${i%3}>${v}</R${Math.floor(i/3)}${i%3}>`).join(''));}
function item(c,n,p='',children=''){return `<Item class="${c}" referent="RBX${++seq}"><Properties>${str('Name',n)}${p}</Properties>${children}</Item>`;}
const graphite=[35,45,52],steel=[62,75,82],dark=[22,30,36],cyan=[88,184,190],paper=[203,205,190],amber=[210,166,96];
let parts=0;
function part(n,size,pos,color=graphite,material=1088,extra='',children='',rotation){parts++;return item('Part',n,vec('size',size)+cf(pos,rotation)+col('Color',color)+token('Material',material)+bool('Anchored',true)+bool('CanCollide',true)+token('TopSurface',0)+token('BottomSurface',0)+extra,children);}
function beam(n,a,b,width,color,mat=288){let d=b.map((v,i)=>v-a[i]),len=Math.hypot(...d),z=d.map(v=>v/len),up=Math.abs(z[1])>.99?[1,0,0]:[0,1,0];let x=[up[1]*z[2]-up[2]*z[1],up[2]*z[0]-up[0]*z[2],up[0]*z[1]-up[1]*z[0]];let l=Math.hypot(...x);x=x.map(v=>v/l);let y=[z[1]*x[2]-z[2]*x[1],z[2]*x[0]-z[0]*x[2],z[0]*x[1]-z[1]*x[0]];return part(n,[width,width,len],a.map((v,i)=>(v+b[i])/2),color,mat,bool('CanCollide',false),'',[x[0],y[0],z[0],x[1],y[1],z[1],x[2],y[2],z[2]]);}
function ring(n,r,y,color,width=.05,segments=64,center=[0,0]){let s='';for(let i=0;i<segments;i++){let a=i*2*Math.PI/segments,b=(i+1)*2*Math.PI/segments;s+=beam(n,[center[0]+r*Math.cos(a),y,center[1]+r*Math.sin(a)],[center[0]+r*Math.cos(b),y,center[1]+r*Math.sin(b)],width,color);}return s;}
function surfaceLabel(label,sub){return item('SurfaceGui','Identity',token('Face',2)+prop('Vector2','CanvasSize','<X>1000</X><Y>320</Y>')+num('LightInfluence',0.1),item('TextLabel','Label',prop('UDim2','Size','<XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO>')+num('BackgroundTransparency',1)+str('Text',label+'\n'+sub)+col('TextColor3',paper)+num('TextSize',68)+token('Font',18)));}
const room=require('./scene.cjs')({part,beam,ring,item,num,col,bool,token});
const source=(file,cls,name)=>item(cls,name,prop('ProtectedString','Source',esc(fs.readFileSync(path.join(root,'src',file),'utf8'))));
const clientFiles=[['client/UnitPortrait.lua','ModuleScript','UnitPortrait'],['client/InterfaceKit.lua','ModuleScript','InterfaceKit'],['client/ReportStory.lua','ModuleScript','ReportStory'],['client/AudioSources.lua','ModuleScript','AudioSources'],['client/UnitIdentity.lua','ModuleScript','UnitIdentity'],['client/PresentationDirector.lua','ModuleScript','PresentationDirector'],['client/PresentationConfig.lua','ModuleScript','PresentationConfig'],['client/AudioController.lua','ModuleScript','AudioController'],['client/CameraController.lua','ModuleScript','CameraController'],['client/TableController.lua','ModuleScript','TableController'],['client/UnitPresentation.lua','ModuleScript','UnitPresentation'],['client/TutorialController.lua','ModuleScript','TutorialController'],['client/ReportController.lua','ModuleScript','ReportController'],['client/BattleController.lua','ModuleScript','BattleController'],['client/Bootstrap.client.lua','LocalScript','Bootstrap']];
let xml='<roblox version="4"><External>null</External><External>nil</External>';
xml+=item('Workspace','Workspace','',item('Model','DeadlockWorld','',item('Model','CommandRoom','',room)));
xml+=item('Lighting','Lighting',token('Technology',4)+num('Brightness',1.9)+num('ClockTime',0)+col('Ambient',[44,55,66])+col('OutdoorAmbient',[55,65,74])+num('EnvironmentDiffuseScale',.7)+num('EnvironmentSpecularScale',.9)+bool('GlobalShadows',true),'');
// Explicit modern chat avoids the legacy PlayerGui overlay intercepting roster input.
xml+=item('TextChatService','TextChatService',token('ChatVersion',1),'');
const productLua=`return {Name="${product.name}", EnglishName="${product.englishName}", Tagline="${product.tagline}"}`;
clientFiles.push(['client/ProfileController.lua','ModuleScript','ProfileController']);
clientFiles.push(['client/PreferencesView.lua','ModuleScript','PreferencesView'],['client/SessionMenu.lua','ModuleScript','SessionMenu']);
clientFiles.push(['client/ResponsiveLayout.lua','ModuleScript','ResponsiveLayout']);
clientFiles.push(['client/ResolutionEffects.lua','ModuleScript','ResolutionEffects'],['client/MusicSources.lua','ModuleScript','MusicSources'],['client/MusicController.lua','ModuleScript','MusicController']);
clientFiles.push(['client/ImpactPresentation.lua','ModuleScript','ImpactPresentation']);
clientFiles.push(['client/PortraitAssets.lua','ModuleScript','PortraitAssets']);
clientFiles.push(['client/RankAssets.lua','ModuleScript','RankAssets'],['client/HubView.lua','ModuleScript','HubView']);
clientFiles.push(['client/EnglishCatalog.lua','ModuleScript','EnglishCatalog'],['client/LocaleController.lua','ModuleScript','LocaleController']);
xml+=item('ReplicatedStorage','ReplicatedStorage','',item('Folder','DeadlockShared','',source('shared/LegacyConfig.lua','ModuleScript','LegacyConfig')+source('shared/AIConfig.lua','ModuleScript','AIConfig')+source('shared/ProgressionConfig.lua','ModuleScript','ProgressionConfig')+item('ModuleScript','ProductConfig',prop('ProtectedString','Source',esc(productLua)))));
const serverFiles=[['OpeningRules.lua','ModuleScript','OpeningRules'],['OpeningTests.lua','ModuleScript','OpeningTests'],['CombatRules.lua','ModuleScript','CombatRules'],['BattleReport.lua','ModuleScript','BattleReport'],['BattleReportTests.lua','ModuleScript','BattleReportTests'],['MatchRules.lua','ModuleScript','MatchRules'],['StandardAI.lua','ModuleScript','StandardAI'],['CombatTests.lua','ModuleScript','CombatTests'],['MatchService.lua','ModuleScript','MatchService'],['Bootstrap.server.lua','Script','Bootstrap']];
serverFiles.push(['ProfileSchema.lua','ModuleScript','ProfileSchema'],['DataService.lua','ModuleScript','DataService'],['AIDirector.lua','ModuleScript','AIDirector'],['PlayerProjection.lua','ModuleScript','PlayerProjection']);
serverFiles.push(['TrainingMatch.lua','ModuleScript','TrainingMatch']);
xml+=item('ServerScriptService','ServerScriptService','',item('Folder','DeadlockServer','',serverFiles.map(([file,cls,name])=>source('server/'+file,cls,name)).join('')));
xml+=item('StarterPlayer','StarterPlayer','',item('StarterPlayerScripts','StarterPlayerScripts','',item('Folder','DeadlockClient','',clientFiles.map(x=>source(...x)).join(''))));
xml+=item('StarterGui','StarterGui')+item('SoundService','SoundService')+item('ServerStorage','ServerStorage','',item('Folder','DeadlockAssets'))+'</roblox>';
const dest=path.join(root,'DEADLOCK_PROTOCOL.rbxlx');
if(fs.existsSync(dest)){const b=path.join(root,'../.build/backups');fs.mkdirSync(b,{recursive:true});fs.copyFileSync(dest,path.join(b,'DEADLOCK_PROTOCOL-'+Date.now()+'.rbxlx'));}
fs.writeFileSync(dest,xml);
fs.writeFileSync(path.join(root,'../generated/BUILD_MANIFEST.json'),JSON.stringify({parts,instances:seq,sourceCommit:'242dd1b2a58a9ff7e5f0ab057b5023f328ac9f3d',externalModels:[],externalAssetIds:['AudioSources.lua','MusicSources.lua','PortraitAssets.lua','RankAssets.lua'].flatMap(file=>[...fs.readFileSync(path.join(root,'src/client',file),'utf8').matchAll(/rbxassetid:\/\/(\d+)/g)].map(m=>Number(m[1]))),milestone:'First edition polish: AI, same-server PvP, profiles, public-event VFX and adaptive music; full product and published QA pending',matchAvailable:true},null,2));
console.log(JSON.stringify({file:dest,parts,instances:seq,bytes:Buffer.byteLength(xml)}));
