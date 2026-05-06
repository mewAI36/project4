repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local player
repeat task.wait() player = Players.LocalPlayer until player
repeat task.wait() until player:FindFirstChild("Data")

if not player.Team then
    pcall(function()
        game:GetService("ReplicatedStorage")
            :WaitForChild("Remotes")
            :WaitForChild("CommF_")
            :InvokeServer("SetTeam", "Marines")
    end)
end

repeat task.wait() until player.Team ~= nil

getgenv().XERO_KEY = getgenv().XERO_KEY or "KEY_XERO"
getgenv().NIGHT_KEY = getgenv().NIGHT_KEY or "KEY_NIGHT"

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")

getgenv().BlockXero = false

local CONFIG = getgenv().CONFIG or {
    ["CONFIG"] = {
        ["Find Tushita"] = true,
        ["Find Valkyrie Helm"] = true,
        ["Find Dark Fragment"] = true,
        ["Find Soul Reaper"] = true
    }
}

local function getSea()
    if workspace:FindFirstChild("Map") then
        if workspace.Map:FindFirstChild("Dressrosa") then
            return 2
        elseif workspace.Map:FindFirstChild("TikiOutpost") then
            return 3
        else
            return 1
        end
    end
    return 0
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
        return player:WaitForChild("Data"):WaitForChild("Level").Value
    end)
    return success and lvl or 0
end

local function GetMob(NAME)
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") then
            if typeof(NAME) == "table" and table.find(NAME, v.Name) then
                return v
            end
        end
    end
end

local function CheckSoulReaper()
    return GetMob({"Soul Reaper"}) ~= nil
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
        ["Auto Tushita"] = false,
        ["Auto Tushita [HOP]"] = false,
        ["Auto Kill Boss"] = false,
        ["Auto Kill Boss [HOP]"] = false,
        ["Select Boss"] = "rip_indra"
    }

    if mode == "TUSHITA" then
        data["Auto Tushita"] = true
        data["Auto Tushita [HOP]"] = true
    elseif mode == "INDRA" then
        data["Auto Kill Boss"] = true
        data["Auto Kill Boss [HOP]"] = true
    elseif mode == "DARKBEARD" then
        data["Auto Kill Boss"] = true
        data["Auto Kill Boss [HOP]"] = true
        data["Select Boss"] = "Darkbeard"
    elseif mode == "CDK" then
        data["Auto Kill Boss"] = true
        data["Auto Kill Boss [HOP]"] = true
        data["Select Boss"] = "Soul Reaper"
    end

    if makefolder then makefolder(folder) end
    if writefile then writefile(file, HttpService:JSONEncode(data)) end
end

local function runScript()
    getgenv().Team = "Marines"

    local env = {}
    setmetatable(env, {
        __index = getgenv(),
        __newindex = getgenv()
    })

    env.script_key = getgenv().NIGHT_KEY

    local src = game:HttpGet("https://raw.githubusercontent.com/WhiteX1208/Scripts/refs/heads/main/HopScript.luau")
    local fn = loadstring(src)

    setfenv(fn, env)
    fn()
end

task.spawn(function()
    if getPlayerLevel() > 1500 and getSea() == 2 and hasItem("Dark Fragment") == 0 then
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

        if getSea() ~= 3 then continue end
        if not CONFIG["CONFIG"]["Find Soul Reaper"] then continue end

        local alucard = hasItem("Alucard Fragment")

        if GetCDKProcess() == "Hell Dimension Quest" and alucard >= 3 and alucard < 6 then
            if CheckSoulReaper() then
                if not waitingSoul then
                    waitingSoul = true
                    task.delay(120, function()
                        if waitingSoul then
                            setupConfig("CDK")
                            runScript()
                            waitingSoul = false
                        end
                    end)
                end
            else
                waitingSoul = false
                setupConfig("CDK")
                runScript()
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(60)

        if getSea() ~= 3 then continue end

        if CONFIG["CONFIG"]["Find Tushita"] and hasItem("Tushita") == 0 then
            setupConfig("TUSHITA")
            runScript()
        elseif CONFIG["CONFIG"]["Find Valkyrie Helm"] and hasItem("Valkyrie Helm") == 0 then
            setupConfig("INDRA")
            runScript()
        end
    end
end)
