repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

local player = Players.LocalPlayer
repeat task.wait() until player:FindFirstChild("Data")

if not player.Team then
    pcall(function()
        CommF:InvokeServer("SetTeam", "Marines")
    end)
end

repeat task.wait() until player.Team ~= nil

local function Convert_CFrame(x)
    if not x then return end
    return (typeof(x) == "Vector3" and CFrame.new(x))
        or (typeof(x) == "CFrame" and x)
        or (typeof(x) == "Model" and x:GetPivot())
        or (x:IsA("BasePart") and x.CFrame)
end

local function GetDistance(POS_1, POS_2, NO_Y)
    if POS_1 == nil then return 9e9 end

    local char = player.Character
    if not char then return 9e9 end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return 9e9 end

    POS_2 = POS_2 or hrp

    local cf1 = Convert_CFrame(POS_1)
    local cf2 = Convert_CFrame(POS_2)

    if not cf1 or not cf2 then return 9e9 end

    local p1 = Vector3.new(cf1.X, NO_Y and 0 or cf1.Y, cf1.Z)
    local p2 = Vector3.new(cf2.X, NO_Y and 0 or cf2.Y, cf2.Z)

    return (p1 - p2).Magnitude
end

local function IsAlive(v)
    if not v then return false end
    local humanoid = v:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetMob(NAME, FINDMORE, DISTANCE)
    if not NAME then return nil end

    local selecttarget, min_dist = nil, (DISTANCE or math.huge)

    local function isValid(v)
        if not v or not v:FindFirstChild("HumanoidRootPart") then
            return false
        end

        if not IsAlive(v) then
            return false
        end

        if typeof(NAME) == "table" then
            return table.find(NAME, v.Name) ~= nil
        elseif typeof(NAME) == "string" then
            return v.Name == NAME
        end

        return false
    end

    local function trySelect(v)
        local dist = GetDistance(v.HumanoidRootPart.Position)

        if dist <= min_dist then
            min_dist = dist
            selecttarget = v
        end
    end

    if workspace:FindFirstChild("Enemies") then
        for _, v in pairs(workspace.Enemies:GetChildren()) do
            if isValid(v) then
                trySelect(v)
            end
        end
    end

    if FINDMORE then
        for _, v in pairs(ReplicatedStorage:GetChildren()) do
            if isValid(v) then
                trySelect(v)
            end
        end
    end

    return selecttarget
end

local function CheckSoulReaper()
    local mob = GetMob({"Soul Reaper", "Soul Reaper Boss", "SoulReaper"}, true)
    return mob ~= nil, mob
end

getgenv().XERO_KEY = getgenv().XERO_KEY or "KEY_XERO"
getgenv().NIGHT_KEY = getgenv().NIGHT_KEY or "KEY_NIGHT"

local function getSea()
    if workspace:FindFirstChild("Map") then
        if workspace.Map:FindFirstChild("Dressrosa") then
            return 2
        elseif workspace.Map:FindFirstChild("TikiOutpost") then
            return 3
        end
    end

    return 1
end

local function hasItem(name)
    local success, result = pcall(function()
        local inv = CommF:InvokeServer("getInventory")

        for _, v in pairs(inv) do
            if v.Name == name then
                return v.Count or 1
            end
        end

        return 0
    end)

    return success and result or 0
end

local function getPlayerLevel()
    local success, lvl = pcall(function()
        return player.Data.Level.Value
    end)

    return success and lvl or 0
end

local function GetCDKProcess()
    local data = CommF:InvokeServer("CDKQuest", "Progress", "Good")
    return data and data.Evil == 2 and "Hell Dimension Quest" or "None"
end

local function setupConfig(mode)
    local folder = "Night Hub Hop Rewrite"
    local file = folder .. "/" .. player.Name .. "-Gay.json"

    local data = {
        ["Select Tool"] = "Melee",
        ["Auto Tushita"] = (mode == "TUSHITA"),
        ["Auto Tushita [HOP]"] = (mode == "TUSHITA"),
        ["Auto Kill Boss"] = (mode ~= "TUSHITA"),
        ["Auto Kill Boss [HOP]"] = true,
        ["Select Boss"] =
            (mode == "INDRA" and "rip_indra")
            or (mode == "DARKBEARD" and "Darkbeard")
            or (mode == "CDK" and "Soul Reaper")
            or ""
    }

    if makefolder then
        makefolder(folder)
    end

    writefile(file, HttpService:JSONEncode(data))
end

local function runScript()
    getgenv().Team = "Marines"

    local env = getgenv()
    env.script_key = getgenv().NIGHT_KEY

    local src = game:HttpGet("https://raw.githubusercontent.com/WhiteX1208/Scripts/refs/heads/main/HopScript.luau")
    local fn = loadstring(src)

    setfenv(fn, env)
    fn()
end

task.spawn(function()
    if getPlayerLevel() >= 1500 and getSea() == 2 and hasItem("Dark Fragment") == 0 then
        getgenv().BlockXero = true
        setupConfig("DARKBEARD")
        runScript()
    else
        getgenv().BlockXero = false
    end
end)

local waitingSoul = false

task.spawn(function()
    while true do
        task.wait(30)

        if getSea() ~= 3 then
            continue
        end

        if not (getgenv().CONFIG and getgenv().CONFIG["CONFIG"]["Find Soul Reaper"]) then
            continue
        end

        local alucard = hasItem("Alucard Fragment")

        if GetCDKProcess() == "Hell Dimension Quest" and alucard >= 3 and alucard < 6 then
            setupConfig("CDK")

            local soulFound = CheckSoulReaper()

            if soulFound then
                if not waitingSoul then
                    waitingSoul = true

                    task.delay(120, function()
                        runScript()
                        waitingSoul = false
                    end)
                end
            else
                runScript()
            end
        end
    end
end)

task.spawn(function()
    task.wait(10)

    if getSea() ~= 3 then
        return
    end

    local level = getPlayerLevel()
    local cfg = getgenv().CONFIG and getgenv().CONFIG["CONFIG"]

    if not cfg then
        return
    end

    if cfg["Find Tushita"]
        and level >= 2000
        and hasItem("Tushita") == 0 then

        setupConfig("TUSHITA")
        runScript()

    elseif cfg["Find Valkyrie Helm"]
        and level >= 1500
        and hasItem("Valkyrie Helm") == 0 then

        setupConfig("INDRA")
        runScript()
    end
end)
