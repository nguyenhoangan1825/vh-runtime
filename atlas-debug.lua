-- Atlas D1-20261124: observation-only diagnostics on the published Resume build.
-- Based on our prior test launcher and pinned third-party Atlas build.
-- Base: DarkBotGen/atlasbss @ 88492a18a102cdeadae279c5c2ac363816cd1b91
-- Configs: atlas-test/. Live Roblox behavior has not been verified here.
-- Cach dung: vao Bee Swarm Simulator, dong Atlas cu, copy toan bo file va dan vao executor.
-- Day la launcher thu nghiem: can Internet de tai dung commit source da kiem tra.
-- Da qua compile Luau 0.748 va 20 kiem tra launcher cuc bo; chua test trong Roblox.
-- Loi khi chay duoc ghi ra console; neu co writefile, xem atlas-test-error.log.
local SOURCE_URL = "https://raw.githubusercontent.com/DarkBotGen/atlasbss/88492a18a102cdeadae279c5c2ac363816cd1b91/atlasbss.lua"
local EXPECTED_BYTES = 2673837
local EXPECTED_ADLER = 3442727789
local PATCHED_ADLER = 4292441072
local TAG = "[Atlas D1] "
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
 local first="\n\tif userFlag == true then\n"
 local last="\n\tif not (userFlag == false or not localPlayer.UserId"
 local a=assert(string.find(source,first,1,true),"Missing refusal branch")
 local b=assert(string.find(source,last,a+#first,true),"Missing branch boundary")
 local stop="\n\tif userFlag == true then\n\t\terror(\"Atlas test: upstream policy refused this account; stopped without external scripts.\",0)\n\tend\n"
 source=string.sub(source,1,a-1)..stop..string.sub(source,b)
 local tail=assert(string.find(source,"\nlocalPlayer:Kick(\"You are blacklisted",1,true),"Missing fallback boundary")
 source=string.sub(source,1,tail-1).."\nerror(\"Atlas test: upstream startup policy rejected this session.\",0)\n"
 source=replaceLiteral(source,[=[while not localPlayer.PlayerGui:FindFirstChild("LoadingScreenGui") or localPlayer.PlayerGui.LoadingScreenGui.LoadingMessage.Visible do
	RunService.Heartbeat:Wait()
end]=],[=[do
 local deadline=os.clock()+90
 while true do
  local playerGui=localPlayer:FindFirstChild("PlayerGui")
  local loading=playerGui and playerGui:FindFirstChild("LoadingScreenGui")
  local message=loading and loading:FindFirstChild("LoadingMessage")
  if playerGui and (not loading or not message or not message.Visible) then break end
  if os.clock()>deadline then error("Atlas test: loading screen timeout (90s).",0) end
  RunService.Heartbeat:Wait()
 end
end]=],1)
 source=replaceLiteral(source,'loadstring(game:HttpGet("https://raw.githubusercontent.com/DarkBotGen/atlasbss/main/atlasbss.lua"))()','getgenv().__AtlasRebuiltTestReload()',1)
 source=replaceLiteral(source,'"atlas-','"atlas-test-',9)
 source=replaceLiteral(source,'"atlas/','"atlas-test/',26)
 source=replaceLiteral(source,'"atlas"','"atlas-test"',3)
 source=replaceLiteral(source,[=[function showerController:ResumeOthers()
	self.suspending = false
	if state then state.stopface = self.previousStopface end
	local paused = self.paused
	self.paused = {}
	if self.shuttingDown or threads.closed or not state or state.stop then return end
	for id, job in pairs(paused) do
		if id == "Autofarm" and not cfg.autofarm.enabled then continue end
		if id == "fasttween" and not cfg.detected.background then continue end
		if not threads:Get(id) then
			threads:Add(id, job.callback, job.delaySeconds, table.unpack(job.args,1,job.args.n))
		end
	end
end
]=],[=[function showerController:ResumeOthers()
 -- Atlas Resume Fix 2026-11-24: keep suspended jobs until Stop is released.
 self.suspending = false
 if state then state.stopface = self.previousStopface end
 if self.shuttingDown or threads.closed or not state then
  table.clear(self.paused)
  return
 end
 if state.stop then return end
 local paused = self.paused
 self.paused = {}
 for id, job in pairs(paused) do
  if id == "Autofarm" and not cfg.autofarm.enabled then continue end
  if id == "walkspeed" and not cfg.vars.walkspeedenabled then continue end
  if id == "autodig" and not cfg.autofarm.autodig then continue end
  if id == "fasttween" and not cfg.detected.background then continue end
  if not threads:Get(id) then
   threads:Add(id, job.callback, job.delaySeconds, table.unpack(job.args,1,job.args.n))
  end
 end
end
]=],1)
 source=replaceLiteral(source,[=[controls["Stop Everything"] = Home.AddSwitch("Stop Everything", function(stop)
		if not stop or not threads:Get("Autofarm") then
			if not stop then
				for _, amuletName in ipairs({ "Moon Amulet", "Star Amulet", "Mutations", "Royal Jelly", "Gifted Basic" }) do
					if not threads:Get("Auto " .. amuletName) then
						continue
					end
					ui.Notify("Warning", "Auto " .. amuletName .. " is still running")
					controls["Stop Everything"].Set(true)
					return
				end

				if not (not cfg.autofarm.enabled or threads:Get("Autofarm")) then
					threads:Add("Autofarm", autofarmLoop)
				end
			end
		else
			threads:Cancel("Autofarm")
			stopMovement()
		end

		state.stop = stop or nil
		if stop and showerController.cancel then showerController.cancel("Stop Everything") end
	end)
]=],[=[controls["Stop Everything"] = Home.AddSwitch("Stop Everything", function(stop)
  if stop then
   -- Set the global flag before cancellation callbacks can resume workers.
   state.stop = true
   if threads:Get("Autofarm") then
    threads:Cancel("Autofarm")
    stopMovement()
   end
   if showerController.cancel then showerController.cancel("Stop Everything") end
   return
  end
  for _, amuletName in ipairs({ "Moon Amulet", "Star Amulet", "Mutations", "Royal Jelly", "Gifted Basic" }) do
   if threads:Get("Auto " .. amuletName) then
    ui.Notify("Warning", "Auto " .. amuletName .. " is still running")
    controls["Stop Everything"].Set(true)
    return
   end
  end
  state.stop = nil
  showerController:ResumeOthers()
  if cfg.autofarm.enabled and not threads:Get("Autofarm") then
   threads:Add("Autofarm", autofarmLoop)
  end
 end)
]=],1)
 source=replaceLiteral(source,[=[Farming.AddSwitch("Autofarm", function(n)
					if n and not state.stop and not threads:Get("Autofarm") then
						threads:Add("Autofarm", autofarmLoop)
					elseif not n and threads:Get("Autofarm") then
						threads:Cancel("Autofarm")
						stopMovement()
					end
				end, "autofarm", "enabled")]=],[=[Farming.AddSwitch("Autofarm", function(n)
  if n then
   if not state.stop and not threads:Get("Autofarm") then
    threads:Add("Autofarm", autofarmLoop)
   end
  else
   -- Remove a queued job too, even when there is no live Autofarm coroutine.
   threads:Cancel("Autofarm")
   stopMovement()
   if showerController.cancel then showerController.cancel("Autofarm disabled") end
  end
 end, "autofarm", "enabled")]=],1)
 source=replaceLiteral(source,[====[local connections = { list = {}, closed = false }]====],[====[local connections = { list = {}, closed = false }
local farmDiagnostic = {
 build="D1-20261124", phases=setmetatable({}, {__mode="k"}),
 pending=setmetatable({}, {__mode="k"}), lastWrite=0,
}
function farmDiagnostic:Mark(name)
 local thread=coroutine.running()
 local old=self.phases[thread]
 if not old or old.name~=name then self.phases[thread]={name=name,since=os.clock()} end
end
function farmDiagnostic:Error(id,message)
 self.lastError={job=tostring(id),message=string.sub(tostring(message),1,4000),time=os.time()}
end
function farmDiagnostic:Snapshot()
 local now=os.clock()
 local function names(t)
  local list={};for id in pairs(t or {})do list[#list+1]=tostring(id)end;table.sort(list);return list
 end
 local main=threads:Get("Autofarm")
 local phase=main and self.phases[main]
 local pending=main and self.pending[main]
 local jobs={}
 for id,thread in pairs(threads.list)do
  local ok,status=pcall(coroutine.status,thread)
  jobs[tostring(id)]=ok and status or "unknown"
 end
 local char=localPlayer.Character
 local h=char and char:FindFirstChildOfClass("Humanoid")
 local report={build=self.build,time=os.time(),phase=phase and phase.name or "No running Autofarm",
  phaseSeconds=phase and math.floor(now-phase.since) or 0,jobs=jobs,
  autofarmEnabled=cfg and cfg.autofarm.enabled,stop=state and state.stop==true,
  fastTween=state and state.fasttween==true,hivePending=state and state.hivePending==true,
  activity=state and state.activityStatus,speedActual=h and h.WalkSpeed,
  speedConfigured=cfg and cfg.vars.walkspeed,speedEnabled=cfg and cfg.vars.walkspeedenabled,
  shower=smoothMovement.showerController and smoothMovement.showerController.active or false,
  combo=smoothMovement.comboController and smoothMovement.comboController.active or false,
  mondo=mondoHop and mondoHop.active or false,
  showerPaused=names(smoothMovement.showerController and smoothMovement.showerController.paused),
  mondoPaused=names(mondoHop and mondoHop.paused),lastWorkerError=self.lastError}
 report.waitingCalls={}
 for parent,call in pairs(self.pending)do
  local id="unregistered"
  for job,thread in pairs(threads.list)do if thread==parent then id=tostring(job);break end end
  report.waitingCalls[#report.waitingCalls+1]={job=id,name=call.name,seconds=math.floor(now-call.since)}
 end
 report.jobPhases={}
 for id,thread in pairs(threads.list)do
  local p=self.phases[thread]
  if p then report.jobPhases[tostring(id)]={phase=p.name,seconds=math.floor(now-p.since)} end
 end
 report.mondoSettings={}
 if cfg and cfg.combat then
  for key,value in pairs(cfg.combat)do
   if string.find(string.lower(tostring(key)),"mondo",1,true) and (type(value)=="boolean" or type(value)=="number") then report.mondoSettings[key]=value end
  end
 end
 if mondoHop then
  report.mondoState={active=mondoHop.active==true,teleporting=mondoHop.teleporting==true,
   retrySeconds=mondoHop.retryAt and math.max(0,math.floor(mondoHop.retryAt-now)),
   sessionDone=mondoHop.session and mondoHop.session.done==true,
   deadline=mondoHop.session and mondoHop.session.deadline,
   returning=mondoHop.session and mondoHop.session.returning==true}
  local thread=threads:Get("MondoHop")
  if thread then
   local ok,stack=pcall(debug.traceback,thread,"MondoHop stack",0)
   if ok then report.mondoStack=string.sub(tostring(stack),1,5000) end
  end
 end
 if pending then report.secureCall={seconds=math.floor(now-pending.since),name=pending.name} end
 local combo=smoothMovement.comboController
 if combo and combo.taskTravel then
  local ok,status=pcall(coroutine.status,combo.taskTravel.thread)
  report.travelLock={ownerIsAutofarm=combo.taskTravel.thread==main,status=ok and status or "unknown"}
 end
 if main then
  local ok,stack=pcall(debug.traceback,main,"Autofarm stack",0)
  if ok then report.stack=string.sub(tostring(stack),1,5000) end
 end
 return report
end
function farmDiagnostic:Text()
 local ok,text=pcall(function()return HttpService:JSONEncode(self:Snapshot())end)
 return ok and text or ("Diagnostic error: "..tostring(text))
end
function farmDiagnostic:Tick(label)
 local main=threads:Get("Autofarm")
 local phase=main and self.phases[main]
 if label then label.Text="Farm: "..(phase and phase.name or "No running Autofarm") end
 if os.clock()-self.lastWrite>=15 then
  self.lastWrite=os.clock()
  if type(writefile)=="function" then pcall(writefile,"atlas-test-diagnostic.json",self:Text()) end
 end
end
]====],1)
 source=replaceLiteral(source,[====[if not ok then warn(err) end
	end)
	manager.list[threadId]]====],[====[if not ok then farmDiagnostic:Error(threadId,err);warn(err) end
	end)
	manager.list[threadId]]====],1)
 source=replaceLiteral(source,[====[			local q
			threadCount += 1]====],[====[			local q
			local parent=coroutine.running()
			local labelOk,label=pcall(debug.info,n,"n")
			farmDiagnostic.pending[parent]={since=os.clock(),name=labelOk and tostring(label) or "secureCall"}
			threadCount += 1]====],1)
 source=replaceLiteral(source,[====[			if not Z then
				error(p)]====],[====[			farmDiagnostic.pending[parent]=nil
			if not Z then
				error(p)]====],1)
 source=replaceLiteral(source,[====[			if state.hivePending then continue end
			if not state.stop and not state.fasttween then]====],[====[   if state.hivePending then farmDiagnostic:Mark("Waiting for hive claim");continue end
   if state.fasttween then farmDiagnostic:Mark("Blocked: fasttween") end
   if state.stop then farmDiagnostic:Mark("Global Stop") end
   if not state.stop and not state.fasttween then
    farmDiagnostic:Mark("Autofarm tasks")]====],1)
 source=replaceLiteral(source,[====[		convertHoney = function()
]====],[====[		convertHoney = function()
   farmDiagnostic:Mark("Convert honey")
]====],1)
 source=replaceLiteral(source,[====[						goTo(localPlayer.SpawnPos.Value.Position + Vector3.new(0, 0, cfg.vars.movement == "Tween" and 8 or 0), "Hive")]====],[====[						farmDiagnostic:Mark("Convert: travel to hive")
						goTo(localPlayer.SpawnPos.Value.Position + Vector3.new(0, 0, cfg.vars.movement == "Tween" and 8 or 0), "Hive")
						farmDiagnostic:Mark("Convert: at hive")]====],1)
 source=replaceLiteral(source,[====[	while self:TravelBlocked() do
]====],[====[	while self:TravelBlocked() do
  farmDiagnostic:Mark("Travel: waiting for movement owner")
]====],1)
 source=replaceLiteral(source,[====[	local lock={thread=running,character=localPlayer.Character}
]====],[====[	farmDiagnostic:Mark("Travel: moving")
	local lock={thread=running,character=localPlayer.Character}
]====],1)
 source=replaceLiteral(source,[====[function mondoHop:TakeMovement()
	if self.active then return end]====],[====[function mondoHop:TakeMovement()
	if self.active then return end
 farmDiagnostic:Mark("Mondo: taking movement")]====],1)
 source=replaceLiteral(source,[====[function mondoHop:Resume()
	if not self.active then return end]====],[====[function mondoHop:Resume()
	if not self.active then return end
 farmDiagnostic:Mark("Mondo: resuming workers")]====],1)
 source=replaceLiteral(source,[====[function mondoHop:Teleport(home)
]====],[====[function mondoHop:Teleport(home)
 farmDiagnostic:Mark(home and "Mondo: return-home check" or "Mondo: public-hop check")
]====],1)
 source=replaceLiteral(source,[====[					local killed=killMondo(nil,nil,session)]====],[====[					farmDiagnostic:Mark("Mondo Hop: fight/loot")
					local killed=killMondo(nil,nil,session)]====],1)
 source=replaceLiteral(source,[====[		killMondo(nil,nil,nil,true)]====],[====[		farmDiagnostic:Mark("Mondo Priority: fight/loot")
		killMondo(nil,nil,nil,true)]====],1)
 source=replaceLiteral(source,[====[	local runtimeMemoryLabel = Home.AddLabel("Client Lua heap: measuring...")]====],[====[ local runtimeMemoryLabel = Home.AddLabel("Client Lua heap: measuring...")
 Home.AddLabel("Build: D1-20261124 (logging only)")
 local diagnosticLabel=Home.AddLabel("Farm: starting")
 Home.AddButton("Copy Stuck Report",function()
  local text=farmDiagnostic:Text()
  if type(writefile)=="function" then pcall(writefile,"atlas-test-diagnostic.json",text) end
  if type(setclipboard)=="function" then pcall(setclipboard,text) end
  print("[Atlas D1 Diagnostic] "..text)
  ui.Notify("Diagnostic", "Report printed; copied if clipboard is supported")
 end)
 _G.__AtlasGetDiagnostic=function()return farmDiagnostic:Text()end]====],1)
 source=replaceLiteral(source,[====[			local n = os.clock() - state.start
]====],[====[			farmDiagnostic:Tick(diagnosticLabel)
			local n = os.clock() - state.start
]====],1)
 source=replaceLiteral(source,[====[	if _G.atlas == ScreenGui then _G.atlas = nil end
]====],[====[	if _G.atlas == ScreenGui then _G.atlas = nil;_G.__AtlasGetDiagnostic=nil end
]====],1)
 source=replaceLiteral(source,[====[local title = "Atlas+"]====],[====[local title = "Atlas+ [D1]"]====],1)
 if checksum(source)~=PATCHED_ADLER then fail("Patched source checksum mismatch.") end
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
 log("Downloading pinned reconstructed build...")
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
