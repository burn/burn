require "the"

-------------------------------------------------------------
-- ## Misc  Stuff 

int   = math.floor
printf= function (s, ...) return io.write(s:format(...)) end
match = function (s,p)    return string.match(s,p) ~= nil end

-------------------------------------------------------------
-- ## Maths Stuff

-- ### close(m:number, n:number [, e:float])
-- Return true are `m` and `n` are within `e`% of each other
-- (default value for e = 1).
function close(m,n,e) 
  e = e and e or 1
  return math.abs(m-n)/n <= e/100 end

-- ### min(x:number, y:number): number
-- ### max(x:number, y:number): number
function max(a,b) if a > b then return a else return b end
function min(a,b) if a < b then return a else return b end

-- ### rand()
-- Return a random number 0..1. To set the random number seed,
-- use `rseed(n:int)`.
do
  local seed0     = 10013
  local seed      = seed0
  local modulus   = 2147483647
  local multipler = 16807
  function rseed(n) seed = n or seed0 end
  function rand() -- park miller 
    seed = (multipler * seed) % modulus
    return seed / modulus end end

-------------------------------------------------------------
-- ## Table Stuff

-- ### ordered(t:table)
-- Iterator. Returns key,values in key sorted order.
function ordered(t)
  local i,tmp = 0,{}
  for key,_ in pairs(t) do tmp[#tmp+1] = key end
  table.sort(tmp)
  return function () 
    if i < #tmp then 
      i=i+1; return tmp[i], t[tmp[i]] end end end

-- ### sorted(t:table [,f:function]): table
-- Sorts table `t` using `f` (defaults to "`lt`").
function sorted(t, f)
  f = f or function (x,y) return x<y end
  table.sort(t,f)
  return t end

-- ### member(x,t:table)
-- Returns true if x is in x
function member(x,t)
  for _,y in pairs(t) do
    if x== y then return true end end
  return false end

-- ### slice(t:table,i:integer, j:integer): table
-- Return items `i` to `j` of table `t`.
function slice(t, i,j)
  local out={}
  for k=i,j do out[#out+1] = t[k] end
  return out end

-- ### push(x, t:table): x
-- Pushes `x` to the end of table `t`. Returns `x`.  
function push(x,t) 
  t[ #t+1 ] = x; return x end

-- ### join(t:table [,sep:string]): string
-- Converts a table to a string.
function join(t, sep)
  return table.concat(t, sep or ", ") end

-- ### shuffle(t: table): t
-- Elements in `t` are rearranged randomly.
function shuffle( t )
  for i= 1,#t do
    local j = i + math.floor((#t - i) * rand() + 0.5)
    t[i],t[j] = t[j], t[i] end
  return t end

function shuffleOkay()
  local t= {}
  rseed(1)
  for i = 1,9  do t[i] = i end
  for _ = 1,10 do print( join(shuffle(t), "") )  end end

-------------------------------------------------------------
-- ## Environment Stuff
-- ### args(settings:table, ignore: table, updates:table)
-- Reading from `updates` (or, if missing, `arg`),
-- ignoring any flags listed in `ignore`, update `settings`
-- with command-line settings such as `-k a=1 b=2`
-- (which sets `k` to true and `a,b` to 1,2).
function args(settings,ignore, updates)
  updates = updates or arg
  ignore = ignore or {}
  local i = 1
  while updates[i] ~= nil  do
    local flag = updates[i]
    local b4   = #flag
    flag = flag:gsub("^[-]+","")
    if not member(flag,ignore) then
      if settings[flag] == nil then error("unknown flag '" .. flag .. "'")
      else
        if b4 - #flag == 2     then settings[flag] = true
        elseif b4 - #flag == 1 then
          local a1 = updates[i+1]
          local a2 = tonumber(a1)
          settings[flag] = a2 or a1
          i = i + 1 end end end
    i = i + 1 end
  return settings end

-------------------------------------------------------------
-- ## String  Stuff

-- ### scan(s:string): string
-- Convert `s` into a string or number, as appropriate.
function scan(s) return tonumber(s) or s end

-- ### rep(s: string, n: int): string
-- Repeat a string, n times
function rep(s, n) return n > 0 and s .. rep(s, n-1) or "" end

-- ### split(s:string, sep:string [, use:function, prep:function]): list 
-- Return a table of cells generated by spliting `s` on `sep`.
function split(s, sep)
  local t, sep = {}, sep or ","
  local notsep = "([^" ..sep.. "]+)"
  for y in string.gmatch(s, notsep) do t[#t+1] = y end 
  return t end

-- ### sub(s: string, [lo : int], [hi : int]): string
-- Extract substrings. Allow Python style negative indexes
function sub(s,lo,hi) 
  if lo and lo < 0 then
    return sub(s, string.len(s) + lo +1)
  else
    return string.sub(s,lo and lo or 1,hi) end end    

function subOkay()
  assert(sub("timm")     == "timm")
  assert(sub("timm",2)   == "imm")
  assert(sub("timm",2,3) == "im")
  assert(sub("timm",-1)  == "m")
  assert(sub("aa",3,10)  == "")
end

-- ### oo(x : anything)
-- Print anything, including nested things
function oo(data) 
  local seen={}
  local function go(x,       str,sep)  
    if type(x) ~= "table" then return tostring(x) end
    if seen[x]            then return "..." end
    seen[x] = true
    for k,v in ordered(x) do
      str = str .. sep .. k .. ": " .. go(v, "{","")
      sep = ", " end 
    return str .. '}'
  end 
  print(go(data,"{","")) end  

-------------------------------------------------------------
-- ## Meta  Stuff

-- ## roguesOkay()
-- Checked for escaped local. Report number of assertion failures.
function roguesOkay()
  local ignore = {
           jit=true, math=true, package=true, table=true, coroutine=true, 
           bit=true, os=true, io=true, bit32=true, string=true,
           arg=true, debug=true, _VERSION=true, _G=true }
  for k,v in pairs( _G ) do
    if type(v) ~= "function" and not ignore[k] then
       assert(match(k,"^[A-Z]"),"rogue local "..k) end end end

-------------------------------------------------------------
-- ## Unit Test  Stuff

-- ### tests()
-- Run any function ending in "Ok". Report number of failures.
function tests()
  local try,fail=0,0
  local function go(goal)
    for k,f in ordered( _G ) do
      if type(f) == "function" and match(k,goal .. "$") then
        print("-- Testing if " .. k .. "?")
        The = defaults()
        try = try + 1
        local passed,err = pcall(f)
        if not passed then 
          fail = fail + 1
          print("-- E> Failure: " .. err)  end end end end
   for _,v in pairs{"Okay","OkaY","OkAY","OKAY"} do go(v) end
   print("-- Failures: ".. 1-((try-fail)/try) .. "%") end

-- ## main{m:string = f:function}
-- Run function `f` if we are in module `m`.
-- Used  like Python's if \_\_name\_\_ == '\_\_main\_\_'. 
-- e.g. `main{lib=doThis}` will call `doThis()` if
-- the environment variable MAIN equals `lib`.
function main(t) 
  roguesOkay()
  for s,f in pairs(t) do
    if s == os.getenv("MAIN") then return f() end end end

-------------------------------------------------------------
-- ## Object Stuff

-- ### Any:new(o)
-- Create the `any` base object
Any={id=0}
function Any:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  if not self.oid then self.oid=0 end
  self.oid = self.oid+1
  self.__index = self
  o.id = self.oid
  o:ready()
  return o
end

function Any:ready() return self end
function Any:pass(...) return self end

function anyOkay()
  local x,y = Any:new(), Any:new()
  x.sub = y
  y.sub = x
  x.lname="tim"; x.fname="menzies"
  assert(y.id == 1 + x.id) end

-------------------------------------------------------------
-- ## Sampling Stuff

Sample = Any:new{max=The.sample.max, n=0, all}
function Sample:ready() self.all = {} end

-- Sample:inc(x): x
-- Keep at most `max` number of items (selected at random).
function Sample:inc(x)
  self.n = self.n + 1
  local now = #self.all
  if now < self.max then self.all[ self.n ] = x 
  else if rand() < now/self.n then
    self.all[ int( 1+ rand() * now ) ] = x end end
  return x end

function sampleOkay()
  rseed(1)
  local s=Sample:new()
  for i=1,100000 do s:inc(i) end
  table.sort(s.all)
  print(join(s.all)) end

-- main{lib=tests}
main{lib = sampleOkay}

local out = {}
for i=1,100 do out[ #out+1 ] = int(1+ rand() * 10) end
table.sort(out)
print( join(out,",") )
