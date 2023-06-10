ESX.RegisterServerCallback('esx_simple_taxi:pay', function(source, cb, price)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getMoney() >= price then
		xPlayer.removeMoney(price, "Taxi ride")
		TriggerClientEvent('esx:showNotification', source, "You paid " .. price)
		cb(true)
	else
		TriggerClientEvent('esx:showNotification', source, "You didn't have the money :(")
		cb(false)
	end
end)