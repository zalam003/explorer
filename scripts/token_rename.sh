#!/bin/bash
#
# Description: Script to rename eTokens to Tokens
#
# Dependency:
#   - etoken_contract_addr_mainnet.txt   Contract address for eTokens in mainnet
#   - etoken_contract_addr_testnet.txt   Contract address for eTokens in testnet
#
#set -x

if [[ $1 == mainnet ]]
then
    . ./mainnet_indexer.env
    export ADDRFILE=etoken_contract_addr_mainnet.txt

elif [[ $1 == testnet ]]
then
    . ./testnet_indexer.env
    export ADDRFILE=etoken_contract_addr_testnet.txt
    exit 0

elif [[ $1 == develop ]]
then
    . ./develop_indexer.env
    export ADDRFILE=etoken_contract_addr_mainnet.txt

elif [[ $1 == local ]]
then
    . ./local_indexer.env
    export ADDRFILE=etoken_contract_addr_mainnet.txt

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
# Rename Tokens
#######
IFS=$'\n'
for LINE in $( cat ${ADDRFILE} )
do
    CONTRACT=$(echo "$LINE" | awk '{print $1}')
    TOKEN=$(echo "$LINE" | awk '{print $2}')
    echo "Rename Token: ${TOKEN} with contract ${CONTRACT}"
    psql -d $PGDATABASE -U $PGUSER -h $PGHOST -t -c "UPDATE tokens SET
      symbol = '${TOKEN}'
      WHERE contract_address_hash = '${CONTRACT}';"
done
