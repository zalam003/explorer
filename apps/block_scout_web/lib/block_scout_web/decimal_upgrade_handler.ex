defmodule BlockScoutWeb.DecimalUpgradeHandler do

  alias Explorer.Chain.Cache.NetVersion
  alias Explorer.Chain.Address
  alias BlockScoutWeb.CurrencyHelpers

  def upgraded_decimal_contracts() do
    chain_id = NetVersion.get_version()

    # contract_addresses => %{
    #   decimals(before updrade) => 18
    #   "upgrade_block_number" => 959415
    # }

    if chain_id == 39797 do
      # mainnet
      {
      }
    else
      # testnet
      %{
        "0x6EAdB8BA9b1054fC7D82B4129EbBEFF807852190" =>  %{
          "decimals" => Decimal.new(18),
          "upgrade_block_number" => 959415
        }
      }
    end
  end

  def handle_decimals_upgrade(token_transfers) do
    Enum.map(token_transfers, fn token_transfer ->
      upgraded_decimal_contracts_list = upgraded_decimal_contracts()
      token_contract_address_str = Address.checksum(token_transfer.token.contract_address_hash)
      decimals = upgraded_decimal_contracts_list[token_contract_address_str]["decimals"]
      upgrade_block_number = upgraded_decimal_contracts_list[token_contract_address_str]["upgrade_block_number"]

      if !is_nil(decimals) and token_transfer.block_number < upgrade_block_number do
        token = Map.put(token_transfer.token, :decimals, decimals)
        Map.put(token_transfer, :token, token)
      else
        token_transfer
      end
    end)
  end

  def handle_decimal_upgrade_for_transaction(transactions) do
    Enum.map(transactions, fn transaction ->
      token_transfer = handle_decimals_upgrade(transaction.token_transfers)
      Map.put(transaction, :token_transfers, token_transfer)
    end)
  end

  def update_decimal_for_token_balance(token_balance) do
      upgraded_decimal_contracts_list = upgraded_decimal_contracts()
      %Address.CurrentTokenBalance{token: token} = token_balance
      token_contract_address_str = Address.checksum(token.contract_address_hash)
      decimals = upgraded_decimal_contracts_list[token_contract_address_str]["decimals"]
      upgrade_block_number = upgraded_decimal_contracts_list[token_contract_address_str]["upgrade_block_number"]

      if !is_nil(decimals) and token_balance.block_number < upgrade_block_number do
        balance_value = CurrencyHelpers.divide_decimals(token_balance.value, Decimal.sub(decimals, token.decimals))
        Map.put(token_balance, :value, Decimal.round(balance_value, 0, :down))
      else
        token_balance
      end
  end

  def handle_decimals_upgrade_for_token_balance(tokens) when is_list(tokens) do
    Enum.map(tokens, fn item ->
      case item do
        {token_balance, bridged_token, token} ->
          {update_decimal_for_token_balance(token_balance), bridged_token, token}

        token_balance ->
          update_decimal_for_token_balance(token_balance)
      end
    end)
  end

end
