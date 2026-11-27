-- HAHub
if game.PlaceId ~= 1537690962 then return end
local g = getgenv()
local cfg = type(g.HAHub) == "table" and g.HAHub or {}
cfg.syncmode = "cloud"
cfg.searcher_low_resource = true
g.VicHopOwnConfig = cfg
if cfg.mainuser ~= nil then g.mainuser = cfg.mainuser end
if cfg.hook ~= nil then g.hook = cfg.hook end
if cfg.cloud_url ~= nil then g.VicHopCloudURL = cfg.cloud_url end
g.VicHopAutoExecuteOnly = false
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/33b123d80b1594dda5890603f9531114da46a75b/HAHub-runtime.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
