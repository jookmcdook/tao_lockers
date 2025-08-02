if GetResourceState('qbx-core') ~= 'started' then return end

Config = lib.load('shared')
local PlayerData = {}

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = exports.qbx_core:GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    table.wipe(PlayerData)
    onPlayerUnload()
end)

function hasPlyLoaded()
    return LocalPlayer.state.isLoggedIn
end

function DoNotification(text, nType)
    lib.notify({
        title = 'Storage System',
        description = text,
        type = nType
    })
end

function GetPlayerJob()
    return PlayerData.job.name
end

function GetJobGrade()
    return PlayerData.job.grade.level
end

function GetJobLabel(job)
    return PlayerData.job.label
end

function GetPlyCid()
    return PlayerData.citizenid
end

function hasItem(item)
    local count = exports.ox_inventory:Search('count', item)
    return count and count > 0
end

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    PlayerData = val
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    PlayerData.job = job
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(newDuty)
    PlayerData.job.onduty = newDuty
end)

AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() ~= res or not hasPlyLoaded() then return end
    PlayerData = exports.qbx_core:GetPlayerData()
end)