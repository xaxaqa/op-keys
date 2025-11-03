ESX = exports["es_extended"]:getSharedObject()

RegisterServerEvent('op-carlock:toggleLock')
AddEventHandler('op-carlock:toggleLock', function(plate, netId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh then return end

    MySQL.query('SELECT 1 FROM owned_vehicles WHERE plate = ? AND owner = ?', {plate, xPlayer.identifier}, function(result)
        if not result[1] then return xPlayer.showNotification('~o~Not your car!~s~') end

        local hasKey = exports.ox_inventory:Search(src, 'count', 'carkeys', {plate = plate}) > 0
        if not hasKey then return xPlayer.showNotification('~o~No keys!~s~') end

        local locked = GetVehicleDoorLockStatus(veh) == 2
        local newState = locked and 1 or 2
        SetVehicleDoorsLocked(veh, newState)
        TriggerClientEvent('op-carlock:playEffects', src, veh, newState)
        xPlayer.showNotification(locked and '~g~Unlocked~s~' or '~r~Locked~s~')
    end)
end)

RegisterNetEvent('op-carlock:givekey')
AddEventHandler('op-carlock:givekey', function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    exports.ox_inventory:RemoveItem(src, 'carkeys', 99)
    
    if exports.ox_inventory:AddItem(src, 'carkeys', 1, {plate = plate, description = 'Keys for '..plate}) then
        xPlayer.showNotification('~g~Keys received~s~ for ~y~'..plate)
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
    
    xPlayer.showNotification(removed > 0 and ('~r~Keys removed~s~ for ~y~'..plate) or ('~o~No keys found~s~ for ~y~'..plate))
end)