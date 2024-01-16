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

  # --------------------------------------------------------------------------------------------------------------------------------------------------------
  # retrieve from the pairs <external platform token address> - <eon token address> from the environment
  @token_address_pairs "TOKEN_ADDRESS_PAIRS_EXT_PLATFORM_EON"
  def fetch_token_address_pairs_for_swap do
    token_list = System.fetch_env!(@token_address_pairs)
    parse_token_list(token_list)
  end

  defp parse_token_list(token_list) do
    token_pairs =
      token_list
      |> String.split(",")
      |> Enum.map(&parse_token_pair/1)

    Map.new(token_pairs)
  end

  defp parse_token_pair(token_pair) do
    [name, address] = String.split(token_pair, "_")
    {name, address}
  end

  # --------------------------------------------------------------------------------
  # swap the addresses
  defp swap_addresses(result_map, address_mapping) do
    Enum.reduce(address_mapping, %{}, fn {old_address, new_address}, acc ->
      swap_addresses(result_map, old_address, new_address, acc)
    end)
  end

  defp swap_addresses(result_map, old_address, new_address, acc) do
    old_value = Map.get(result_map, old_address)
    updated_value = remove_zero_market_cap(old_value)
    Map.put(acc, new_address, updated_value)
  end

  defp remove_zero_market_cap(map) do
    case Map.get(map, "usd_market_cap") do
      0.0 -> Map.delete(map, "usd_market_cap")
      _ -> map
    end
  end

  # --------------------------------------------------------------------------------
  # retrieve the ZEN exchange rate from the database
  @spec get_exchange_rate(String.t()) :: Token.t() | nil
  defp get_exchange_rate(symbol) do
    ExchangeRates.lookup(symbol)
  end

  # --------------------------------------------------------------------------------
  # add the wrapped-zen map with the exchange rate read from the database
  # convert it to float (with 2 decimal places) before put it in the map
  @wrapped_zen_env_var "WRAPPED_ZEN_ADDRESS"
  defp create_wrapped_zen_map do
    zen_exchange_rate = get_exchange_rate(Explorer.coin())
    zen_usd_value =
      case zen_exchange_rate do
        %Explorer.ExchangeRates.Token{usd_value: uv} -> uv
        _ -> nil
      end
    zen_usd_value_float = Float.round(Decimal.to_float(zen_usd_value), 2)
    %{System.get_env(@wrapped_zen_env_var) => %{"usd" => zen_usd_value_float}}
  end

  # --------------------------------------------------------------------------------
  @external_platform "EXT_PLATFORM_FOR_TOKEN_FETCH"

  # --------------------------------------------------------------------------------------------------------------------------------------------------------

  @doc """
  In the update_result_addresses method if the response processes id the one from the token_price api (v3/simple/token_price/<platform>) the addresses will
  be swapped with their horizen-eon counterpart (using the TOKEN_ADDRESS_PAIRS_EXT_PLATFORM_EON environment variable)
  Moreover the ZEN exchange rate is retrieved and an entry related to the wrapped-zen token is added to the result map
  """
  defp update_result_addresses(result, source_url) do

    case {System.get_env(@external_platform), String.contains?(source_url, "/simple/token_price/" <> System.get_env(@external_platform))} do
      {_, true} ->
        # retrieve token address pairs between the external platform used and the eon sidechain
        token_address_pairs_for_swap = fetch_token_address_pairs_for_swap()

        # swap v3/simple/token_price/<platform> results addresses
        swapped_result = swap_addresses(result, token_address_pairs_for_swap)

        if System.get_env(@wrapped_zen_env_var) do
          # retrieve ZEN exchange rate, associated it to the wrapped-zen token address and map it to the result map
          wrapped_zen_map = create_wrapped_zen_map()
          merged_result = Map.merge(swapped_result, wrapped_zen_map)
          merged_result

        else
          swapped_result
        end

      _ ->
        # if the response is not from the v3/simple/token_price/<platform> api return the input result unchanged
        result

    end

  end


  defp fetch_exchange_rates_request(_source, source_url, _headers) when is_nil(source_url),
    do: {:error, "Source URL is nil"}

  defp fetch_exchange_rates_request(source, source_url, headers) do
    case http_request(source_url, headers) do
      {:ok, result} when is_map(result) ->

        result_updated_and_formatted =
        result
        |> update_result_addresses(source_url)
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
