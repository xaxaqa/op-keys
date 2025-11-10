ESX = exports["es_extended"]:getSharedObject()
local cache = {}
local function Notify(src, msg, type)
    if Config.Notify == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, { description = msg, type = type })
    else
        ESX.GetPlayerFromId(src).showNotification(msg)
    end
end
AddEventHandler('playerDropped', function()
    local src = source
    for k in pairs(cache) do
        if k:match('^' .. src .. ':') then cache[k] = nil end
    end
end)
RegisterServerEvent('op-carlock:toggleLock')
AddEventHandler('op-carlock:toggleLock', function(plate, netId)
    local src = source
    local p = ESX.GetPlayerFromId(src)
    if not p then return end
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh then return end
    if exports.ox_inventory:Search(src, 'count', 'carkeys', { plate = plate }) == 0 then
        return Notify(src, 'No keys!', 'error')
    end
    local key = src .. ':' .. plate
    local owned = cache[key]
    if owned == false then return Notify(src, 'Not your car!', 'error') end
    if owned ~= true then
        local row = MySQL.single.await([[
            SELECT owner, job, jobGrade, jobLocked
            FROM owned_vehicles
            WHERE plate = ? LIMIT 1
        ]], { plate })
        if not row then return Notify(src, 'Vehicle not registered!', 'error') end
        local isPersonal = row.owner and row.owner == p.identifier
        local isJob = false
        if row.job and row.jobLocked == 'true' then
            isJob = p.job.name == row.job and p.job.grade >= (row.jobGrade or 0)
        end
        cache[key] = (isPersonal or isJob) and true or false
        if not (isPersonal or isJob) then
            return Notify(src, 'Not your car!', 'error')
        end
    end
    local locked = GetVehicleDoorLockStatus(veh) == 2
    local new = locked and 1 or 2
    SetVehicleDoorsLocked(veh, new)
    TriggerClientEvent('op-carlock:playEffects', -1, netId, new)
    TriggerClientEvent('op-carlock:playAnimation', src, netId)
    Notify(src, locked and 'Unlocked' or 'Locked', locked and 'success' or 'error')
end)
RegisterNetEvent('op-carlock:givekey')
AddEventHandler('op-carlock:givekey', function(plate)
    local src = source
    local p = ESX.GetPlayerFromId(src)
    if not p then return end
    exports.ox_inventory:RemoveItem(src, 'carkeys', 99)
    if exports.ox_inventory:AddItem(src, 'carkeys', 1, { plate = plate, description = 'Keys for ' .. plate }) then
        Notify(src, 'Keys received for ' .. plate, 'success')
        cache[src .. ':' .. plate] = true
    end
end)
RegisterNetEvent('op-carlock:removekey')
AddEventHandler('op-carlock:removekey', function(plate)
    local src = source
    local p = ESX.GetPlayerFromId(src)
    if not p then return end
    local removed = 0
    for _, v in pairs(exports.ox_inventory:Search(src, 'slots', 'carkeys') or {}) do
        if v.metadata and v.metadata.plate == plate and exports.ox_inventory:RemoveItem(src, 'carkeys', 1, v.metadata, v.slot) then
            removed = removed + 1
        end
    end
    if removed > 0 then cache[src .. ':' .. plate] = nil end
    Notify(src, removed > 0 and 'Keys removed for ' .. plate or 'No keys found for ' .. plate,
        removed > 0 and 'error' or 'inform')
end)