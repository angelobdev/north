#!/bin/bash

# Variables
ASSETS_DIRECTORY="services/assets/public"

# UTILITIES
Black=30       # Black
Red=31         # Red
Green=32       # Green
Yellow=33      # Yellow
Blue=34        # Blue
Purple=35      # Purple
Cyan=36        # Cyan
White=37       # White

echoc () {
    printf "\033[1;${1}m${2}\033[0m\n"
}

# ***** Making sure all dependencies exist (Git + Node + Docker) *****
echoc ${Purple} 'Making sure dependencies are met...'

# Git
if ! command -v git &> /dev/null
then
    echoc ${Red} 'Sorry but it seems Git is not installed! Please install it and re-run this script...'
    exit
fi

# Node
if ! command -v npm &> /dev/null
then
    echoc ${Red} 'Sorry but it seems NodeJS is not installed! Please install it and re-run this script...'
    exit
fi

# Docker
if ! command -v docker &> /dev/null
then
    echoc ${Red} 'Sorry but it seems Docker is not installed! Please install it and re-run this script...'
    exit
fi

# Python
if ! command -v python3 &> /dev/null
then
    echoc ${Red} 'Sorry but it seems Python 3 is not installed! Please install it and re-run this script...'
    exit
fi

echoc ${Green} Done!

# ***** Getting default assets *****
echoc ${Purple} 'Getting default assets...'

# Nitro
if [ ! -d "services/assets/public" ]
then
    git clone --recursive https://git.krews.org/nitro/default-assets ${ASSETS_DIRECTORY}
    rm -rf ./services/assets/public/bundled/generic/room.nitro
else
    echoc ${Cyan} 'Skipping Nitro default'
fi

# SWFs
if [ ! -d "services/assets/public/swf" ]
then
    git clone --recursive https://git.krews.org/morningstar/arcturus-morningstar-default-swf-pack.git ${ASSETS_DIRECTORY}/swf
else
    echoc ${Cyan} 'Skipping SWFs default'
fi

# room.nitro
if [ ! -f "services/assets/public/bundled/generic/room.nitro" ]
then
    wget https://github.com/billsonnn/nitro-react/files/10334858/room.nitro.zip
    unzip -o room.nitro.zip -d ./services/assets/public/bundled/generic
    rm room.nitro.zip
else
    echoc ${Cyan} 'Skipping room.nitro'
fi

# Starting assets service
echoc ${Red} 'Starting assets service on port 8080'
docker compose up assets -d --build

echoc ${Green} Done!

# ***** Creating database service *****
echoc ${Red} 'Starting database service on port 3306'
docker compose up database -d --build
echoc ${Green} Done!

# ***** Cloning arcturus emulator and plugins ******

# Arcturus # TODO: solve developer mode issue (promptEnterKey)
if [ ! -d "services/emulator" ]
then
    echoc ${Purple} 'Cloning Arcturus Emulator...'
    git clone --branch ms4/dev https://git.krews.org/morningstar/Arcturus-Community.git services/emulator
    mkdir services/emulator/plugins
else
    echoc ${Cyan} 'Skipping Arcturus Emulator...'
fi

# MS WebSocket Plugin
if [ ! -f "services/emulator/plugins/websockets.jar" ]
then
    echoc ${Purple} 'Downloading NitroWebsockets for MS...'
    wget -O services/emulator/plugins/websockets.jar https://git.krews.org/morningstar/nitrowebsockets-for-ms/-/raw/master/target/NitroWebsockets-3.1.jar
else
    echoc ${Cyan} 'Skipping NitroWebsockets for MS...'
fi

echoc ${Red} 'Starting emulator service on port 2096 (WS)'
docker compose up emulator -d --build

echoc ${Green} Done!

# ***** Getting default SQL and waiting for user to upload it into database (default + fix) *****
echoc ${Purple} 'Getting default SQLs...'

if [ ! -f "data/SQLs/default.sql" ]
then
    echoc ${Purple} 'Downloading default MS4 database...'
    wget -O data/SQLs/default.sql https://git.krews.org/morningstar/ms4-base-database/uploads/0343964415cb7b25f4616204463c537a/ms4db-all-init.sql
