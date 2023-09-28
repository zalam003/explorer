defmodule Explorer.Market do
  @moduledoc """
  Context for data related to the cryptocurrency market.
  """

  alias Explorer.ExchangeRates.Token
  alias Explorer.Market.{MarketHistory, MarketHistoryCache}
  alias Explorer.{ExchangeRates, KnownTokens, Repo}
  alias Explorer.Chain.Address
  alias Explorer.Chain.Cache.TokenExchangeRate

  @doc """
  Get most recent exchange rate for the given symbol.
  """
  @spec get_exchange_rate(String.t()) :: Token.t() | nil
  def get_exchange_rate(symbol) do
    ExchangeRates.lookup(symbol)
  end

  @doc """
  Get the address of the token with the given symbol.
  """
  @spec get_known_address(String.t()) :: Hash.Address.t() | nil
  def get_known_address(symbol) do
    case KnownTokens.lookup(symbol) do
      {:ok, address} -> address
      nil -> nil
    end
  end

  @doc """
  Retrieves the history for the recent specified amount of days.

  Today's date is include as part of the day count
  """
  @spec fetch_recent_history() :: [MarketHistory.t()]
  def fetch_recent_history do
    MarketHistoryCache.fetch()
  end

  @doc """
  Retrieves today's native coin exchange rate from the database.
  """
  @spec get_native_coin_exchange_rate_from_db() :: Token.t()
  def get_native_coin_exchange_rate_from_db do
    today =
      case fetch_recent_history() do
        [today | _the_rest] -> today
        _ -> nil
      end

    if today do
      %Token{
        usd_value: Map.get(today, :closing_price),
        market_cap_usd: Map.get(today, :market_cap),
        available_supply: nil,
        total_supply: nil,
        btc_value: nil,
        id: nil,
        last_updated: nil,
        name: nil,
        symbol: nil,
        volume_24h_usd: nil
      }
    else
      Token.null()
    end
  end

  @doc """
  Get most recent exchange rate for the native coin from ETS or from DB.
  """
  @spec get_coin_exchange_rate() :: Token.t() | nil
  def get_coin_exchange_rate do
    get_exchange_rate(Explorer.coin()) || get_native_coin_exchange_rate_from_db() || Token.null()
  end

  @doc false
  def bulk_insert_history(records) do
    records_without_zeroes =
      records
      |> Enum.reject(fn item ->
        Map.has_key?(item, :opening_price) && Map.has_key?(item, :closing_price) &&
          Decimal.equal?(item.closing_price, 0) &&
          Decimal.equal?(item.opening_price, 0)
      end)
      # Enforce MarketHistory ShareLocks order (see docs: sharelocks.md)
      |> Enum.sort_by(& &1.date)

    Repo.insert_all(MarketHistory, records_without_zeroes, on_conflict: :nothing, conflict_target: [:date])
  end

  def get_price(token) do
    energiswap_api_url = Application.get_env(:explorer, :energiswap_api_url)

      if(!is_nil(energiswap_api_url)) do
        TokenExchangeRate.fetch(token.contract_address_hash, Address.checksum(token.contract_address_hash))
      end
  end

  def add_price(%{symbol: _symbol} = token) do
    checksummed_contract_address = Address.checksum(token.contract_address_hash)
    known_address = KnownTokens.lookup_from_address(checksummed_contract_address)

    mnrg_token_address = Application.get_env(:explorer, :mnrg_token_address)
    mnrg_token = checksummed_contract_address == mnrg_token_address

    usd_value =
      cond do
        known_address ->
          get_price(token)

        mnrg_token ->
          nrg_price = get_exchange_rate(Explorer.coin())
          nrg_price.usd_value

        bridged_token = mainnet_bridged_token?(token) ->
          TokenBridge.get_current_price_for_bridged_token(
            token.contract_address_hash,
            bridged_token.foreign_token_contract_address_hash
          )
        true ->
          nil
      end
    Map.put(token, :usd_value, usd_value)
  end

  def add_price(%CurrentTokenBalance{token: token} = token_balance) do
    token_with_price = add_price(token)

    Map.put(token_balance, :token, token_with_price)
  end

  def add_price(tokens) when is_list(tokens) do
    Enum.map(tokens, fn item ->
      case item do
        {token_balance, bridged_token, token} ->
          {add_price(token_balance), bridged_token, token}

        token_balance ->
          add_price(token_balance)
      end
    end)
  end

  defp mainnet_bridged_token?(token) do
    bridged_prop = Map.get(token, :bridged) || nil

    if bridged_prop do
      bridged_token = Repo.get_by(BridgedToken, home_token_contract_address_hash: token.contract_address_hash)

      if bridged_token do
        if bridged_token.foreign_chain_id do
          if Decimal.cmp(bridged_token.foreign_chain_id, Decimal.new(1)) == :eq, do: bridged_token, else: false
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end
end
