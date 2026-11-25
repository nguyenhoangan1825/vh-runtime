-- VicHop 3.2: Lite searchers; Main retains stats and kill webhook.
local g = getgenv()
g.VicHopOwnConfig = type(g.VicHopOwnConfig) == "table" and g.VicHopOwnConfig or {}
g.VicHopOwnConfig.searcher_low_resource = true
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/ff55a24bb393bc8f7bc7ebc3dfb5cc12af51e319/v3.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