else
    echoc ${Cyan} 'Skipping default MS4 database...'
fi

echoc ${Yellow} 'Please execute the SQL files in data/SQLs directory...'
read -n 1 -s -r -p "Press any key to continue (after execution)"
echo

# ***** Updating SWFs using habbo-downloader *****
echoc ${Yellow} 'Do you want to update to latest production?'
echoc ${Red} 'Do it if this is the first time running this script!'
printf "[y/N] >> "
read update_production

if [[ "$update_production" =~ [yY] ]]
then
    echoc ${Purple} 'Installing habbo-downloader using npm'
    npm i -g habbo-downloader

    echoc ${Yellow} 'Please insert your language locale'
    echoc ${Yellow} 'Valid inputs are [ com.br, com.tr, com, de, es, fi, fr, it, nl ]'
    printf ">> "
    read locale # TODO: add check for valid inputs

    echoc ${Purple} 'Updating to latest production... (it might take a while)'
    rm -rf services/assets/public/swf/gordon/PRODUCTION

    habbo-downloader --output ./services/assets/public/swf --domain $locale --command badgeparts
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command badges
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command clothes
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command effects
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command furnitures
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command gamedata
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command gordon
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command hotelview
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command icons
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command mp3
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command pets
    habbo-downloader --output ./services/assets/public/swf --domain $locale --command promo

    cp -n services/assets/public/swf/dcr/hof_furni/icons/* services/assets/public/swf/dcr/hof_furni
    mv services/assets/public/swf/gordon/PRODUCTION* services/assets/public/swf/gordon/PRODUCTION

    echoc ${Green} Done!

    # ***** Converting swf assets into .nitro (nitro-converter) *****
    echoc ${Purple} 'Configuring nitro-converter...'
    cp data/configurations/configuration.json tools/nitro-converter/configuration.json
    echoc ${Green} Done!

    echoc ${Red} 'Starting nitro-converter... (it might take a while)'
    cd tools/nitro-converter
    yarn install && yarn build
    yarn start
    cd ../..
    echoc ${Purple} 'Copying new files...'
    cp -R tools/nitro-converter/assets/* services/assets/public/
    echoc ${Green} Done!

    # ***** Translation *****
    echoc ${Purple} 'Translating Furnidata and Productdata...'
    python3 tools/scripts/FurnitureDataTranslator.py
    echoc ${Green} Done!

    echoc ${Purple} 'Generating SQLs...'
    python3 tools/scripts/SQLGenerator.py
    cp -R tools/scripts/catalog_items.sql data/SQLs/catalog_items.sql
    echoc ${Green} Done!

    # ***** Waiting for user to upload updated SQLs *****
    echoc ${Yellow} 'Please execute the catalog_items.sql in data/SQLs directory...'
    read -n 1 -s -r -p "Press any key to continue (after execution)"
    echo

else
    echoc ${Cyan} 'Skipping update'
fi

# ***** Configuring nitro-react *****
if [ ! -d "services/nitro" ]
then
    echoc ${Purple} 'Cloning nitro-react...'
    git clone --branch dev https://github.com/billsonnn/nitro-react.git services/nitro
    echoc ${Green} Done!
else
    echoc ${Cyan} 'Skipping nitro-react configuration...'
fi

echoc ${Purple} 'Configuring nitro-react...'
cp -R data/configurations/Dockerfile services/nitro/Dockerfile
cp -R data/configurations/vite.config.js services/nitro/vite.config.js
cp -R data/configurations/renderer-config.json services/nitro/public/renderer-config.json
cp -R data/configurations/ui-config.json services/nitro/public/ui-config.json

docker compose up nitro -d --build

# ***** Cleaning up *****
echoc ${Purple} 'Cleaning up...'
rm -rf services/emulator/examples
rm -rf services/emulator/old-sql-files
rm -rf services/emulator/sqlupdates
echoc ${Green} Done!

# ***** RUNNING EVERYTHING *****
