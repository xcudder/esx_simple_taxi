local car, driver, starting_point, cfg = false, false, false, false, false

function debug_message(msg)
	if(Config.debug) then
		Wait(1000)
		ESX.ShowHelpNotification(msg)
	end
end

function spawn_car()
	starting_point = GetEntityCoords(PlayerPedId())
	debug_message("Estabilished starting point")

	while not HasModelLoaded(cfg.driver_hash) do
		RequestModel(cfg.driver_hash)
		Wait(100)
	end
	debug_message("Loaded driver hash")

	while not HasModelLoaded(cfg.car_hash) do
		RequestModel(cfg.car_hash)
		Wait(50)
	end
	debug_message("Loaded car hash")

	driver = CreatePed(4, cfg.driver_hash, starting_point.x, starting_point.y, starting_point.z + 2, GetEntityHeading(PlayerPedId()), true, true)
	debug_message("Created driver ped")

	ESX.Game.SpawnVehicle(cfg.car_hash, starting_point, GetEntityHeading(PlayerPedId()), function(vehicle) car = vehicle  end)
	debug_message("Called SpawnVehicle")

	while not car do Wait(100) end

	SetVehicleHasBeenOwnedByPlayer(car, true)
	SetVehicleDoorsLocked(car, 4)
	debug_message("Vehicle spawned")

	SetPedIntoVehicle(driver, car, -1)
	SetPedIntoVehicle(PlayerPedId(), car, 2)
end

function get_going()
	local arrived, dest, distance_to_destination = false, false, false

	while not dest do
		if DoesBlipExist(GetFirstBlipInfoId(8)) then
			dest = GetBlipCoords(GetFirstBlipInfoId(8))
		else
			ESX.ShowHelpNotification("Choose a destination via waypoint")
			Wait(1000)
		end
	end

	debug_message("Got destination blip")
	TaskVehicleDriveToCoordLongrange(driver, car, dest.x, dest.y, dest.z, cfg.speed, cfg.drive_mode, cfg.range)
	debug_message("Started driving task")

	Citizen.CreateThread(function()
		while not arrived do
			Wait(1000)

			if DoesBlipExist(GetFirstBlipInfoId(8)) and dest ~= GetBlipCoords(GetFirstBlipInfoId(8)) then
				debug_message("checking for arrival: Updated destination")
				dest = GetBlipCoords(GetFirstBlipInfoId(8))
			end

			local player_coords = GetEntityCoords(PlayerPedId())
			debug_message("checking for arrival: Got player coords")

			distance_to_destination = Vdist(player_coords.x, player_coords.y, player_coords.z, dest.x, dest.y, dest.z)
			debug_message("checking for arrival: Distance to destination: " .. distance_to_destination)

			arrived = distance_to_destination < cfg.range
			if arrived then
				debug_message("We arrived")
				DeletePed(driver)
				ESX.Game.DeleteVehicle(car)

				local distance = CalculateTravelDistanceBetweenPoints(
					starting_point.x, starting_point.y, starting_point.z, dest.x, dest.y, dest.z
				)
				debug_message("We traveled " .. distance)

				local price = (distance/1000) * cfg.price_per_km
				debug_message("Ride cost: " .. price)				

				ESX.TriggerServerCallback('esx_simple_taxi:pay', function(success)
					if not success then
						SetEntityCoords(PlayerPedId(), starting_point.x, starting_point.y, starting_point.z)
					end
					car, driver, starting_point, dest = false, false, false, false
				end, price)
			else
				debug_message("checking for arrival: Not close enough yet")
			end 
		end
	end)
end

RegisterCommand("call_car", function(source, args)
	if (args[1] == 'particular') then
		cfg = Config.particular
	else
		cfg = Config.taxi
	end

	spawn_car()
	get_going()
end)