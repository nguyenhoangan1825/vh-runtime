-- VicHop 3.3.1: finish current Vic first; preserve Lite searchers and saved settings.
local g = getgenv()
g.VicHopOwnConfig = type(g.VicHopOwnConfig) == "table" and g.VicHopOwnConfig or {}
g.VicHopOwnConfig.searcher_low_resource = true
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/86137cb7c17d45bb941ce092a9a51f36ee6f38fe/v3.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
