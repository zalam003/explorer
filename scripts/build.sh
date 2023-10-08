#!/bin/bash

export DATABASE_URL=postgresql://explorer_mainnet_db:Block6scout123@127.0.0.1:5432/explorer_mainnet_db
export SECRET_KEY_BASE=IWTVkfnfrKBta0U6p4UUbajb44wu5lYcrK0B6drT+dvnuTvSN18vliy3cxUnLXt3

# remove static assets from the previous build
mix phx.digest.clean

# Set env variables
. ./local_indexer.env

# Compile the application:
mix compile

# Create and migrate database 
mix do ecto.create, ecto.migrate

# Install Node.js dependencies
cd apps/block_scout_web/assets; npm install && node_modules/webpack/bin/webpack.js --mode production; cd -
cd apps/explorer && npm install; cd -

# Build static assets for deployment 
mix phx.digest

# Enable HTTPS in development. The Phoenix server only runs with HTTPS
cd apps/block_scout_web; mix phx.gen.cert blockscout blockscout.local; cd -

# start the Phoenix Server. 
mix phx.server
