-- Atlas VI4: source hosted and pinned in nguyenhoangan1825/vh-runtime.
-- Full editable source: atlas/source.lua; provenance: atlas/ORIGIN.md.
-- Config folder: atlas-test/. Diagnostic variant adds observation-only logs.
local SOURCE_URL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/8b36bf692272f16b0628b9c78449149ccbb355ba/atlas/source.lua"
local EXPECTED_BYTES = 2718736
local EXPECTED_ADLER = 721991047
local PATCHED_ADLER = 721991047
local TAG = "[Atlas VI4] "
local env = getgenv and getgenv() or _G
local function fail(message) error(TAG .. tostring(message), 0) end
local function log(message) print(TAG .. tostring(message)) end
local function checksum(s)
 local a,b=1,0
 for i=1,#s do a=(a+string.byte(s,i))%65521;b=(b+a)%65521 end
 return b*65536+a
end
local function replaceLiteral(s,old,new,expected)
 local parts,pos,count={},1,0
 while true do
  local a,b=string.find(s,old,pos,true)
  if not a then parts[#parts+1]=string.sub(s,pos);break end
  parts[#parts+1]=string.sub(s,pos,a-1);parts[#parts+1]=new
  pos=b+1;count+=1
 end
 if count~=expected then fail("Patch mismatch: "..tostring(count).." / "..tostring(expected)) end
 return table.concat(parts)
end
local function patchSource(source)
 if #source~=EXPECTED_BYTES or checksum(source)~=EXPECTED_ADLER then
  fail("Downloaded source differs from the reviewed build; stopped.")
 end

 if checksum(source)~=PATCHED_ADLER then fail("Patched source checksum mismatch.")end
 return source
end
local function preflight()
 if not game or not task then fail("This launcher requires a Roblox client environment.") end
 if game.PlaceId~=1537690962 then fail("Open Bee Swarm Simulator before running this build.") end
 if type(loadstring)~="function" then fail("Missing loadstring.") end
 local required={"getthreadidentity","setthreadidentity","newcclosure","getconnections","isfunctionhooked","isfile","isfolder","makefolder","readfile","writefile","listfiles"}
 local missing={}
 for _,name in ipairs(required)do if type(env[name])~="function"then missing[#missing+1]=name end end
 if type(debug)~="table"or type(debug.getupvalue)~="function"then missing[#missing+1]="debug.getupvalue"end
 if #missing>0 then fail("Missing APIs: "..table.concat(missing,", ")) end
 local ok,level=pcall(env.getthreadidentity)
 if not ok or type(level)~="number"or level<8 then fail("Upstream requires thread identity >= 8; this environment is unsupported.") end
 if _G.loading then fail("Another Atlas launch is still in progress; wait or rejoin first.") end
 if _G.atlas then fail("Close the existing Atlas UI before running this test build.") end
end
local patchedSource
local function executePatched()
 local chunk,compileError=loadstring(patchedSource,"=Atlas_Rebuilt_Test")
 if type(chunk)~="function"then fail("Compile failed: "..tostring(compileError))end
 local previous=_G.atlas
 local ok,result=xpcall(chunk,function(err)return debug.traceback(tostring(err),2)end)
 if not ok then
  local partial=_G.atlas
  if partial and partial~=previous then pcall(function()partial:Destroy()end)end
  _G.loading=nil
  warn(TAG..tostring(result))
  if type(env.writefile)=="function"then pcall(env.writefile,"atlas-test-error.log",tostring(result))end
  return false
 end
 _G.loading=nil
 if not _G.atlas then
  warn(TAG.."Source returned without creating an Atlas UI. Review its compatibility checks.")
  return false
 end
 log("UI loaded. Config folder: atlas-test/. Enable only the feature you want to test.")
 return true
end
local function start()
 preflight()
 log("Downloading your pinned Atlas source...")
 local ok,source=pcall(function()return game:HttpGet(SOURCE_URL)end)
 if not ok or type(source)~="string"then fail("Download failed: "..tostring(source))end
 patchedSource=patchSource(source)
 env.__AtlasRebuiltTestReload=function()
  task.defer(function()
   local previous=_G.atlas
   if previous then
    local stopped,err=pcall(function()previous:Destroy()end)
    if not stopped then warn(TAG.."Could not close previous UI: "..tostring(err));return end
   end
   _G.loading=nil
   executePatched()
  end)
 end
 executePatched()
end
local ok,err=xpcall(start,function(message)return debug.traceback(tostring(message),2)end)
if not ok then
 warn(tostring(err))
 if type(env.writefile)=="function"then pcall(env.writefile,"atlas-test-error.log",tostring(err))end
end
