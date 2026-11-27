-- HAHub 3.5.4
if game.PlaceId ~= 1537690962 then return end
local g = getgenv()
local cfg = type(g.HAHub) == "table" and g.HAHub or {}
cfg.syncmode = "cloud"
cfg.searcher_low_resource = true
cfg.searcher_scan_seconds = 3
g.VicHopOwnConfig = cfg
if cfg.mainuser ~= nil then g.mainuser = cfg.mainuser end
if cfg.hook ~= nil then g.hook = cfg.hook end
if cfg.cloud_url ~= nil then g.VicHopCloudURL = cfg.cloud_url end
g.VicHopAutoExecuteOnly = false
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/7c15debe65a9fbacb197999f04804b72d5667bf8/HAHub-runtime.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
