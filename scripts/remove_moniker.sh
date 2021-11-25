#!/bin/bash
#
# Description: Remove '@ Energi' moniker from token names
#              Special case update name of BTC to Bitcoin in Mainnet
#
#set -x

if [[ $1 == mainnet ]]
then
    . ./mainnet.env
    export TMPFILE=token_moniker_mainnet.txt

elif [[ $1 == testnet ]]
then
    . ./testnet.env
    export TMPFILE=token_moniker_testnet.txt

elif [[ $1 == develop ]]
then
    . ./develop.env
    export TMPFILE=token_moniker_mainnet.txt

elif [[ $1 == local ]]
then
    . ./local.env
    export TMPFILE=token_moniker_mainnet.txt

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

echo "Download tokens with moniker"
psql -d $PGDATABASE -U $PGUSER -h $PGHOST -t -c "SELECT name,contract_address_hash FROM tokens WHERE name LIKE '%@ Energi';" > ${TMPFILE}

if [[ -s ${TMPFILE} ]]
then
    #######
    # Rename Tokens
    #######
    IFS=$'\n'
    for LINE in $( cat ${TMPFILE} )
    do
        CONTRACT=$(echo "$LINE" | awk -F\| '{print $2}' | awk '{$1=$1};1')
        NAME=$(echo "$LINE" | awk -F\| '{print $1}' | sed 's/ @ Energi//g' | awk '{$1=$1};1' )
        echo "Rename Token: ${NAME} with contract ${CONTRACT}"
        psql -d $PGDATABASE -U $PGUSER -h $PGHOST -t -c "UPDATE tokens SET
          name = '${NAME}'
          WHERE contract_address_hash = '${CONTRACT}';"
    done

else
    echo "Nothing to update..."

fi

# Change BTC name to Bitcoin
if [[ $1 == mainnet || $1 == develop ]]
then
    echo "Rename Token: Bitcoin from Energi BTC"
    psql -d $PGDATABASE -U $PGUSER -h $PGHOST -t -c "UPDATE tokens SET
      name = 'Bitcoin'
      symbol = 'BTC'
      WHERE contract_address_hash = '\x29a791703e5A5A8D1578F8611b4D3691377CEbc0';"

fi

# Clean up
rm ${TMPFILE}
