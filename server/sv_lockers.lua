local QBX = exports['qb-core']:GetCoreObject()
local playerStorages = {}
local lastRentProcess = 0
local rentProcessInterval = 600000 -- Process rent every 10 minutes instead of 5
local rentCheckInterval = 300000 -- Check for rent every 5 minutes

while not Config do
    Wait(100)
end

local function getPlayerStorage(cid)
    return playerStorages[cid]
end

local function hasStorage(cid)
    return playerStorages[cid] ~= nil
end

local function createStorageStash(cid, tier)
    local stashId = 'storage_' .. cid
    local tierData = Config.StorageTiers[tier]
    
    exports.ox_inventory:RegisterStash(
        stashId, 
        tierData.label, 
        tierData.slots, 
        tierData.weight * 1000, 
        nil, 
        nil
    )
    
    return stashId
end

local function checkWeaponLimit(cid, tier)
    local stashId = 'storage_' .. cid
    local tierData = Config.StorageTiers[tier]
    local items = exports.ox_inventory:GetInventoryItems(stashId)
    
    local weaponCount = 0
    for _, item in pairs(items) do
        if item.weapon then
            weaponCount = weaponCount + item.count
        end
    end
    
    return weaponCount <= tierData.weaponLimit
end

local function processRent()
    local currentTime = os.time()
    local rentInterval = 7 * 24 * 60 * 60 -- 7 days in seconds
    local processedCount = 0
    
    for cid, storage in pairs(playerStorages) do
        local player = QBX.Functions.GetPlayerByCitizenId(cid)
        local tierData = Config.StorageTiers[storage.tier]
        
        local timeSinceLastRent = currentTime - storage.lastRentPaid
        
        if timeSinceLastRent >= rentInterval then
            if player then
                local bankBalance = player.PlayerData.money['bank']
                
                if bankBalance >= tierData.price then
                    player.Functions.RemoveMoney('bank', tierData.price, 'storage-rent')
                    storage.lastRentPaid = currentTime
                    
                    MySQL.update.await('UPDATE player_storage SET last_rent_paid = ? WHERE citizenid = ?', {
                        currentTime, cid
                    })
                    
                    TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                        title = 'Storage System',
                        description = ('Rent paid: $%s'):format(tierData.price),
                        type = 'success'
                    })
                else
                    local gracePeriodEnd = storage.lastRentPaid + rentInterval + (Config.GracePeriod * 60 * 60)
                    
                    if currentTime >= gracePeriodEnd then
                        TriggerClientEvent('tao_lockers:client:gracePeriod', player.PlayerData.source)
                        
                        exports.ox_inventory:ClearInventory(storage.stashId)
                        MySQL.query.await('DELETE FROM player_storage WHERE citizenid = ?', {cid})
                        playerStorages[cid] = nil
                        
                        TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
                            title = 'Storage System',
                            description = 'Your storage has been deleted due to unpaid rent',
                            type = 'error'
                        })
                    else
                        local hoursLeft = math.floor((gracePeriodEnd - currentTime) / 3600)
                        TriggerClientEvent('tao_lockers:client:rentDue', player.PlayerData.source, hoursLeft)
                    end
                end
            else
                local gracePeriodEnd = storage.lastRentPaid + rentInterval + (Config.GracePeriod * 60 * 60)
                
                if currentTime >= gracePeriodEnd then
                    exports.ox_inventory:ClearInventory(storage.stashId)
                    MySQL.query.await('DELETE FROM player_storage WHERE citizenid = ?', {cid})
                    playerStorages[cid] = nil
                end
            end
            
            processedCount = processedCount + 1
        end
    end
    
    if processedCount > 0 then
        print('[TAO_LOCKERS] Processed rent for', processedCount, 'players')
    end
end

RegisterNetEvent('tao_lockers:server:requestStorageData', function()
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player then return end
    
    local cid = player.PlayerData.citizenid
    local storage = getPlayerStorage(cid)
    
    if storage then
        TriggerClientEvent('tao_lockers:client:setPlayerStorage', src, storage)
    else
        TriggerClientEvent('tao_lockers:client:setPlayerStorage', src, nil)
    end
end)

