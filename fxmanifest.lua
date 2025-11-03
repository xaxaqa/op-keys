fx_version 'cerulean'
game 'gta5'

author 'xaxaqa'

shared_scripts{
    'shared/config.lua',
    '@ox_lib/init.lua'
}

client_scripts{
    'client/main.lua'
}

server_scripts{
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}