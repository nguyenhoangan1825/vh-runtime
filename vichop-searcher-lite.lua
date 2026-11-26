-- VicHop 3.4.0: event-aware fast scans and parallel next-server preparation.
local g = getgenv()
g.VicHopOwnConfig = type(g.VicHopOwnConfig) == "table" and g.VicHopOwnConfig or {}
g.VicHopOwnConfig.searcher_low_resource = true
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/d7c73602d89d0bf0b537af94210a09731284cb31/v3.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
