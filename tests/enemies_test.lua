local ns, units, plates, count = {}, {}, {}, 0
local secret = {}
function issecretvalue(value) return rawequal(value,secret) end
function UnitIsPlayer(unit) return units[unit].player end
function UnitCanAttack(_,unit) return units[unit].attackable end
function UnitIsDeadOrGhost(unit) return units[unit].dead end
function UnitAffectingCombat(unit) return units[unit].combat end
C_NamePlate = {GetNamePlates=function() return plates end}
local function eq(a,b,label) assert(a==b,label..": "..tostring(a)); count=count+1 end
local function mob(unit, overrides)
    units[unit]={player=false,attackable=true,dead=false,combat=true}
    for k,v in pairs(overrides or {}) do units[unit][k]=v end
end
assert(loadfile("addon/LycheeBlightfall_Core/Enemies.lua"))("Test",ns)
local e=ns.Enemies.New()
for i=1,3 do mob("nameplate"..i); e:Add("nameplate"..i) end
eq(e.count,3,"count engaged")
eq(e:IsAOE(),true,"3 is AOE")
e:Add("nameplate3")
eq(e.count,3,"duplicate add is idempotent")
e:Remove("nameplate3")
e:Remove("nameplate3")
eq(e.count,2,"duplicate remove is idempotent")
eq(e:IsAOE(),false,"2 uses single")
mob("nameplate4",{combat=false}); e:Add("nameplate4")
eq(e.count,2,"unpulled enemy excluded")
units.nameplate4.combat=true; e:Update("nameplate4")
eq(e.count,3,"already visible mob enters combat")
units.nameplate4.dead=true; e:Refresh()
eq(e.count,2,"dead mob excluded")
mob("nameplate5",{attackable=false}); e:Add("nameplate5")
mob("nameplate6",{player=true}); e:Add("nameplate6")
eq(e.count,2,"friendly and player excluded")
mob("nameplate7",{combat=secret}); e:Add("nameplate7")
eq(e.count,2,"secret combat not counted")
eq(e.unknown,1,"secret combat explicitly unknown")
e:Add(secret); e:Remove(secret); e:Update(secret)
eq(e.count,2,"secret unit is never indexed")
units.nameplate7.combat=true; e:Update("nameplate7")
eq(e.count,3,"public data recovers")
eq(e.unknown,0,"unknown status clears")
for _,field in ipairs({"attackable","dead","player"}) do
    mob("nameplate7",{[field]=secret}); e:Update("nameplate7")
    eq(e.unknown,1,"secret "..field.." handled")
    eq(e.count,2,"secret "..field.." not counted")
end
plates={{unitToken="nameplate1"},{namePlateUnitToken="nameplate2"},{unitToken="nameplate1"},secret,{unitToken=secret}}
e:Rebuild()
eq(e.count,2,"initial existing nameplates deduplicated")
plates=secret; e:Rebuild()
eq(e.count,0,"secret list cannot be enumerated")
e:Clear()
eq(next(e.units),nil,"disabled clears units")
print("Enemy counter assertions passed: "..count)
