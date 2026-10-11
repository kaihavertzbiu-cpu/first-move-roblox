-- Canonical HUD: your side is A on either client. Start from the existing private-safe
-- projection, then swap labels; never project by cloning the authoritative state.
local Rules=require(script.Parent.MatchRules)
local Projection={}
local function swap(value)
    if type(value)~="table" then if value=="A" then return "B" elseif value=="B" then return "A" end;return value end
    local out={};for key,item in pairs(value) do local k=key=="A" and "B" or key=="B" and "A" or key;out[k]=swap(item) end;return out
end
function Projection.view(state,owner)
    local view=Rules.view(state,owner)
    return owner=="B" and swap(view) or view
end
return Projection
