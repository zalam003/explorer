#!/bin/bash
#
# Description: Script to rename LP Tokens
#
# Dependency:
#   - lp_token_rename_mainnet.txt   Contract address for LP Tokens in mainnet
#   - lp_token_rename_testnet.txt   Contract address for LP Tokens in testnet
#
#set -x

if [[ $1 == mainnet ]]
then
    . ./mainnet.env
    export LPTOKENLIST=lp_token_rename_mainnet.txt

elif [[ $1 == testnet ]]
then
    . ./testnet.env
    export LPTOKENLIST=lp_token_rename_testnet.txt

elif [[ $1 == develop ]]
then
    . ./develop.env
    export LPTOKENLIST=lp_token_rename_mainnet.txt

elif [[ $1 == local ]]
then
    . ./local.env
    export LPTOKENLIST=lp_token_rename_mainnet.txt

else
    echo
    echo "Usage: $0 <environment>"
    echo "    environments are:"
    echo "        local    - Local"
    echo "        develop  - Develop"
    echo "        testnet  - Testnet"
    echo "        mainnet  - Mainnet"
    echo
    exit

fi

# export variables
export PGPORT=5432
export PGHOST
export PGDATABASE
export PGUSER
export PGPASSWORD

# Install psql client if not there
if [ ! -x "$( command -v psql )" ]
then
    sudo apt-get update
    sudo apt -y install postgresql-client

fi

#######
# Rename LP Tokens
#######
IFS=$'\n'
for LINE in $( cat ${LPTOKENLIST} | grep -v \^# )
do
    CONTRACT=$(echo "$LINE" | awk -F\, '{print $1}')
    NAME=$(echo "$LINE" | awk -F\, '{print $2}')
    SYMBOL=$(echo "$NAME" | awk '{print $1}')
    echo "Rename conract: ${CONTRACT} Name: ${NAME} Symbol: ${SYMBOL}"
    psql -d $PGDATABASE -U $PGUSER -h $PGHOST -t -c "UPDATE tokens SET
      name = '${NAME}',
      symbol = '${SYMBOL}'
      WHERE contract_address_hash = '${CONTRACT}';"

done
