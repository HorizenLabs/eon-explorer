defmodule Explorer.ExchangeRates.Source do
  @moduledoc """
  Behaviour for fetching exchange rates from external sources.
  """

  alias Explorer.Chain.Hash
  alias Explorer.ExchangeRates.Source.CoinGecko
  alias Explorer.ExchangeRates.Token
  alias Explorer.{ExchangeRates, Repo}
  alias HTTPoison.{Error, Response}

  @doc """
  Fetches exchange rates for currencies/tokens.
  """
  @spec fetch_exchange_rates(module) :: {:ok, [Token.t()]} | {:error, any}
  def fetch_exchange_rates(source \\ exchange_rates_source()) do
    source_url = source.source_url()
    fetch_exchange_rates_request(source, source_url, source.headers())
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

  @spec fetch_market_data_for_token_addresses([Hash.Address.t()]) ::
          {:ok, %{Hash.Address.t() => %{fiat_value: float() | nil, circulating_market_cap: float() | nil}}}
          | {:error, any}
  def fetch_market_data_for_token_addresses(address_hashes) do
    source_url = CoinGecko.source_url(address_hashes)
    headers = CoinGecko.headers()
    fetch_exchange_rates_request(CoinGecko, source_url, headers)
  end

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

  defp remove_market_cap_if_certain_token(value, address) do
    if address in ["0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab", "0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7"] do
      Map.delete(value, "usd_market_cap")
    else
      value
    end
  end

  defp swap_address(result, original_address, new_address) do
    case Map.has_key?(result, original_address) do
      true ->
        {value, remaining_result} = Map.pop(result, original_address)
        value_updated = remove_market_cap_if_certain_token(value, original_address)
        Map.put(remaining_result, new_address, value_updated)

      false ->
        result
    end
  end

  @spec get_exchange_rate(String.t()) :: Token.t() | nil
  defp get_exchange_rate(symbol) do
    ExchangeRates.lookup(symbol)
  end

  defp update_result_addresses(result) do

    result
    |> swap_address("0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab", "0x2c2E0B0c643aB9ad03adBe9140627A645E99E054") # weth
    |> swap_address("0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7", "0x6318374DFb468113E06d3463ec5Ed0B6Ae0F0982") # wrapped-avax
    |> swap_address("0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e", "0xCc44eB064CD32AAfEEb2ebb2a47bE0B882383b53") # usd-coin
    |> swap_address("0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7", "0xA167bcAb6791304EDa9B636C8beEC75b3D2829E6") # tether
    |> swap_address("0xd586e7f844cea2f87f50152665bcbc2c279d8d70", "0x38C2a6953F86a7453622B1E7103b738239728754") # dai
    |> swap_address("0x5947bb275c521040051d82396192181b413227a3", "0xDF8DBA35962Aa0fAD7ade0Df07501c54Ec7c4A89") # chainlink
    |> swap_address("0x50b7545627a5162f82a992c33b87adc75187b218", "0x1d7fb99AED3C365B4DEf061B7978CE5055Dfc1e7") # wrapped-bitcoin

    zen_exchange_rate = get_exchange_rate("ZEN")
    zen_usd_value = case zen_exchange_rate do %Explorer.ExchangeRates.Token{usd_value: uv} -> uv; _ -> nil end
    zen_map = %{"0xF5cB8652a84329A2016A386206761f455bCEDab6" => %{"usd" => zen_usd_value}}
    merged_result = Map.merge(result, zen_map)
    merged_result

  end


  defp fetch_exchange_rates_request(_source, source_url, _headers) when is_nil(source_url),
    do: {:error, "Source URL is nil"}

  defp fetch_exchange_rates_request(source, source_url, headers) do
    case http_request(source_url, headers) do
      {:ok, result} when is_map(result) ->

        result_updated_and_formatted =
        result
        |> update_result_addresses()
        |> source.format_data()
        {:ok, result_updated_and_formatted}

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

  def http_request(source_url, additional_headers) do
    case HTTPoison.get(source_url, headers() ++ additional_headers) do
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
