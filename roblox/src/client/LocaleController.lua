-- Offline, curated Chinese/English presentation. No network translation dependency.
local Catalog=require(script.Parent.EnglishCatalog)
local Service=game:GetService("LocalizationService")
local Locale={Preference="auto",Changed=Instance.new("BindableEvent"),Missing={}}
local targets=setmetatable({},{__mode="k"})
local entries={};for source,value in pairs(Catalog)do table.insert(entries,{source,value})end
table.sort(entries,function(a,b)return #a[1]>#b[1]end)
local function language()
    if Locale.Preference~="auto"then return Locale.Preference end
    return string.sub(string.lower(Service.RobloxLocaleId),1,2)=="zh"and"zh-cn"or"en-us"
end
function Locale.isEnglish()return language()=="en-us"end
local function clean(value)return value:gsub('<font size="%d+">复</font>',"复")end
function Locale.translate(value,protected)
    if not Locale.isEnglish()or type(value)~="string"then return value end
    value=clean(value)
    if protected and protected~=""then
        local first,last=value:find(protected,1,true)
        if first then return Locale.translate(value:sub(1,first-1))..protected..Locale.translate(value:sub(last+1))end
    end
    if Catalog[value]then return Catalog[value]end
    if not value:find("[\128-\255]")then return value end
    -- A single source pass: replacements never become input to later replacements.
    local result={};local at=1
    while at<=#value do
        local bestPos,bestEntry
        for _,entry in ipairs(entries)do
            local pos=value:find(entry[1],at,true)
            if pos and (not bestPos or pos<bestPos)then bestPos=pos;bestEntry=entry end
        end
        if not bestPos then table.insert(result,value:sub(at));break end
        table.insert(result,value:sub(at,bestPos-1));table.insert(result,bestEntry[2]);at=bestPos+#bestEntry[1]
    end
    local translated=table.concat(result)
    if translated:find("[\228-\233][\128-\191][\128-\191]")then Locale.Missing[clean(value)]=true end
    return translated
end
function Locale.bind(obj)
    if not(obj:IsA("TextLabel")or obj:IsA("TextButton")or obj:IsA("TextBox"))or obj:IsA("TextBox")then return end
    obj.AutoLocalize=false
    local source=clean(obj.Text);local writing=false
    local function render()
        if writing or not obj.Parent then return end
        writing=true
        obj:SetAttribute("LocaleSource",source)
        obj.Text=obj:GetAttribute("LocaleIgnore")and source or Locale.translate(source,obj:GetAttribute("ProtectedText"))
        writing=false
    end
    targets[obj]=render
    obj:GetPropertyChangedSignal("Text"):Connect(function()
        if writing then return end
        source=clean(obj.Text);obj:SetAttribute("LocaleSource",source)
        if Locale.isEnglish()then render()end
    end)
    obj:GetAttributeChangedSignal("ProtectedText"):Connect(render)
    obj:GetAttributeChangedSignal("LocaleIgnore"):Connect(render)
    obj.Destroying:Connect(function()targets[obj]=nil end)
    render()
end
local current=language()
local function refresh()
    local nextLanguage=language();if current==nextLanguage then return end
    current=nextLanguage
    for obj,render in pairs(targets)do if obj.Parent then render()end end
    Locale.Changed:Fire(nextLanguage)
end
function Locale.Set(preference)
    if preference~="auto"and preference~="zh-cn"and preference~="en-us"then return false end
    Locale.Preference=preference;refresh();return true
end
function Locale.label()
    return Locale.Preference=="auto"and"自动"or Locale.Preference=="zh-cn"and"简体中文"or"English"
end
function Locale.cycle()
    return Locale.Preference=="auto"and"zh-cn"or Locale.Preference=="zh-cn"and"en-us"or"auto"
end
Service:GetPropertyChangedSignal("RobloxLocaleId"):Connect(refresh)
return Locale
