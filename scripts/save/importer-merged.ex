defmodule Explorer.ChainSpec.Energi.Importer do
  @moduledoc """
  Imports genesis data from energi chain spec file.
  """

  require Logger

  import Ecto.Query

  alias EthereumJSONRPC.Blocks
  alias Explorer.Repo
  alias Explorer.Chain
  alias Explorer.Chain.SmartContract
  alias Explorer.SmartContract.Solidity.CodeCompiler
  alias Explorer.Chain.Hash.Address, as: AddressHash

  def import_genesis_accounts(chain_spec) do
    balance_params =
      chain_spec
      |> genesis_accounts()
      |> Stream.map(fn balance_map ->
        Map.put(balance_map, :block_number, 0)
      end)
      |> Enum.to_list()

    json_rpc_named_arguments = Application.get_env(:explorer, :json_rpc_named_arguments)

    {:ok, %Blocks{blocks_params: [%{timestamp: timestamp}]}} =
      EthereumJSONRPC.fetch_blocks_by_range(1..1, json_rpc_named_arguments)

    day = DateTime.to_date(timestamp)

    balance_daily_params =
      chain_spec
      |> genesis_accounts()
      |> Stream.map(fn balance_map ->
        Map.put(balance_map, :day, day)
      end)
      |> Enum.to_list()

    address_params =
      balance_params
      |> Stream.map(fn %{address_hash: hash} = map ->
        Map.put(map, :hash, hash)
      end)
      |> Enum.to_list()

    params = %{
      address_coin_balances: %{params: balance_params},
      address_coin_balances_daily: %{params: balance_daily_params},
      addresses: %{params: address_params}
    }

    Chain.import(params)
  end

  def genesis_accounts(%{"genesis" => genesis}) do
    genesis_accounts(genesis)
  end

  def genesis_accounts(chain_spec) do
    accounts = chain_spec["alloc"]

    if accounts do
      parse_accounts(accounts)
    else
      Logger.warn(fn -> "No accounts are defined in genesis" end)

      []
    end
  end

  defp parse_accounts(accounts) do
    accounts
    |> Stream.filter(fn {_address, map} ->
      !is_nil(map["balance"])
    end)
    |> Stream.map(fn {address, %{"balance" => value} = params} ->
      formatted_address = if String.starts_with?(address, "0x"), do: address, else: "0x" <> address
      {:ok, address_hash} = AddressHash.cast(formatted_address)
      balance = parse_number(value)

      code = params["code"]

      %{address_hash: address_hash, value: balance, contract_code: code}
    end)
    |> Enum.to_list()
  end

  def import_genesis_smart_contracts(chain_spec) do
    genesis_contracts_params = chain_spec["genesis_contracts_params"]
    if genesis_contracts_params do
      Logger.info(fn -> "Verifying Energi genesis smart contracts ..." end)
      verify_contracts(genesis_contracts_params)
      Logger.info(fn -> "Done verifying Energi genesis smart contracts" end)
    else
      Logger.warn(fn -> "No genesis smart contracts are defined in chain spec" end)
      []
    end
  end

  def verify_contracts (contracts_params) do
    contracts_params
    |> Stream.filter(fn {_contract, map} ->
      !is_nil(map["address"])
      && !is_nil(map["name"])
      && !is_nil(map["compiler_version"])
      && !is_nil(map["evm_version"])
      && !is_nil(map["optimization_runs"])
      && !is_nil(map["optimization"])
      && !is_nil(map["contract_source_code"])
      && !is_nil(map["constructor_arguments"])
      && !is_nil(map["external_libraries"])
      && !is_nil(map["abi"])
    end)
    |> Stream.map(fn {contract_name,
         %{"address" => address_hash,
           "name" => name,
           "compiler_version" => compiler_version,
           "evm_version" => evm_version,
           "optimization_runs" => optimization_runs,
           "optimization" => optimization,
           "contract_source_code" => contract_source_code,
           "constructor_arguments" => constructor_arguments,
           "abi" => abi,
           "external_libraries" => external_libraries
         }} ->

      # Checking if contract is already registered
      query =
        from(
          contract in SmartContract,
          where: contract.address_hash == ^address_hash,
          select: contract
        )

      case Repo.one(query) do
        nil -> case CodeCompiler.run(
                      name: name,
                      compiler_version: compiler_version,
                      code: contract_source_code,
                      optimize: optimization,
                      optimization_runs: optimization_runs,
                      evm_version: evm_version,
                      external_libs: external_libraries
                    ) do

                 {:ok, %{"abi" => _contract_abi, "bytecode" => contract_bytecode}} ->

                   Logger.info("Compiled genesis smart contract " <> contract_name)

                   case Chain.create_genesis_smart_contract(%{address_hash: address_hash,
                     name: contract_name,
                     compiler_version: compiler_version,
                     evm_version: evm_version,
                     optimization_runs: optimization_runs,
                     optimization: optimization,
                     contract_source_code: contract_source_code,
                     contract_bytecode: contract_bytecode,
                     constructor_arguments: constructor_arguments,
                     external_libraries: external_libraries,
                     abi: abi # Inserting abi as defined in chain spec (need abi of latest implementation for proxy contracts)
                   }, []) do

                     {:ok, _smart_contract} -> {:ok, "Registered genesis smart contract " <> contract_name}

                     {:error, error} -> {:error, "Error registering genesis smart contract " <> contract_name <> "\n" <> error}

                   end

                 _ -> {:error, "Error compiling genesis smart contract " <> contract_name}

               end

        _ -> {:ok, "Genesis smart contract " <> contract_name <> " already registered"}
      end
    end)
    |> Enum.map(fn result ->
        case result do
          {:error, error} -> Logger.error(fn -> error end)
          {:ok, message} -> Logger.info(fn -> message end)
          _ -> Logger.error(fn -> "Error verifying Energi genesis smart contracts " end)
        end
      end)
  end

  defp parse_number("0x" <> hex_number) do
    {number, ""} = Integer.parse(hex_number, 16)

    number
  end

  defp parse_number(""), do: 0

  defp parse_number(string_number) do
    {number, ""} = Integer.parse(string_number, 10)

    number
  end
end