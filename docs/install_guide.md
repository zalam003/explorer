# Blockscout deployment guide
This guide ooutlines the installation of Energi Block Explorer.  Block Explorer is based on Blockscout, an open source project.

## General Pre-Requirements
Following are the requirements to run Energi Block Explorer:

- Ubuntu-18.04 (Bionic) server
- Blockscout v3.7.0
- PostgreSQL Database v10.3+

We recommend following specifications for the servers:

<center>
<table>
    <tr><th>Function</th><th>CPU</th><th>Memory</th><th>Storage</th></tr> 
    <tr><td>Energi Core Node</td><td>8 x 2 GHz</td><td>16 GB</td><td>100 GB</td></tr> 
    <tr><td>Blockscout Web Server (FE)</td><td>4 x 2 GHz</td><td>8 GB</td><td>30 GB</td></tr>
    <tr><td>Blockscout Web Server (Indexer)</td><td>8 x 2 GHz</td><td>16 GB</td><td>30 GB</td></tr>
    <tr><td>Postgres Database</td><td>8 x 2 GHz</td><td>16 GB</td><td>300 GB</td></tr>
</table>
</center>

The high level architecture is as follows:

![Block Explorer Architecture](/docs/images/Block-Explorer-Architecture.png)


*Note*

_bash_ commands below are for reference only. Commands marked with $ should be executed as a user, under whom the blockscout service will be running. # means the command should be run as root. =# commands are executed in psql.


# Energi Core Node Setup

## Setup Energi Core Node per recommendations. Create an application user. Bootstrap to expedite sync.

Create users with sudo privileges to ensure basic server security.
```
# adduser nrgusr
# usermod -aG sudo nrgusr
```

## Auto start Energi Core Node

```
# nano /lib/systemd/system/energi3.service
```

```
[Unit]
Description=Energi Core Node Service
After=syslog.target network.target

[Service]
SyslogIdentifier=energi3
Type=simple
Restart=always
RestartSec=5
User=nrgusr
Group=nrgusr
UMask=0027
ExecStart=/home/nrgusr/energi3/bin/energi3 \
          --datadir /home/nrgusr/.energicore3 \
          --cache 5120 \
          --nousb \
          --gcmode archive \
          --syncmode "full" \
          --rpcvhosts '*' \
          --ws --wsaddr 10.6.96.5 --wsport 39795 \
          --rpc --rpcaddr 10.6.96.5 --rpcport 39796 \
          --rpcapi debug,net,eth,shh,web3,txpool,masternode,energi \
          --wsapi eth,net,web3,network,debug,txpool,masternode,energi \
          --rpccorsdomain '*' \
          --wsorigins '*' \
          --maxpeers 256 \
          --ethstats Explorer1:N6w9tW5J83bl@stats.energi.network:443
          --verbosity 0

WorkingDirectory=/home/nrgusr

[Install]
WantedBy=multi-user.target
```

Start Energi Core Node
```
$ sudo systemctl daemon-reload
$ sudo systemctl start energi3.service
```


# PostgreSQL setup
## PostgreSQL Pre-Install
Prepare and mount storage for BlockScout DB.  In production (Mainnet and Testnet), AWS RDS will be utilized.

## Install PostgreSQL
In Ubuntu, follow the steps below to setup PostgreSQL v10.3 Database:

```
$ sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
$ wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
$ sudo apt-get update
$ sudo apt-get install postgresql-10
```

## PostgreSQL configuration
Create a new user in the OS and set a password using adduser

```
# adduser nrgdba
# usermod -aG sudo nrgdba
```

Create a database, user and set userpassword

```
# su - postgres
$ createuser --interactive nrgdba
$ createdb blockscoutdb
$ psql
=# ALTER USER nrgdba WITH PASSWORD 'dbuserpassword';
=# GRANT ALL PRIVILEGES ON blockscoutdb TO nrgdba;
=# \q
```

_Note_

PSQL user should be first created as a general user with adduser. The user's system password should not be the same as their database dbuserpassword. dbuserpassword will be parsed by BlockScout as part of the DB link.  It is recommended to omit problematic characters in the database password.

Set your storage path as psql datadir

```
$ nano /etc/postgresql/10/main/postgresql.conf
```

```
...
data_directory = '/mnt/psql/storage/path'          # use data in another directory
...
```

Make sure the PSQL user has the right permissions on storage dir.

Start psql

```
$ sudo systemctl start postgresql
```

Validate data directory path

```
# su - postgres
$ psql
=# SHOW data_directory;
```

```
    data_directory
---------------------
 /mnt/psql/storage/path
(1 row)
```

```
=# \q
```

Make sure your user has blockscout db access

```
# su - nrgdba
$ psql -d blockscoutdb
```

Allow only the Blockscout servers to access port 5432/tcp.  All other access to the database should be restricted to ensure security.

Enable postgresql as service

```
$ sudo systemctl enable postgresql
```

# BlockScout dependencies setup

Get base dependencies from apt:

```
$ sudo apt-get update
$ sudo apt-get install git \
                       automake \
                       libtool inotify-tools \
                       libgmp-dev \
                       libgmp10 \
                       build-essential \
                       rustup \
                       cargo \
                       unzip \
                       cmake -y
```

## Erlang 23.3.1+

Get official release for Ubuntu:
```
$ wget https://packages.erlang-solutions.com/erlang/debian/pool/esl-erlang_23.3.1-1~ubuntu~bionic_amd64.deb
$ sudo apt install ./esl-erlang_23.3.1-1~ubuntu~bionic_amd64.deb
```
Check version and installation:

```
$ erl --version
```

