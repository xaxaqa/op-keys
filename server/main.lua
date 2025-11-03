ESX = exports["es_extended"]:getSharedObject()

local function Notify(src, message, type)
    if Config.Notify == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, {description = message, type = type or 'inform'})
    else
        ESX.GetPlayerFromId(src).showNotification(message)
    end
end

RegisterServerEvent('op-carlock:toggleLock')
AddEventHandler('op-carlock:toggleLock', function(plate, netId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh then return end

    MySQL.query('SELECT 1 FROM owned_vehicles WHERE plate = ? AND owner = ?', {plate, xPlayer.identifier}, function(result)
        if not result[1] then return Notify(src, 'Not your car!', 'error') end

        local hasKey = exports.ox_inventory:Search(src, 'count', 'carkeys', {plate = plate}) > 0
        if not hasKey then return Notify(src, 'No keys!', 'error') end

        local locked = GetVehicleDoorLockStatus(veh) == 2
        local newState = locked and 1 or 2
        SetVehicleDoorsLocked(veh, newState)
        TriggerClientEvent('op-carlock:playEffects', -1, netId, newState)
        Notify(src, locked and 'Unlocked' or 'Locked', locked and 'success' or 'error')
    end)
end)

RegisterNetEvent('op-carlock:givekey')
AddEventHandler('op-carlock:givekey', function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    exports.ox_inventory:RemoveItem(src, 'carkeys', 99)
    
    if exports.ox_inventory:AddItem(src, 'carkeys', 1, {plate = plate, description = 'Keys for '..plate}) then
        Notify(src, 'Keys received for '..plate, 'success')
    end
end)

RegisterNetEvent('op-carlock:removekey')
AddEventHandler('op-carlock:removekey', function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local removed = 0
    local items = exports.ox_inventory:Search(src, 'slots', 'carkeys')
    
    if items then
        for _, item in pairs(items) do
            if item.metadata and item.metadata.plate == plate then
                if exports.ox_inventory:RemoveItem(src, 'carkeys', 1, item.metadata, item.slot) then
                    removed = removed + 1
                end
            end
        end
    end
    
    Notify(src, removed > 0 and ('Keys removed for '..plate) or ('No keys found for '..plate), removed > 0 and 'error' or 'inform')
end)