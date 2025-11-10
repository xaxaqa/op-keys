ESX = exports["es_extended"]:getSharedObject()
local dict = "anim@mp_player_intmenu@key_fob@"
local lockedInside = false
local lastLock = 0
local function Notify(msg, type)
    if Config.Notify == 'ox' then
        exports.ox_lib:notify({description = msg, type = type or 'inform'})
    else
        ESX.ShowNotification(msg)
    end
end
Citizen.CreateThread(function()
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Citizen.Wait(100) end
end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, Config.Key) and GetGameTimer() - lastLock > (Config.LockCooldown or 800) then
            lastLock = GetGameTimer()
            local ped = PlayerPedId()
            local veh = ESX.Game.GetClosestVehicle(GetEntityCoords(ped))
            if veh and #(GetEntityCoords(ped) - GetEntityCoords(veh)) <= (Config.LockDistance or 8.0) then
                TriggerServerEvent('op-carlock:toggleLock', ESX.Math.Trim(GetVehicleNumberPlateText(veh)), NetworkGetNetworkIdFromEntity(veh))
            else
                Notify("No vehicle nearby!", 'error')
            end
        end
        if lockedInside then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh == 0 or not IsVehiclePreviouslyOwnedByPlayer(veh) then
                lockedInside = false
            else
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 75, true)
            end
        end
    end
end)
RegisterNetEvent('op-carlock:playAnimation')
AddEventHandler('op-carlock:playAnimation', function(netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or not DoesEntityExist(veh) then return end
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, true) and #(GetEntityCoords(ped) - GetEntityCoords(veh)) <= (Config.LockDistance or 8.0) then
        TaskPlayAnim(ped, dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
    end
end)
RegisterNetEvent('op-carlock:playEffects')
AddEventHandler('op-carlock:playEffects', function(netId, status)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or not DoesEntityExist(veh) then return end
    local ped = PlayerPedId()
    SetVehicleDoorsLocked(veh, status)
    Citizen.CreateThread(function()
        for i = 1, 2 do
            SetVehicleLights(veh, 2)
            Citizen.Wait(150)
            SetVehicleLights(veh, 0)
            Citizen.Wait(150)
        end
    end)
    if status == 2 then
        PlayVehicleDoorCloseSound(veh, 1)
        for i = 0, 7 do
            if IsVehicleDoorFullyOpen(veh, i) then
                SetVehicleDoorShut(veh, i, false)
            end
        end
        lockedInside = IsPedInVehicle(ped, veh, false)
    else
        PlayVehicleDoorOpenSound(veh, 0)
        lockedInside = false
    end
end)