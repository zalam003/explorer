#!/bin/bash
#
# Description: Script to remove duplicate tokens from Block Explorer DB
#
# Dependency:
#   - dup_contract_addr_mainnet.txt   Contract address for duplicates in mainnet
#   - dup_contract_addr_testnet.txt   Contract address for duplicates in testnet
#
#set -x

if [[ $1 == mainnet ]]
then
#    . ./mainnet_indexer.env
    export ADDRFILE=dup_contract_addr_mainnet.txt

elif [[ $1 == testnet ]]
then
#    . ./testnet_indexer.env
    export ADDRFILE=dup_contract_addr_testnet.txt

elif [[ $1 == develop ]]
then
    . ./develop_indexer.env
    export ADDRFILE=dup_contract_addr_mainnet.txt

elif [[ $1 == local ]]
then
    . ./local_indexer.env
    export ADDRFILE=dup_contract_addr_mainnet.txt

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
export TMPCONTRACTFILE=token_contract_address_hash.tmp

# Install psql client if not there
if [ ! -x "$( command -v psql )" ]
then
    sudo apk add postgresql-client
fi

#######
# Remove user address Tokens
#######
> ${TMPCONTRACTFILE}
for TOKEN_ADDR in `cat ${ADDRFILE} | awk '{print $1}'`
do
    echo "Token Address: ${TOKEN_ADDR}"
    psql -d $PGDATABASE -U $PGUSER -P pager=off -t -c "SELECT token_contract_address_hash,address_hash FROM address_current_token_balances WHERE token_contract_address_hash = '${TOKEN_ADDR}' and value > 0;" >> ${TMPCONTRACTFILE}
done

# Remove duplicates
sort -u ${TMPCONTRACTFILE} -o ${TMPCONTRACTFILE}
# Remove blank
sed -i '/^$/d' ${TMPCONTRACTFILE}
# Remove delimiter
sed -i 's/ |//g' ${TMPCONTRACTFILE}

#
IFS=$'\n'
for LINE in $( cat ${TMPCONTRACTFILE} )
do
    CONTRACT=$(echo "$LINE" | awk '{print $1}')
    ADDR=$(echo "$LINE" | awk '{print $2}')
    echo "Contract: ${CONTRACT}  Address: ${ADDR}"
    psql -d $PGDATABASE -U $PGUSER -t \
      -c "UPDATE address_current_token_balances SET \
      value = null, \
      value_fetched_at = NOW(), \
      updated_at = NOW() \
      WHERE address_hash = '${ADDR}' \
        AND token_contract_address_hash = '${CONTRACT}';"
done

# Clean up
if [[ -f ${TMPCONTRACTFILE} ]]
then
    rm ${TMPCONTRACTFILE}
fi    

#######
# Remove Tokens from list
#######
for ADDR in `cat ${ADDRFILE} | awk '{print $1}'`
do
    echo "Remove from Tokens List: ${ADDR}"
    psql -d $PGDATABASE -U $PGUSER -h $PGHOST -t -c "UPDATE tokens SET \
      total_supply = 0 \
      WHERE contract_address_hash = '${ADDR}';"

done
