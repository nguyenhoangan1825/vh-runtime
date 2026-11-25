-- VicHop 3.3.1: finish current Vic; preserve opt-in Lite searchers.
local g = getgenv()
g.VicHopOwnConfig = type(g.VicHopOwnConfig) == "table" and g.VicHopOwnConfig or {}
g.VicHopOwnConfig.searcher_low_resource = true
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/86346f43afdb9e9718b7f0aa555a1e3c8afd66a9/v3.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
