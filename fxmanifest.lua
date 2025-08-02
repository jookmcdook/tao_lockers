fx_version 'cerulean'
game 'gta5'

author 'Tao'
description 'Storage Lockers'
ox_lib 'locale'

shared_scripts {
	'@ox_lib/init.lua',
	'shared.lua',
	'config.lua',
}

client_scripts {
	'client/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}

files { 'locales/*.json' }

lua54 'yes'