RegisterNetEvent('tao_lockers:server:rentStorage', function(tier)
    local src = source
    print('[TAO_LOCKERS] Rent storage event triggered by:', src, 'for tier:', tier)
    
    local player = QBX.Functions.GetPlayer(src)
    print('[TAO_LOCKERS] Player object:', player)
    
    if not player then 
        print('[TAO_LOCKERS] Player not found')
        return 
    end
    
    local cid = player.PlayerData.citizenid
    print('[TAO_LOCKERS] Citizen ID:', cid)
    
    if hasStorage(cid) then
        print('[TAO_LOCKERS] Player already has storage')
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You already have storage rented',
            type = 'error'
        })
    end
    
    local tierData = Config.StorageTiers[tier]
    if not tierData then
        print('[TAO_LOCKERS] Invalid tier:', tier)
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'Invalid storage tier',
            type = 'error'
        })
    end
    
    local bankBalance = player.PlayerData.money['bank']
    print('[TAO_LOCKERS] Bank balance:', bankBalance, 'Required:', tierData.price)
    
    if bankBalance < tierData.price then
        print('[TAO_LOCKERS] Not enough money')
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You don\'t have enough money in the bank',
            type = 'error'
        })
    end
    
    print('[TAO_LOCKERS] Creating storage...')
    
    local stashId = createStorageStash(cid, tier)
    local currentTime = os.time()
    
    local storage = {
        citizenid = cid,
        tier = tier,
        stashId = stashId,
        lastRentPaid = currentTime,
        created = currentTime
    }
    
    playerStorages[cid] = storage
    
    MySQL.insert.await('INSERT INTO player_storage (citizenid, tier, stash_id, last_rent_paid, created) VALUES (?, ?, ?, ?, ?)', {
        cid, tier, stashId, currentTime, currentTime
    })
    
    player.Functions.RemoveMoney('bank', tierData.price, 'storage-rent')
    
    print('[TAO_LOCKERS] Storage created successfully, notifying client')
    
    TriggerClientEvent('tao_lockers:client:storageRented', src, storage)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Storage System',
        description = ('Successfully rented %s storage for $%s/week'):format(tierData.label, tierData.price),
        type = 'success'
    })
end)

RegisterNetEvent('tao_lockers:server:upgradeStorage', function(newTier)
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player then return end
    
    local cid = player.PlayerData.citizenid
    local storage = getPlayerStorage(cid)
    
    if not storage then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You don\'t have any storage rented',
            type = 'error'
        })
    end
    
    local newTierData = Config.StorageTiers[newTier]
    if not newTierData then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'Invalid storage tier',
            type = 'error'
        })
    end
    
    local currentTierData = Config.StorageTiers[storage.tier]
    if newTierData.weight <= currentTierData.weight then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'This is not an upgrade',
            type = 'error'
        })
    end
    
    local bankBalance = player.PlayerData.money['bank']
    if bankBalance < newTierData.price then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You don\'t have enough money in the bank',
            type = 'error'
        })
    end
    
    if not checkWeaponLimit(cid, newTier) then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You have too many weapons for this storage tier',
            type = 'error'
        })
    end
    
    storage.tier = newTier
    storage.lastRentPaid = os.time()
    
    MySQL.update.await('UPDATE player_storage SET tier = ?, last_rent_paid = ? WHERE citizenid = ?', {
        newTier, storage.lastRentPaid, cid
    })
    
    player.Functions.RemoveMoney('bank', newTierData.price, 'storage-upgrade')
    
    TriggerClientEvent('tao_lockers:client:storageUpgraded', src, storage)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Storage System',
        description = ('Successfully upgraded to %s storage for $%s/week'):format(newTierData.label, newTierData.price),
        type = 'success'
    })
end)

