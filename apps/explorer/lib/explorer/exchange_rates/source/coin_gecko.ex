defmodule Explorer.ExchangeRates.Source.CoinGecko do
  @moduledoc """
  Adapter for fetching exchange rates from https://coingecko.com
  """

  alias Explorer.Chain
  alias Explorer.ExchangeRates.{Source, Token}

  import Source, only: [to_decimal: 1]

  @behaviour Source

  @impl Source
  def format_data(%{"market_data" => _} = json_data) do
    market_data = json_data["market_data"]

    last_updated = get_last_updated(market_data)
    current_price = get_current_price(market_data)

    id = json_data["id"]

    btc_value =
      if Application.get_env(:explorer, Explorer.ExchangeRates)[:fetch_btc_value], do: get_btc_value(id, market_data)

    circulating_supply_data = market_data && market_data["circulating_supply"]
    total_supply_data = market_data && market_data["total_supply"]
    market_cap_data_usd = market_data && market_data["market_cap"] && market_data["market_cap"]["usd"]
    total_volume_data_usd = market_data && market_data["total_volume"] && market_data["total_volume"]["usd"]

    [
      %Token{
        available_supply: to_decimal(circulating_supply_data),
        total_supply: to_decimal(total_supply_data) || to_decimal(circulating_supply_data),
        btc_value: btc_value,
        id: id,
        last_updated: last_updated,
        market_cap_usd: to_decimal(market_cap_data_usd),
        name: json_data["name"],
        symbol: String.upcase(json_data["symbol"]),
        usd_value: current_price,
        volume_24h_usd: to_decimal(total_volume_data_usd)
      }
    ]
  end

  @impl Source
  def format_data(%{} = market_data_for_tokens) do
    currency = currency()
    market_cap = currency <> "_market_cap"

    market_data_for_tokens
    |> Enum.reduce(%{}, fn
      {address_hash_string, market_data}, acc ->
        case Explorer.Chain.Hash.Address.cast(address_hash_string) do
          {:ok, address_hash} ->
            acc
            |> Map.put(address_hash, %{
              fiat_value: Map.get(market_data, currency),
              circulating_market_cap: Map.get(market_data, market_cap)
            })

          _ ->
            acc
        end

      _, acc ->
        acc
    end)
  end

  # --------------------------------------------------------------------------------------------------------------------------------------------------------
  # retrieve, if present, the list of wrapped token addreses from the environment and update the response map
  @eon_token_list_env_var "HORIZEN_EON_TOKEN_LIST_TO_FETCH"
  defp add_wrapped_tokens(supported_coins) do
    wrapped_tokens_list_var = System.get_env(@eon_token_list_env_var)

    case wrapped_tokens_list_var do
      nil ->
        supported_coins
      _ ->
        # token map is the one read from the environment
        wrapped_token_list = parse_token_list(wrapped_tokens_list_var)
        # update the supported_coins response
        update_supported_coins(supported_coins, wrapped_token_list)
    end
  end

  defp parse_token_list(token_list) do
    token_pairs =
      token_list
      |> String.split(",")
      |> Enum.map(&parse_token_pair_id_address/1)

    Map.new(token_pairs)
  end

  defp parse_token_pair_id_address(token_pair) do
    [name, address] = String.split(token_pair, "_")
    {name, address}
  end

  # --------------------------------------------------------------------------------
  # update the response of the api/v3/coins/list api with the addresses of our sidechain
  def update_supported_coins(supported_coins, token_list) do
    Enum.map(supported_coins, &update_coin(&1, token_list))
  end

  defp update_coin(%{"id" => coin_id, "platforms" => platforms} = coin, token_list) do
    case Map.get(token_list, coin_id) do
      nil -> coin
      token ->
        updated_platforms = Map.put_new(platforms, "horizen-eon", token)
        Map.put(coin, "platforms", updated_platforms)
    end
  end

  # --------------------------------------------------------------------------------
  # retrieve, if present, the wrapped-zen address from the environment and update the response map
  @wrapped_zen_env_var "WRAPPED_ZEN_ADDRESS"
  defp add_wrapped_zen(supported_coins) do
    wrapped_zen_address = System.get_env(@wrapped_zen_env_var)

    case wrapped_zen_address do
      nil ->
        supported_coins
      _ ->
        wrapped_zen = %{
          "id" => "wrapped-zen",
          "platforms" => %{
            "horizen-eon" => wrapped_zen_address
          }
        }
        [wrapped_zen | supported_coins]
    end
  end

  # --------------------------------------------------------------------------------------------------------------------------------------------------------

  @doc """
  In the format_data method the wrapped token addresses will be retrieved from the environemnt variable HORIZEN_EON_TOKEN_LIST_TO_FETCH, formatted and added
  to the response of the coingecko api/v3/coins/list api (triggered by the token_exchange_rate module).
  Moreover we retrieve from the environment the variable WRAPPED_ZEN_ADDRESS, if present it contains the address of the wrapped-zen token and a new entry
  with id wrapped-zen is added since it is not present in the api response.
  These addresses will find match in the one currently present in the sidechain and they will be put in the state variable tokens_to_fetch of the module
  token_exchange_rate. A tokens_to_fetch variable not empty will trigger a call to the coingecko v3/simple/token_price/<platform> to retrieve the wrapped
  token prices and market cap.
  """
  @impl Source
  def format_data(supported_coins) when is_list(supported_coins) do

    # overwrite the platform used with horizen-eon
    platform = "horizen-eon"

    # add the wrapped tokens if present, reading them from the HORIZEN_EON_TOKEN_LIST_TO_FETCH env variable
    supported_coins = add_wrapped_tokens(supported_coins)

    # add the new entry for wrapped-zen if present
    supported_coins = add_wrapped_zen(supported_coins)

    supported_coins
    |> Enum.reduce([], fn
      %{"platforms" => %{^platform => token_contract_hash_str}}, acc ->
        case Chain.Hash.Address.cast(token_contract_hash_str) do
          {:ok, token_contract_hash} -> [token_contract_hash | acc]
          _ -> acc
        end

      _, acc ->
        acc
    end)
  end

  @impl Source
  def format_data(_), do: []

  @impl Source
  def source_url do
    explicit_coin_id = config(:coin_id)

    {:ok, id} =
      if explicit_coin_id do
        {:ok, explicit_coin_id}
      else
        case coin_id() do
          {:ok, id} ->
            {:ok, id}

          _ ->
            {:ok, nil}
        end
      end

    if id, do: "#{base_url()}/coins/#{id}", else: nil
  end

  @impl Source
  def source_url(:coins_list) do
    "#{base_url()}/coins/list?include_platform=true"
  end

  # --------------------------------------------------------------------------------------------------------------------------------------------------------
  # retrieve from the list of external platform token addresses from the environment
  @token_address_pairs "TOKEN_ADDRESS_PAIRS_EXT_PLATFORM_EON"
  @external_platform "EXT_PLATFORM_FOR_TOKEN_FETCH"

  defp fetch_external_platform_token_addresses do
    token_list = System.fetch_env!(@token_address_pairs)
    parse_ext_platform_token_list(token_list)
  end

  defp parse_ext_platform_token_list(input) do
    input
    |> String.split(",")
    |> Enum.map(&parse_left_element/1)
    |> Enum.join(",")
  end

  defp parse_left_element(element) do
    [left, _right] = String.split(element, "_")
    left
  end

  # --------------------------------------------------------------------------------------------------------------------------------------------------------

  @doc """
  The v3/simple/token_price/<platform> will be performed to the external platform defined in the EXT_PLATFORM_FOR_TOKEN_FETCH environment variable and using
  the list of token addresses of the external platform (read from the environment as well using the TOKEN_ADDRESS_PAIRS_EXT_PLATFORM_EON variable)
  """
  @impl Source
  def source_url(token_addresses) when is_list(token_addresses) do

    platform = System.fetch_env!(@external_platform)
    joined_addresses = fetch_external_platform_token_addresses()

    "#{base_url()}/simple/token_price/#{platform}?vs_currencies=#{currency()}&include_market_cap=true&contract_addresses=#{joined_addresses}"
  end

  @impl Source
  def source_url(input) do
    case Chain.Hash.Address.cast(input) do
      {:ok, _} ->
        address_hash_str = input
        "#{base_url()}/coins/#{platform()}/contract/#{address_hash_str}"

      _ ->
        symbol = input

        id =
          case coin_id(symbol) do
            {:ok, id} ->
              id

            _ ->
              nil
          end

        if id, do: "#{base_url()}/coins/#{id}", else: nil
    end
  end

  @impl Source
  def headers do
    if api_key() do
      [{"X-Cg-Pro-Api-Key", "#{api_key()}"}]
    else
      []
    end
  end

  defp api_key do
    config(:api_key) || nil
  end

  def coin_id do
    symbol = String.downcase(Explorer.coin())

    coin_id(symbol)
  end

  def coin_id(symbol) do
    id_mapping = token_symbol_to_id_mapping_to_get_price(symbol)

    if id_mapping do
      {:ok, id_mapping}
    else
      url = "#{base_url()}/coins/list"

      symbol_downcase = String.downcase(symbol)

      case Source.http_request(url, headers()) do
        {:ok, data} ->
          get_symbol_data(data, symbol_downcase)

        resp ->
          resp
      end
    end
  end

  defp get_symbol_data(data, symbol_downcase) do
    if is_list(data) do
      symbol_data = find_symbol_data(data, symbol_downcase)

      process_symbol_data(symbol_data)
    else
      {:ok, data}
    end
  end

  defp find_symbol_data(data, symbol_downcase) do
    Enum.find(data, fn item ->
      item["symbol"] == symbol_downcase
    end)
  end

  defp process_symbol_data(symbol_data) do
    if symbol_data do
      {:ok, symbol_data["id"]}
    else
      {:error, :not_found}
    end
  end

  defp get_last_updated(market_data) do
    last_updated_data = market_data && market_data["last_updated"]

    if last_updated_data do
      {:ok, last_updated, 0} = DateTime.from_iso8601(last_updated_data)
      last_updated
    else
      nil
    end
  end

  defp get_current_price(market_data) do
    if market_data["current_price"] do
      to_decimal(market_data["current_price"]["usd"])
    else
      1
    end
  end

  defp get_btc_value(id, market_data) do
    case get_btc_price() do
      {:ok, price} ->
        btc_price = to_decimal(price)
        current_price = get_current_price(market_data)

        if id != "btc" && current_price && btc_price do
          Decimal.div(current_price, btc_price)
        else
          1
        end

      _ ->
        1
    end
  end

  defp platform do
    config(:platform) || "ethereum"
  end

  defp currency do
    config(:currency) || "usd"
  end

  defp base_url do
    if api_key() do
      base_pro_url()
    else
      base_free_url()
    end
  end

  defp base_free_url do
    config(:base_url) || "https://api.coingecko.com/api/v3"
  end

  defp base_pro_url do
    config(:base_pro_url) || "https://pro-api.coingecko.com/api/v3"
  end

  defp get_btc_price(currency \\ "usd") do
    url = "#{base_url()}/exchange_rates"

    case Source.http_request(url, headers()) do
      {:ok, data} = resp ->
        if is_map(data) do
          current_price = data["rates"][currency]["value"]

          {:ok, current_price}
        else
          resp
        end

      resp ->
        resp
    end
  end

  @spec config(atom()) :: term
  defp config(key) do
    Application.get_env(:explorer, __MODULE__, [])[key]
  end

  defp token_symbol_to_id_mapping_to_get_price(symbol) do
    case symbol do
      "UNI" -> "uniswap"
      "SURF" -> "surf-finance"
      _symbol -> nil
    end
  end
end
