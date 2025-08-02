local QBX = exports['qb-core']:GetCoreObject()
local playerStorage = nil
local isNearStorage = false
local storageBlips = {}
local waitingForStorageData = false
local lastProximityCheck = 0
local proximityCheckInterval = 1000 -- Increased to 1 second
local playerCoords = vector3(0, 0, 0)
local lastCoordsUpdate = 0
local coordsUpdateInterval = 500 -- Update coords every 500ms

-- Get player's current storage data
local function getPlayerStorage()
    return playerStorage
end

-- Create blips for all storage locations
local function createStorageBlips()
    -- Wait for Config to be loaded
    while not Config do
        Wait(100)
    end
    
    -- Remove existing blips first
    for _, blip in pairs(storageBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    table.wipe(storageBlips)
    
    for k, location in ipairs(Config.AccessLocations) do
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, 50) -- Warehouse sprite
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 3) -- Blue color
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Storage")
        EndTextCommandSetBlipName(blip)
        
        storageBlips[k] = blip
    end
    
    print('[TAO_LOCKERS] Created', #storageBlips, 'storage blips')
end

local function updatePlayerCoords()
    local currentTime = GetGameTimer()
    if currentTime - lastCoordsUpdate > coordsUpdateInterval then
        playerCoords = GetEntityCoords(PlayerPedId())
        lastCoordsUpdate = currentTime
    end
end

local function checkNearStorage()
    updatePlayerCoords()
    
    for k, location in ipairs(Config.AccessLocations) do
        local distance = #(playerCoords - location.coords)
        if distance <= Config.CircleRadius then
            return true, k, location
        end
    end
    
    return false, nil, nil
end

local function showStorageUI()
    if not isNearStorage then
        lib.showTextUI('[E] - Access Storage', {
            position = "right-center"
        })
        isNearStorage = true
    end
end

local function hideStorageUI()
    if isNearStorage then
        lib.hideTextUI()
        isNearStorage = false
    end
end

local function openRentalMenu(tier, data)
    print('[TAO_LOCKERS] Opening rental menu for tier:', tier)
    
    local alert = lib.alertDialog({
        header = 'Confirm Rental',
        content = ('Rent %s for $%s/week?\n\nWeight: %s\nWeapon Limit: %s\nSlots: %s'):format(
            data.label, data.price, data.weight, data.weaponLimit, data.slots
        ),
        centered = true,
        cancel = true
    })
    
    if alert == 'confirm' then
        print('[TAO_LOCKERS] Confirming rental for tier:', tier)
        TriggerServerEvent('tao_lockers:server:rentStorage', tier)
    else
        print('[TAO_LOCKERS] Rental cancelled')
    end
end

local function openUpgradeMenu()
    local storage = getPlayerStorage()
    local currentTier = storage.tier
    local options = {}

    for tier, data in pairs(Config.StorageTiers) do
        if tier ~= currentTier then
            local isUpgrade = false
            if tier == 'medium' and currentTier == 'small' then
                isUpgrade = true
            elseif tier == 'large' and (currentTier == 'small' or currentTier == 'medium') then
                isUpgrade = true
            end

            if isUpgrade then
                options[#options + 1] = {
                    title = data.label,
                    description = ('$%s/week | %s weight | %s weapons max'):format(
                        data.price,
                        data.weight,
                        data.weaponLimit
                    ),
                    icon = 'fa-solid fa-arrow-up',
                    onSelect = function()
                        local alert = lib.alertDialog({
                            header = 'Confirm Upgrade',
                            content = ('Upgrade to %s for $%s/week?'):format(data.label, data.price),
                            centered = true,
                            cancel = true
                        })
                        
                        if alert == 'confirm' then
                            TriggerServerEvent('tao_lockers:server:upgradeStorage', tier)
                        end
                    end
                }
            end
        end
    end

    if #options == 0 then
        lib.notify({
            title = 'No Upgrades Available',
            description = 'You already have the largest storage tier',
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'upgrade_menu',
        title = 'Upgrade Storage',
        menu = 'storage_main_menu',
        options = options
    })

    lib.showContext('upgrade_menu')
end

local function openDowngradeMenu()
    local storage = getPlayerStorage()
    local currentTier = storage.tier
    local options = {}

    for tier, data in pairs(Config.StorageTiers) do
        if tier ~= currentTier then
            local isDowngrade = false
            if tier == 'small' and (currentTier == 'medium' or currentTier == 'large') then
                isDowngrade = true
            elseif tier == 'medium' and currentTier == 'large' then
                isDowngrade = true
            end

            if isDowngrade then
                options[#options + 1] = {
                    title = data.label,
                    description = ('$%s/week | %s weight | %s weapons max'):format(
                        data.price,
                        data.weight,
                        data.weaponLimit
                    ),
                    icon = 'fa-solid fa-arrow-down',
                    onSelect = function()
                        local alert = lib.alertDialog({
                            header = 'Confirm Downgrade',
                            content = ('Downgrade to %s for $%s/week?\n\nWarning: Items that exceed the new storage limits will be lost!'):format(data.label, data.price),
                            centered = true,
                            cancel = true
                        })
                        
                        if alert == 'confirm' then
                            TriggerServerEvent('tao_lockers:server:downgradeStorage', tier)
                        end
                    end
                }
            end
        end
    end

    if #options == 0 then
        lib.notify({
            title = 'No Downgrades Available',
            description = 'You already have the smallest storage tier',
            type = 'error'
        })
        return
    end

    lib.registerContext({
        id = 'downgrade_menu',
        title = 'Downgrade Storage',
        menu = 'storage_main_menu',
        options = options
    })

    lib.showContext('downgrade_menu')
end

local function openCancelMenu()
    local confirmation = lib.alertDialog({
        header = 'Cancel Rental',
        content = 'Are you sure you want to cancel your storage rental?\n\nAll items in storage will be permanently lost!',
        centered = true,
        cancel = true
    })

    if confirmation == 'confirm' then
        TriggerServerEvent('tao_lockers:server:cancelStorage')
    end
end

local function openStorageMenu()
    TriggerServerEvent('tao_lockers:server:requestStorageData')
    
    waitingForStorageData = true
    local attempts = 0
    while waitingForStorageData and attempts < 50 do -- Wait up to 5 seconds
        Wait(100)
        attempts = attempts + 1
    end
    
    local storage = getPlayerStorage()
    local options = {}

    if not storage then
        local tierOrder = {'small', 'medium', 'large'}
        for _, tier in ipairs(tierOrder) do
            local data = Config.StorageTiers[tier]
            options[#options + 1] = {
                title = data.label,
                description = ('$%s/week | %s weight | %s weapons max'):format(
                    data.price,
                    data.weight,
                    data.weaponLimit
                ),
                icon = 'fa-solid fa-warehouse',
                onSelect = function()
                    openRentalMenu(tier, data)
                end
            }
        end
    else
        local tierData = Config.StorageTiers[storage.tier]
        
        options[#options + 1] = {
            title = 'Access Storage',
            description = ('%s | %s weight | %s weapons max'):format(
                tierData.label,
                tierData.weight,
                tierData.weaponLimit
            ),
            icon = 'fa-solid fa-box-open',
            onSelect = function()
                exports.ox_inventory:openInventory('stash', storage.stashId)
            end
        }

        options[#options + 1] = {
            title = 'Upgrade Storage',
            description = 'Change to a larger storage tier',
            icon = 'fa-solid fa-arrow-up',
            onSelect = function()
                openUpgradeMenu()
            end
        }

        options[#options + 1] = {
            title = 'Downgrade Storage',
            description = 'Change to a smaller storage tier',
            icon = 'fa-solid fa-arrow-down',
            onSelect = function()
                openDowngradeMenu()
            end
        }

        options[#options + 1] = {
            title = 'Cancel Rental',
            description = 'Cancel your storage rental (items will be lost)',
            icon = 'fa-solid fa-times',
            onSelect = function()
                openCancelMenu()
            end
        }
    end

    lib.registerContext({
        id = 'storage_main_menu',
        title = 'Storage Rental',
        options = options
    })
    Wait(0)
    lib.showContext('storage_main_menu')
end

function onPlayerUnload()
    hideStorageUI()
    for _, blip in pairs(storageBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    table.wipe(storageBlips)
    playerStorage = nil
end

RegisterNetEvent('tao_lockers:client:setPlayerStorage', function(storage)
    playerStorage = storage
    waitingForStorageData = false
    print('[TAO_LOCKERS] Received storage data:', storage and storage.tier or 'none')
end)

RegisterNetEvent('tao_lockers:client:storageRented', function(storage)
    playerStorage = storage
    lib.notify({
        title = 'Storage Rented',
        description = ('Successfully rented %s storage'):format(storage.tier),
        type = 'success'
    })
end)

RegisterNetEvent('tao_lockers:client:storageUpgraded', function(storage)
    playerStorage = storage
    lib.notify({
        title = 'Storage Upgraded',
        description = ('Successfully upgraded to %s storage'):format(storage.tier),
        type = 'success'
    })
end)

RegisterNetEvent('tao_lockers:client:storageDowngraded', function(storage)
    playerStorage = storage
    lib.notify({
        title = 'Storage Downgraded',
        description = ('Successfully downgraded to %s storage'):format(storage.tier),
        type = 'success'
    })
end)

RegisterNetEvent('tao_lockers:client:storageCancelled', function()
    playerStorage = nil
    lib.notify({
        title = 'Storage Cancelled',
        description = 'Your storage rental has been cancelled',
        type = 'inform'
    })
end)

RegisterNetEvent('tao_lockers:client:rentDue', function(daysLeft)
    lib.notify({
        title = 'Rent Due',
        description = ('Your storage rent is due in %s days. Pay rent or lose access to your items!'):format(daysLeft),
        type = 'error'
    })
end)

RegisterNetEvent('tao_lockers:client:gracePeriod', function()
    lib.notify({
        title = 'Grace Period',
        description = 'Your storage rent is overdue! You have 24 hours to remove your items before storage is deleted.',
        type = 'error'
    })
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        Wait(2000) 
        createStorageBlips()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000) 
    createStorageBlips()
end)

RegisterNetEvent('QBCore:Client:OnPlayerSpawn', function()
    Wait(2000) 
    createStorageBlips()
end)

CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        if currentTime - lastProximityCheck > proximityCheckInterval then
            local nearStorage, locationIndex, location = checkNearStorage()
            
            if nearStorage then
                if not isNearStorage then
                    showStorageUI()
                end
                Wait(2000) 
            else
                if isNearStorage then
                    hideStorageUI()
                end
                Wait(3000)
            end
            
            lastProximityCheck = currentTime
        else
            Wait(2000) 
        end
    end
end)

CreateThread(function()
    while true do
        if isNearStorage then
            if IsControlJustPressed(0, 38) then -- E key
                openStorageMenu()
            end
            Wait(100)
        else
            Wait(2000)
        end
    end
end)
