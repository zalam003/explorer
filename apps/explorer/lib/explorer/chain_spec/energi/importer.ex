defmodule Explorer.ChainSpec.Energi.EnergiImporter do
  @moduledoc """
  Imports genesis data from energi chain spec file.
  """

  require Logger

  import Ecto.Query

  alias Explorer.Repo
  alias Explorer.Chain
  alias Explorer.Chain.SmartContract
  alias Explorer.SmartContract.Solidity.CodeCompiler

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
end
