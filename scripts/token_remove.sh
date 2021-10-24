#!/bin/bash
#set -x

if [[ $1 == mainnet ]]
then
    . ./mainnet.env
    export FILENAME=smart_contracts_mainnet.csv
    export ADDRFILE=contract_address_mainnet.txt

elif [[ $1 == testnet ]]
then
    . ./testnet.env
    export FILENAME=smart_contracts_testnet.csv
    export ADDRFILE=contract_address_testnet.txt

elif [[ $1 == testmainnet ]]
then
    . ./local.env
    export ADDRFILE=contract_address_mainnet.txt

else
    echo
    echo "Usage: $0 <environment>"
    echo "    environments are:"
    echo "        testmainnet - Test Mainnet"
    echo "        testnet     - Production Testnet"
    echo "        mainnet     - Production Mainnet"
    echo
    exit

fi

#
export PGPORT=5432
export PGHOST
export PGDATABASE
export PGUSER
export PGPASSWORD
export TMPCONTRACTFILE=token_contract_address_hash.tmp

# Install psql client if not there
if [ ! -x "$( command -v psql )" ]
then
    sudo apt-get update
    sudo apt -y install postgresql-client

fi

#
# Remove user address Tokens
#
> ${TMPCONTRACTFILE}
for TOKEN_ADDR in `cat ${ADDRFILE} | awk '{print $1}'`
do
    echo "Token Address: ${TOKEN_ADDR}"
    psql -d $PGDATABASE -U $PGUSER -P pager=off -t -c "SELECT token_contract_address_hash,address_hash FROM address_current_token_balances WHERE token_contract_address_hash = '${TOKEN_ADDR}' and value > 0;" >> ${TMPCONTRACTFILE}
done

sort -u ${TMPCONTRACTFILE} -o ${TMPCONTRACTFILE}
sed -i '/^$/d' ${TMPCONTRACTFILE}
sed -i 's/ |//g' ${TMPCONTRACTFILE}

#
IFS=$'\n'
for LINE in $( cat ${TMPCONTRACTFILE} )
do
    echo "$LINE"
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

#
# Remove Tokens from list
#
for ADDR in `cat ${ADDRFILE} | awk '{print $1}'`
do
    # Remove from Tokens list
    echo "Remove from Tokens List: ${ADDR}"
    psql -d $PGDATABASE -U $PGUSER -h $PGHOST -t -c "UPDATE tokens SET \
      total_supply = 0 \
      WHERE contract_address_hash = '${ADDR}';"

done
