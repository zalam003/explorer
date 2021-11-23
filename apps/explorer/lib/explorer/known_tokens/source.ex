defmodule Explorer.KnownTokens.Source do
  @moduledoc """
  Behaviour for fetching list of known tokens.
  """

  alias Explorer.Chain.Hash
  alias Explorer.ExchangeRates.Source

  @doc """
  Fetches known tokens
  """
  @spec fetch_known_tokens() :: {:ok, [Hash.Address.t()]} | {:error, any}
  def fetch_known_tokens(_source \\ known_tokens_source()) do
    known_tokens = Source.fetch_energiswap_exchange_rates_for_tokens()
    # NOTE: The token symbol stored in DB must match the symbol received from the Energiswap API response
    # Parse Energiswap API response
    parsed_known_token =
      Enum.map(known_tokens, fn ({k, v}) ->
        %{
          "address"=> k,
          "symbol"=> v["symbol"],
          "type"=> "default"
        }
        end
      )
    {:ok, parsed_known_token }
  end

  @doc """
  Url for querying the list of known tokens.
  """
  @callback source_url() :: String.t()

  @spec known_tokens_source() :: module()
  defp known_tokens_source do
    config(:source) || Explorer.KnownTokens.Source.EnergiSwap
  end

  @spec config(atom()) :: term
  defp config(key) do
    Application.get_env(:explorer, __MODULE__, [])[key]
  end
end
