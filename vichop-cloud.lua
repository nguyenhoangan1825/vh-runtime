-- VicHop own cloud loader. Set mainuser and optional hook before running.
local env = getgenv()
env.VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/fe51834109b310f6a2d6b5cc5a81190f98fe8544/v3.lua"
loadstring(game:HttpGet(env.VicHopReleaseURL))()
