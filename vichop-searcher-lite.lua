-- VicHop 3.3: Lite searchers; Main retains kill/Stinger stats and saved speed.
local g = getgenv()
g.VicHopOwnConfig = type(g.VicHopOwnConfig) == "table" and g.VicHopOwnConfig or {}
g.VicHopOwnConfig.searcher_low_resource = true
g.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/4b803fa7d5fc5e62c7148efb90d85a00930a8338/v3.lua"
loadstring(game:HttpGet(g.VicHopReleaseURL))()
