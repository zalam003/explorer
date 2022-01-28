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
          "upgrade_block_number" => 989106
        },
        "0xdf13537f5a8c697bdeCB4870B249a1a9158b54c6" =>  %{        # CRO
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x1b53c0662414B195FcD5802C09754765b930A312" =>  %{        # CEL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xe59028425E3D3Cb0B9F71F9E18345bE517364d91" =>  %{        # ZIL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xad3EaC6a2EF827833880a10592C6E46605E4F9d6" =>  %{        # VGX
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x5666444647f4fD66DECF411D69f994B8244EbeE3" =>  %{        # CHSB
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x827c3f7FFa144598144F1E10ec9E157B5a0ABA18" =>  %{        # SCRT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x5E2D55bC07B63b18Af6C9ED8Da06CD33258ebb35" =>  %{        # ORN
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x79786Ed8a70ccEC6C7A31debC7FeFc5119f9dc95" =>  %{        # AMPL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x04cd06cf05b816F09395375f0143584B4A95eA9f" =>  %{        # FUN
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xE3D7a5C28d5a4143831242E8ab218D7e9B5c2c87" =>  %{        # UBT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x0d91d554768dC20E1D3D95FF9d5bC041edC3bA0f" =>  %{        # CVC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x83AF4137Ed450F4765A72831Dd938B5203f5d2Fb" =>  %{        # SRM
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x96717283E442FfCE9b636f004C196517a72eE4cA" =>  %{        # AION
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x2483a716A4A5476da5E657be13A37Cf62b608AB6" =>  %{        # PPT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xcDe71daaFFB6a12d584f55777D4c9e9D3c353c1E" =>  %{        # STORJ
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xD2D28530A79634423154c1FD5BDb7C1B0216cD1A" =>  %{        # MTL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xD1BBC2A68B97A8aE4b423BbF534e767Ef6275a30" =>  %{        # POWR
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xB4Ff17b5e93C40ff09326B0d538118022F02dc2b" =>  %{        # RLC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x0702bf2aBBB53f8fEB101A71199965b891dbAE97" =>  %{        # MAPS
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0xEe0837E18F64EC6cf3bECe2dA75a1e5f679A6D84" =>  %{        # FRM
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        },
        "0x0894840ba7d57c7Adf2cAf8fd3c41Eb79AF5B8e7" =>  %{        # WRX
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 989106
        }
      }
    else
      # testnet
      %{
        "0x6EAdB8BA9b1054fC7D82B4129EbBEFF807852190" =>  %{        # BTC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 959415
        },
        "0x582A1b770465F838bEc408b19aAd609E7645d70a" =>  %{        # CRO
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x573CAF5D46BC0273985C68e2512DE063C6B68E8F" =>  %{        # CEL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0xCDEabF84ECa4B1bcb596b3DB78f478bfae986D27" =>  %{        # ZIL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x7f2626377a4f77b1Ac8241096E4E540214dE894a" =>  %{        # VGX
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0xA2962DCC41b4a6bF6eE121f5581C43b1C4cF37F5" =>  %{        # CHSB
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0xf32ad72B317CaEBE7Cf977C4c8e0466DCEeF4595" =>  %{        # SCRT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0xB445423563c24CF04DD1c7b176Af3326d3De9EF2" =>  %{        # ORN
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x943378aCE4a9F6a85BbacE950A288E8A1E4b51Fb" =>  %{        # AMPL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x1D5D8F5C820f05128709EC1a423Fb6700326c45F" =>  %{        # FUN
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0xF078abE9Af3202952172d78830509757c099EDa3" =>  %{        # UBT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x3766Ad5E3294f857bb99588f6227C229123cFa7C" =>  %{        # CVC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x03fA58cfce1A46CE326505c4304ABbD7b0a65a5D" =>  %{        # SRM
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0xA0A37314971c992F970dd8B2B1ee9494349C0B1e" =>  %{        # AION
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x978613EEe42f1808ED6dF68E0Fa13A6649a075c9" =>  %{        # PPT
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x81A39E1Ad6F8F1fD67E2a726e986953122B1CafB" =>  %{        # STORJ
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0xd4F16Fbc222C3Da193E5f3e67aae63A008EFcF92" =>  %{        # MTL
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x4b9e624C7ae53da783d83AC0FAF56775e778F6A2" =>  %{        # POWR
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x1DaCA316cbd6992A029147f8fc92A0Dd715E62B2" =>  %{        # RLC
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x9a70c5867eb344E093eB13eeE9283Df37211CC23" =>  %{        # MAPS
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
        },
        "0x4ed322A3eCC527C7703785c57Cd05137D3eDDDC1" =>  %{        # FRM
          "old_decimals" => Decimal.new(18),
          "upgrade_block_number" => 1002853
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
