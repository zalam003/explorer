defmodule BlockScoutWeb.DecimalUpgradeHandler do

  alias Explorer.Chain.Cache.NetVersion
  alias Explorer.Chain.Address
  alias BlockScoutWeb.CurrencyHelpers

  def upgraded_decimal_contracts() do
    chain_id = NetVersion.get_version()

    # token_contract_addresses => %{
    #   old_decimals(before updrade) => 18
    #   "upgrade_block_number" => 959415
    # }

    if chain_id == 39797 do
      # mainnet
      %{
        "0x29a791703e5A5A8D1578F8611b4D3691377CEbc0" =>  %{        # BTC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xdf13537f5a8c697bdeCB4870B249a1a9158b54c6" =>  %{        # CRO
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x1b53c0662414B195FcD5802C09754765b930A312" =>  %{        # CEL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xe59028425E3D3Cb0B9F71F9E18345bE517364d91" =>  %{        # ZIL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xad3EaC6a2EF827833880a10592C6E46605E4F9d6" =>  %{        # VGX
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x5666444647f4fD66DECF411D69f994B8244EbeE3" =>  %{        # CHSB
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x827c3f7FFa144598144F1E10ec9E157B5a0ABA18" =>  %{        # SCRT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x5E2D55bC07B63b18Af6C9ED8Da06CD33258ebb35" =>  %{        # ORN
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x79786Ed8a70ccEC6C7A31debC7FeFc5119f9dc95" =>  %{        # AMPL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x04cd06cf05b816F09395375f0143584B4A95eA9f" =>  %{        # FUN
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xE3D7a5C28d5a4143831242E8ab218D7e9B5c2c87" =>  %{        # UBT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x0d91d554768dC20E1D3D95FF9d5bC041edC3bA0f" =>  %{        # CVC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x83AF4137Ed450F4765A72831Dd938B5203f5d2Fb" =>  %{        # SRM
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x96717283E442FfCE9b636f004C196517a72eE4cA" =>  %{        # AION
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x2483a716A4A5476da5E657be13A37Cf62b608AB6" =>  %{        # PPT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xcDe71daaFFB6a12d584f55777D4c9e9D3c353c1E" =>  %{        # STORJ
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xD2D28530A79634423154c1FD5BDb7C1B0216cD1A" =>  %{        # MTL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xD1BBC2A68B97A8aE4b423BbF534e767Ef6275a30" =>  %{        # POWR
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xB4Ff17b5e93C40ff09326B0d538118022F02dc2b" =>  %{        # RLC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0x0702bf2aBBB53f8fEB101A71199965b891dbAE97" =>  %{        # MAPS
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        },
        "0xEe0837E18F64EC6cf3bECe2dA75a1e5f679A6D84" =>  %{        # FRM
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 0
        }
      }
    else
      # testnet
      %{
        "0x6EAdB8BA9b1054fC7D82B4129EbBEFF807852190" =>  %{       # BTC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 959415
        }
      }
    end
  end

  def handle_decimals_upgrade(token_transfers) do
    Enum.map(token_transfers, fn token_transfer ->
      upgraded_decimal_contracts_list = upgraded_decimal_contracts()
      token_contract_address_str = Address.checksum(token_transfer.token.contract_address_hash)
      old_decimals = upgraded_decimal_contracts_list[token_contract_address_str]["old_decimals"]
      upgrade_block_number = upgraded_decimal_contracts_list[token_contract_address_str]["upgrade_block_number"]

      if !is_nil(old_decimals) and token_transfer.block_number < upgrade_block_number do
        transfer_value = CurrencyHelpers.divide_decimals(token_transfer.amount, Decimal.sub(old_decimals, token_transfer.token.decimals))
        Map.put(token_transfer, :amount, Decimal.round(transfer_value, 0, :down))
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

  def handle_decimals_for_token_balance(token_balance) do
      upgraded_decimal_contracts_list = upgraded_decimal_contracts()
      %Address.CurrentTokenBalance{token: token} = token_balance
      token_contract_address_str = Address.checksum(token.contract_address_hash)
      decimals = upgraded_decimal_contracts_list[token_contract_address_str]["old_decimals"]
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
          {handle_decimals_for_token_balance(token_balance), bridged_token, token}

        token_balance ->
          handle_decimals_for_token_balance(token_balance)
      end
    end)
  end

end
