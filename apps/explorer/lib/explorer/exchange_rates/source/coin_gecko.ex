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

  def add_token_address_for_platform(data, id, platform, value) do
    Enum.map(data, fn entry ->
      if entry["id"] == id do
        %{
          entry | "platforms" => Map.put(entry["platforms"], platform, value)
        }
      else
        entry
      end
    end)
  end

  defp add_wrapped_zen(supported_coins) do
    wrapped_zen = %{
      "id" => "wrapped-zen",
      "platforms" => %{
        "horizen-eon" => "0xF5cB8652a84329A2016A386206761f455bCEDab6"
      }
    }
    [wrapped_zen | supported_coins]
  end

  @doc """
  In the format_data method the wrapped token addresses will be added to the response of the coingecko api/v3/coins/list api (triggered by the token_exchange_rate module)
  Moreover a new entry with id wrapped-zen is added since it is not present in the api response
  These addresses will find match in the one currently present in the sidechain and they will put in the state variable tokens_to_fetch of the module token_exchange_rate
  A tokens_to_fetch variable not empty will trigger a call to the coingecko v3/simple/token_price/<platform> to retrieve the wrapped token prices and market cap
  """
  @impl Source
  def format_data(supported_coins) when is_list(supported_coins) do

    #platform = platform()
    platform = "horizen-eon"
    supported_coins_updated =
      supported_coins
      |> add_token_address_for_platform("weth", "horizen-eon", "0x2c2E0B0c643aB9ad03adBe9140627A645E99E054")
      |> add_token_address_for_platform("wrapped-avax", "horizen-eon", "0x6318374DFb468113E06d3463ec5Ed0B6Ae0F0982")
      |> add_token_address_for_platform("usd-coin", "horizen-eon", "0xCc44eB064CD32AAfEEb2ebb2a47bE0B882383b53")
      |> add_token_address_for_platform("tether", "horizen-eon", "0xA167bcAb6791304EDa9B636C8beEC75b3D2829E6")
      |> add_token_address_for_platform("dai", "horizen-eon", "0x38C2a6953F86a7453622B1E7103b738239728754")
      |> add_token_address_for_platform("chainlink", "horizen-eon", "0xDF8DBA35962Aa0fAD7ade0Df07501c54Ec7c4A89")
      |> add_token_address_for_platform("wrapped-bitcoin", "horizen-eon", "0x1d7fb99AED3C365B4DEf061B7978CE5055Dfc1e7")

    # Add the new entry for wrapped-zen
    supported_coins_updated = add_wrapped_zen(supported_coins_updated)

    supported_coins_updated
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

  @doc """
  The v3/simple/token_price/<platform> will be performed to the avalanche platform because it has all the wrapped tokens data required in the horizen-eon sidechain,
  so the mothod sets the platform as avalanche for this call and passes all the avalanche wrapped token addresses present on the c-chain
  """
  @impl Source
  def source_url(token_addresses) when is_list(token_addresses) do
    platform = "avalanche"
    joined_addresses = "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab,0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7,0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e,0x9702230a8ea53601f5cd2dc00fdbc13d4df4a8c7,0xd586e7f844cea2f87f50152665bcbc2c279d8d70,0x5947bb275c521040051d82396192181b413227a3,0x50b7545627a5162f82a992c33b87adc75187b218"

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
