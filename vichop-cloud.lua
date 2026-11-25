-- VicHop 3.3.1: kill the local Vic before considering another server.
getgenv().VicHopReleaseURL = "https://raw.githubusercontent.com/nguyenhoangan1825/vh-runtime/86137cb7c17d45bb941ce092a9a51f36ee6f38fe/v3.lua"
loadstring(game:HttpGet(getgenv().VicHopReleaseURL))()