## Elixir 1.11.4+
Download pre-compiled release from github:
```
$ wget https://github.com/elixir-lang/elixir/releases/download/v1.11.4/Precompiled.zip
$ unzip -o Precompiled.zip -d /opt/elixir
```

Add elixir bin to path:
```
$ export PATH="$PATH:/opt/elixir/bin"
```

```
$ nano ~/.bashrc
```
```
...
export PATH="$PATH:/opt/elixir/bin"
```

Check version and installation:
```
$ elixir --version
```

## Node.js 14.15.1
You can get Node.js here (opens new window)or in your distro repos:
```
$ curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
$ sudo apt-get update
$ sudo apt-get install -y nodejs
```

Check Node version:
```
$ nodejs --version
```

# BlockScout Setup

## Install and Compile

### Create application user for Blockscout:
```
# adduser bsusr
# usermod -aG sudo bsusr
```

### Get latest master from Gitlab:
```
# cd /opt
# git clone https://git.energi.software/energi/gen3/block-explorer.git
# chown -R bsusr:bsusr block-explorer
# su - bsusr
$ cd block-explorer
$ mkdir -p ./apps/ethereum_jsonrpc/priv/static
$ mkdir -p ./apps/explorer/priv/static
$ mkdir -p ./apps/indexer/priv/static
```

### Build Blockscout:
```
$ cd /opt/blockscout
$ mix deps.get
$ mix local.hex --force
$ cd /opt/blockscout/deps/libsecp256k1/c_src; ./build_deps.sh; cd -
$ mix do deps.get, local.rebar --force, deps.compile, compile  # in blockscout base dir
```

### Generate DB secret:
```
$ cd /opt/blockscout
$ export SECRET_KEY_BASE=$( mix phx.gen.secret )
$ echo $SECRET_KEY_BASE
```

### Set required env variables (to be updated). Following are some example for NRG:
```
$ export ETHEREUM_JSONRPC_HTTP_URL=http://IP_LB_CORE-NODE:39797
$ export COIN=NRG
$ export SUBNETWORK=Mainnet
$ export NETWORK=Energi
$ export DATABASE_URL=postgresql://nrgdba:dbpassword@IP_PG_HOST:5432/blockscoutdb
```

### Create DB schema:
```
$ mix do ecto.create, ecto.migrate
```

### Install Node.js deps, build static assets:
```
$ cd apps/block_scout_web/assets; npm install && node_modules/webpack/bin/webpack.js --mode production; cd -
$ cd apps/explorer && npm install; cd -
$ mix phx.digest
```

### Enable SSL (optional):
```
$ cd apps/block_scout_web; mix phx.gen.cert blockscout blockscout.local; cd -
```

The above command will generate and enable self-signed ssl certs.  It needs to be replaced with real ones.
```
$  nano /opt/blockscout/config/prod.exs
```

```
...
config :block_scout_web, BlockScoutWeb.Endpoint,
  http: [port: 4000],
  https: [
    port: 4001,
    cipher_suite: :strong,
    certfile: "priv/cert/cert.pem",
    keyfile: "priv/cert/privkey.pem"
  ]
...
```

## Set BlockScout as systemd service
Prepare BlockScout start script:
```
$ nano /opt/blockscout/scripts/start.sh
```

```
#!/bin/bash

export PATH="$PATH:/opt/elixir/bin"
export LOGO=/images/energi_logo.png
export LOGO_FOOTER=/images/energi_logo_footer.png
export BLOCKSCOUT_VERSION=v3.7.0
export ETHEREUM_JSONRPC_HTTP_URL=http://IP_LB-CORE-NODE:39796
export ETHEREUM_JSONRPC_WS_URL=ws://IP_LB-CORE-NODE:39795
export ETHEREUM_JSONRPC_TRACE_URL=$ETHEREUM_JSONRPC_HTTP_URL
export ETHEREUM_JSONRPC_TRANSPORT=http
export IPC_PATH=/root/.energicore3/energi3.ipc
export COIN=NRG
export GAS_PRICE=20
export ENABLE_TXS_STATS=true
export SHOW_TXS_CHART=true
export ALLOWED_EVM_VERSIONS=petersburg
export ETHEREUM_JSONRPC_VARIANT=geth
export COINGECKO_COIN_ID=energi
export SUBNETWORK=Mainnet
export NETWORK=Energi
export PORT=4000
export DATABASE_URL=postgresql://nrgdba:dbpassword@IP_PG_HOST:5432/blockscoutdb
export LINK_TO_OTHER_EXPLORERS=false
export SUPPORTED_CHAINS="[]"

/opt/elixir/bin/mix phx.server
```

```
$ chmod +x /opt/blockscout/scripts/start.sh
```

Set a start script as service.  Create 2 - 1) Blockscout Web and 2) Blockscout Indexer (to be added):
```
$ sudo nano /etc/systemd/system/blockscout_web.service
```

```
 [Unit]
 Description=Blockscout
 After=network.target energi3.service

 [Service]
 User=bsusr
 Group=bsusr
 WorkingDirectory=/opt/blockscout
 ExecStart=/bin/bash /opt/blockscout/scripts/start.sh
 KillSignal=SIGHUP

 [Install]
 WantedBy=default.target
 ```
 
### Setup firewall rules:
```
apt install ufw -y
ufw allow ssh/tcp
ufw limit ssh/tcp
# In-bound access to Core Node is not required
ufw deny 39797/tcp
ufw deny 39797/udp
ufw allow 4000/tcp
ufw allow 4001/tcp
ufw logging on
ufw enable
```

Test run:
```
$ sudo systemctl daemon-reload
$ sudo systemctl start blockscout_web
```

Enable blockscout as a service:

```
$ sudo systemctl enable blockscout_web.service
```
