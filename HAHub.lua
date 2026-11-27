-- HAHub 3.5.2
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
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/de04118489e08c78bdc06d8dbe880e998ef2f9bc/HAHub-runtime.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