RegisterNetEvent('tao_lockers:server:downgradeStorage', function(newTier)
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player then return end
    
    local cid = player.PlayerData.citizenid
    local storage = getPlayerStorage(cid)
    
    if not storage then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You don\'t have any storage rented',
            type = 'error'
        })
    end
    
    local newTierData = Config.StorageTiers[newTier]
    if not newTierData then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'Invalid storage tier',
            type = 'error'
        })
    end
    
    local currentTierData = Config.StorageTiers[storage.tier]
    if newTierData.weight >= currentTierData.weight then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'This is not a downgrade',
            type = 'error'
        })
    end
    
    local bankBalance = player.PlayerData.money['bank']
    if bankBalance < newTierData.price then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You don\'t have enough money in the bank',
            type = 'error'
        })
    end
    
    if not checkWeaponLimit(cid, newTier) then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You have too many weapons for this storage tier',
            type = 'error'
        })
    end
    
    storage.tier = newTier
    storage.lastRentPaid = os.time()
    
    MySQL.update.await('UPDATE player_storage SET tier = ?, last_rent_paid = ? WHERE citizenid = ?', {
        newTier, storage.lastRentPaid, cid
    })
    
    player.Functions.RemoveMoney('bank', newTierData.price, 'storage-downgrade')
    
    TriggerClientEvent('tao_lockers:client:storageDowngraded', src, storage)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Storage System',
        description = ('Successfully downgraded to %s storage for $%s/week'):format(newTierData.label, newTierData.price),
        type = 'success'
    })
end)

RegisterNetEvent('tao_lockers:server:cancelStorage', function()
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player then return end
    
    local cid = player.PlayerData.citizenid
    local storage = getPlayerStorage(cid)
    
    if not storage then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Storage System',
            description = 'You don\'t have any storage rented',
            type = 'error'
        })
    end
    
    exports.ox_inventory:ClearInventory(storage.stashId)
    MySQL.query.await('DELETE FROM player_storage WHERE citizenid = ?', {cid})
    playerStorages[cid] = nil
    
    TriggerClientEvent('tao_lockers:client:storageCancelled', src)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Storage System',
        description = 'Your storage rental has been cancelled',
        type = 'success'
    })
end)

function OnPlayerLoaded(src)
    local player = QBX.Functions.GetPlayer(src)
    if not player then return end
    
    local cid = player.PlayerData.citizenid
    local storage = getPlayerStorage(cid)
    
    if storage then
        TriggerClientEvent('tao_lockers:client:setPlayerStorage', src, storage)
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS player_storage (
                id INT(11) NOT NULL AUTO_INCREMENT,
                citizenid VARCHAR(60) NOT NULL,
                tier VARCHAR(20) NOT NULL,
                stash_id VARCHAR(60) NOT NULL,
                last_rent_paid BIGINT NOT NULL,
                created BIGINT NOT NULL,
                PRIMARY KEY (id),
                UNIQUE KEY citizenid (citizenid)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
        ]])
        
        local result = MySQL.query.await('SELECT * FROM player_storage')
        if result then
            for _, data in pairs(result) do
                playerStorages[data.citizenid] = {
                    citizenid = data.citizenid,
                    tier = data.tier,
                    stashId = data.stash_id,
                    lastRentPaid = data.last_rent_paid,
                    created = data.created
                }
                
                local tierData = Config.StorageTiers[data.tier]
                if tierData then
                    exports.ox_inventory:RegisterStash(
                        data.stash_id,
                        tierData.label,
                        tierData.slots,
                        tierData.weight * 1000,
                        nil,
                        nil
                    )
                end
            end
            print('[TAO_LOCKERS] Loaded', #result, 'existing storages')
        end
        
        CreateThread(function()
            while true do
                local currentTime = GetGameTimer()
                
                if currentTime - lastRentProcess > rentProcessInterval then
                    processRent()
                    lastRentProcess = currentTime
                end
                
                Wait(rentCheckInterval) 
            end
        end)
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    OnPlayerLoaded(src)
end)