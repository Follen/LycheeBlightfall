local count=0
local function eq(a,b,label) assert(a==b,label); count=count+1 end
local function session(class,spec,hero,known)
    local env,frames,queue={},{},{}
    local loads,states=0,{}
    env._G=env
    setmetatable(env,{__index=_G})
    env.UnitClass=function() return class,class end
    env.C_SpecializationInfo={GetSpecialization=function() return 1 end,GetSpecializationInfo=function() return spec end}
    env.C_ClassTalents={GetActiveHeroTalentSpec=function() return hero end}
    env.C_SpellBook={IsSpellKnown=function(id) eq(id,1271974,"check talent not cast"); return known end}
    env.CreateFrame=function()
        local f={}
        function f:RegisterEvent() end
        function f:SetScript(_,fn) self.event=fn end
        frames[#frames+1]=f
        return f
    end
    env.C_Timer={After=function(_,fn) queue[#queue+1]=fn end}
    env.C_AddOns={LoadAddOn=function(name)
        eq(name,"LycheeBlightfall_Core","load correct core")
        loads=loads+1
        env.LycheeBlightfall.SetEligible=function(v) states[#states+1]=v end
        return true
    end}
    setfenv(assert(loadfile("addon/LycheeBlightfall/Loader.lua")),env)()
    if frames[1] then
        frames[1].event(); frames[1].event()
        eq(#queue,1,"coalesce repeated eligibility events")
        queue[1]()
    end
    return loads,#frames,states,env,function()
        frames[1].event()
        queue[#queue]()
    end
end
local loads,frames=session("MAGE",252,31,true)
eq(loads,0,"nonDK no core"); eq(frames,0,"nonDK no event frame")
loads=session("DEATHKNIGHT",251,31,true); eq(loads,0,"frost no core")
loads=session("DEATHKNIGHT",252,32,true); eq(loads,0,"other hero no core")
loads=session("DEATHKNIGHT",252,31,false); eq(loads,0,"no Blightfall no core")
local states,env,refresh
loads,frames,states,env,refresh=session("DEATHKNIGHT",252,31,true)
eq(loads,1,"eligible loads once"); eq(states[1],true,"eligible activates")
env.C_ClassTalents.GetActiveHeroTalentSpec=function() return 32 end
refresh()
eq(states[2],false,"hero change deactivates")
print("Loader assertions passed: "..count)
