-- Opt-in Searcher Lite. The Main keeps its normal policy.
local env=getgenv()
if type(env.VicHopOwnConfig)~='table' then env.VicHopOwnConfig={} end
env.VicHopOwnConfig.searcher_low_resource=true
env.VicHopReleaseURL="https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/5e896913315068b02b35bfa1f370a63e62a29132/v3.lua"
loadstring(game:HttpGet(env.VicHopReleaseURL))()
