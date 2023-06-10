fx_version 'adamant'

game 'gta5'

description 'ESX Simple Taxi'

shared_script '@es_extended/imports.lua'

server_scripts {
	'server/main.lua'
}

client_scripts {
	'client/main.lua',
	'config.lua',
}