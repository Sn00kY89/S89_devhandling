fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'S89 Dev handling'
version '2.0.0'
description 'Handling Editor'
author 'Sn00kY89'
url 'https://github.com/Sn00kY89'

shared_scripts {
    'locales/*.lua'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'config.lua',
    'server/generator.lua',
    'server/server.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/*.js',
    'html/*.css',

    'handling.meta',
}

data_file 'HANDLING_FILE' 'handling.meta'

escrow_ignore {
    'config.lua',
    'locales/*.lua'
}