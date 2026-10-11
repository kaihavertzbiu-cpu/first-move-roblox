-- Curated locale coverage, reversible binding and profile persistence in an isolated clone.
local qa=Instance.new("Folder");qa.Name="LocalizationQA";qa.Parent=game.ServerStorage
local modules=game.StarterPlayer.StarterPlayerScripts.DeadlockClient:Clone();modules.Parent=qa
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local ok,result=pcall(function()
    local Locale=require(modules.LocaleController);Locale.Set("en-us")
    local catalog=require(modules.EnglishCatalog);local count=0
    for source,translated in pairs(catalog)do
        count+=1;check(type(translated)=="string"and#translated>0,"Nonempty translation "..source)
        check(source=="简体中文"or not translated:find("[\228-\233][\128-\191][\128-\191]"),"English catalog contains no Chinese "..source)
    end
    for _,folder in ipairs({modules,game.ReplicatedStorage.DeadlockShared,game.ServerScriptService.DeadlockServer})do
        for _,module in ipairs(folder:GetChildren())do if module:IsA("LuaSourceContainer")and module.Name~="EnglishCatalog"then
            for literal in module.Source:gmatch('"([^"\n]-)"')do
                local parse=loadstring('return "'..literal..'"');local valid,value=pcall(parse or function()error("Not a full literal")end)
                if valid then literal=value end
                if valid and literal:find("[\228-\233][\128-\191][\128-\191]")and literal~="复"and literal~="简体中文"and not literal:find("<font",1,true)then
                    local translated=Locale.translate(literal)
                    check(not translated:find("[\228-\233][\128-\191][\128-\191]"),"Missing literal in "..module.Name..": "..literal)
                end
            end
        end end
    end
    local frame=Instance.new("Frame");frame.Parent=qa
    local label=Instance.new("TextLabel");label.Text="复苏";label.Parent=frame;Locale.bind(label)
    check(label.Text=="Mender"and label:GetAttribute("LocaleSource")=="复苏","Binding preserves source")
    for i=1,20 do Locale.Set("zh-cn");check(label.Text=="复苏","Chinese restored");Locale.Set("en-us");check(label.Text=="Mender","English restored")end
    label.Text="双轨";check(label.Text=="Twinrail","Live text update translated")
    Locale.Set("zh-cn");check(label.Text=="双轨","New source restored")
    label.Text="复苏同学 · 指挥官";label:SetAttribute("ProtectedText","复苏同学");Locale.Set("en-us")
    check(label.Text:find("复苏同学",1,true)and not label.Text:find("Mender",1,true),"Player name is preserved")
    label:SetAttribute("LocaleIgnore",true);check(label.Text=="复苏同学 · 指挥官","User labels can opt out")
    label:Destroy();Locale.Set("zh-cn");Locale.Set("en-us")
    check(not Locale.Set("de-de"),"Unsupported setting rejected")
    local Story=require(modules.ReportStory)
    check(Story.event({kind="Block",target="lan_dun",source="ting_sun"})=="Warden blocked Reaper's attack","Block log grammar")
    check(Story.event({kind="Death",target="bai_ji"})=="Mender was eliminated","Death log grammar")
    check(Story.event({kind="Skill",source="bai_ji"})=="Mender used Repair Pulse","Ability log grammar")
    check(Story.event({kind="ActionStart",owner="A"})=="Your action began","Action log grammar")
    local story=Story.build({winner="A",round=3,rosters={},events={{kind="Damage",source="beng_yue",target="bai_ji",damageType="Normal",effective=8,round=3},{kind="Death",target="bai_ji",round=3}}})
    check(story.closing.summary=="Maul's attack eliminated Mender","Final cause is factual in English")
    local schemaClone=game.ServerScriptService.DeadlockServer.ProfileSchema:Clone();schemaClone.Parent=qa;local Schema=require(schemaClone)
    for _,language in ipairs({"auto","zh-cn","en-us"})do
        local p=Schema.apply(Schema.new(),{kind="Settings",settings={language=language}})
        check(p.settings.language==language and Schema.normalize(p).settings.language==language,"Language persists "..language)
    end
    check(Schema.settings({language="invalid"},true)==nil,"Server rejects invalid language")
    check(Schema.normalize({schemaVersion=2,settings={large=true}}).settings.language=="auto","Old profiles default to automatic")
    return {passed=checks,catalogEntries=count,scope="Offline literal coverage, reversible UI binding, factual event grammar, server settings validation"}
end)
qa:Destroy();if not ok then error(result)end
return game:GetService("HttpService"):JSONEncode(result)
