defmodule Explorer.ExchangeRates.Source do
  @moduledoc """
  Behaviour for fetching exchange rates from external sources.
  """

  alias Explorer.Chain.Hash
  alias Explorer.ExchangeRates.Source.CoinGecko
  alias Explorer.ExchangeRates.Token
  alias HTTPoison.{Error, Response}
  alias Explorer.Chain

  @doc """
  Fetches exchange rates for currencies/tokens.
  """
  @spec fetch_exchange_rates(module) :: {:ok, [Token.t()]} | {:error, any}
  def fetch_exchange_rates(source \\ exchange_rates_source()) do
    wnrg_token_address = Application.get_env(:explorer, :wnrg_token_address)
    source_url = source.source_url()
    nrg_coin_details = fetch_exchange_rates_request(source, source_url, source.headers())
    wnrg_price = fetch_token_price(wnrg_token_address)

    if(is_nil(wnrg_price)) do
      nrg_coin_details
    else
      {:ok, [nrg_details_map]} = nrg_coin_details
      wnrg_price =
        fetch_token_price(wnrg_token_address)
        |> Decimal.round(4)
      # Update usd_value of the map(fetched from Coingecko) with the price fecthed from energiswap
      {:ok, [Map.put(nrg_details_map, :usd_value, wnrg_price)]}
    end
  end

  @spec fetch_exchange_rates_for_token(String.t()) :: {:ok, [Token.t()]} | {:error, any}
  def fetch_exchange_rates_for_token(symbol) do
    source_url = CoinGecko.source_url(symbol)
    headers = CoinGecko.headers()
    fetch_exchange_rates_request(CoinGecko, source_url, headers)
  end

  @spec fetch_exchange_rates_for_token_address(String.t()) :: {:ok, [Token.t()]} | {:error, any}
  def fetch_exchange_rates_for_token_address(address_hash) do
    source_url = CoinGecko.source_url(address_hash)
    headers = CoinGecko.headers()
    fetch_exchange_rates_request(CoinGecko, source_url, headers)
  end

  @spec fetch_energiswap_exchange_rates_for_tokens() :: [any]
  def fetch_energiswap_exchange_rates_for_tokens() do
    energiswap_api_url = Application.get_env(:explorer, :energiswap_api_url)

    if(is_nil(energiswap_api_url)) do
      nil
    else
      {:ok, body} = http_request(energiswap_assets_url(), energiswap_headers())
      {:ok, result} = parse_http_success_response(body)
      result
    end
  end

  def energiswap_base_url() do
    Application.get_env(:explorer, :energiswap_api_url)
  end

  def energiswap_assets_url() do
    "#{energiswap_base_url()}/assets"
  end

  def energiswap_lp_url() do
    "#{energiswap_base_url()}/lpprices"
  end

  @spec fetch_energiswap_exchange_rates_for_lp_tokens() :: [any]
  def fetch_energiswap_exchange_rates_for_lp_tokens() do

    lp_url = energiswap_lp_url()

    if(is_nil(lp_url)) do
      nil
    else
      {:ok, body} = http_request(lp_url, energiswap_headers())
      {:ok, result} = parse_http_success_response(body)
      format_lp_tokens(result)
    end
  end

  @spec fetch_token_price(String.t()) :: [any]
  def fetch_token_price(token_address_str) do
    result = fetch_energiswap_exchange_rates_for_tokens()
    parse_token_price(result, token_address_str)
  end

  def parse_token_price(result, address_hash) do
    if(result[address_hash]) do
      to_decimal(result[address_hash]["last_price"])
    else
      nil
    end
  end

  def format_lp_tokens(tokens) do
    tokens =
      Enum.map(tokens, fn token ->
        {:ok, address_hash} = Chain.string_to_address_hash(token["id"])
        checksumed_address = Chain.Address.checksum(address_hash)
        %{
          checksumed_address => %{
          "symbol" => "#{token["token0"]["symbol"]}/#{token["token1"]["symbol"]}",
          "last_price" => token["lpPriceUSD"],
          }
        }
      end)
    for token <- tokens, {address, details} <- token, into: %{}, do: {address, details}
  end

  defp fetch_exchange_rates_request(_source, source_url) when is_nil(source_url), do: {:error, "Source URL is nil"}

  @spec fetch_token_hashes_with_market_data :: {:ok, [String.t()]} | {:error, any}
  def fetch_token_hashes_with_market_data do
    source_url = CoinGecko.source_url(:coins_list)
    headers = CoinGecko.headers()

    case http_request(source_url, headers) do
      {:ok, result} ->
        {:ok,
         result
         |> CoinGecko.format_data()}

      resp ->
        resp
    end
  end

  defp fetch_exchange_rates_request(_source, source_url, _headers) when is_nil(source_url),
    do: {:error, "Source URL is nil"}

  defp fetch_exchange_rates_request(source, source_url, headers) do
    case http_request(source_url, headers) do
      {:ok, result} when is_map(result) ->
        result_formatted =
          result
          |> source.format_data()

        {:ok, result_formatted}

      resp ->
        resp
    end
  end

  @doc """
  Callback for api's to format the data returned by their query.
  """
  @callback format_data(map() | list()) :: [any]

  @doc """
  Url for the api to query to get the market info.
  """
  @callback source_url :: String.t()

  @callback source_url(String.t()) :: String.t() | :ignore

  @callback headers :: [any]

  def headers do
    [{"Content-Type", "application/json"}]
  end

  def energiswap_headers do
    energiswap_auth_secret = Application.get_env(:explorer, :energiswap_auth_secret)
    [{"authorization_secret", energiswap_auth_secret}]
  end

  def decode_json(data) do
    Jason.decode!(data)
  rescue
    _ -> data
  end

  def to_decimal(nil), do: nil

  def to_decimal(%Decimal{} = value), do: value

  def to_decimal(value) when is_float(value) do
    Decimal.from_float(value)
  end

  def to_decimal(value) when is_integer(value) or is_binary(value) do
    Decimal.new(value)
  end

  @spec exchange_rates_source() :: module()
  defp exchange_rates_source do
    config(:source) || Explorer.ExchangeRates.Source.CoinGecko
  end

  @spec config(atom()) :: term
  defp config(key) do
    Application.get_env(:explorer, __MODULE__, [])[key]
  end

  def http_request(source_url, headers \\ headers()) do
    case HTTPoison.get(source_url, headers) do
      {:ok, %Response{body: body, status_code: 200}} ->
        parse_http_success_response(body)

      {:ok, %Response{body: body, status_code: status_code}} when status_code in 400..526 ->
        parse_http_error_response(body)

      {:ok, %Response{status_code: status_code}} when status_code in 300..308 ->
        {:error, "Source redirected"}

      {:ok, %Response{status_code: _status_code}} ->
        {:error, "Source unexpected status code"}

      {:error, %Error{reason: reason}} ->
        {:error, reason}

      {:error, :nxdomain} ->
        {:error, "Source is not responsive"}

      {:error, _} ->
        {:error, "Source unknown response"}
    end
  end

  defp parse_http_success_response(body) do
    body_json = decode_json(body)

    cond do
      is_map(body_json) ->
        {:ok, body_json}

      is_list(body_json) ->
        {:ok, body_json}

      true ->
        {:ok, body}
    end
  end

  defp parse_http_error_response(body) do
    body_json = decode_json(body)

    if is_map(body_json) do
      {:error, body_json["error"]}
    else
      {:error, body}
    end
  end
end
