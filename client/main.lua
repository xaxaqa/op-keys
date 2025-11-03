ESX = exports["es_extended"]:getSharedObject()
local dict = "anim@mp_player_intmenu@key_fob@"
local lockedInside = false

local function Notify(message, type)
    if Config.Notify == 'ox' then
        exports.ox_lib:notify({description = message, type = type or 'inform'})
    else
        ESX.ShowNotification(message)
    end
end

Citizen.CreateThread(function()
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Citizen.Wait(100) end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, Config.Key) then
            local ped = PlayerPedId()
            local veh = ESX.Game.GetClosestVehicle(GetEntityCoords(ped))
            
            if veh then
                local plate = ESX.Math.Trim(GetVehicleNumberPlateText(veh))
                TriggerServerEvent('op-carlock:toggleLock', plate, NetworkGetNetworkIdFromEntity(veh))
            else
                Notify("No vehicle nearby!", 'error')
            end
        end

        if lockedInside then
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
        end
    end
end)

RegisterNetEvent('op-carlock:playEffects')
AddEventHandler('op-carlock:playEffects', function(netId, status)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or not DoesEntityExist(veh) then return end
    
    local ped = PlayerPedId()
    
    if not IsPedInAnyVehicle(ped, true) then
        TaskPlayAnim(ped, dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
    end
    
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
        for i = 0, 3 do SetVehicleDoorShut(veh, i, false) end
        lockedInside = IsPedInVehicle(ped, veh, false)
    else
        PlayVehicleDoorOpenSound(veh, 0)
        lockedInside = false
    end
end)