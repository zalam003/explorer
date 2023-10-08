#!/bin/bash

export DATABASE_URL=postgresql://explorer_mainnet_db:Block6scout123@127.0.0.1:5432/explorer_mainnet_db
export SECRET_KEY_BASE=IWTVkfnfrKBta0U6p4UUbajb44wu5lYcrK0B6drT+dvnuTvSN18vliy3cxUnLXt3

# remove static assets from the previous build
#../rel/commands/clear_build.sh
mix phx.digest.clean
if [ -d _build ]
then
    rm -rf _build
fi
if [-d deps ]
then
    rm -rf deps
fi
if [ -d apps/block_scout_web/assets/node_modules ]
then
    rm -rf apps/block_scout_web/assets/node_modules
fi
if [ -d apps/explorer/node_modules ]
then
    rm -rf apps/explorer/node_modules
fi

echo "Set env variables"
. ./local_indexer.env

echo "Compile the application..."
mix deps.get
mix compile

echo "Create and migrate database..."
mix do ecto.create, ecto.migrate

echo "Install Node.js dependencies..."
cd apps/block_scout_web/assets; npm install && node_modules/webpack/bin/webpack.js --mode production; cd -
cd apps/explorer && npm install; cd -

echo "Build static assets for deployment..."
mix phx.digest

echo "Enable HTTPS in development. The Phoenix server only runs with HTTPS..."
cd apps/block_scout_web; mix phx.gen.cert blockscout blockscout.local; cd -

# start the Phoenix Server. 
#mix phx.server
