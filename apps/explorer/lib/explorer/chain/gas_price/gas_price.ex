defmodule Explorer.Chain.GasPrice.GasPrice do
  @moduledoc """
  Call for gas price rpc method eth_gasPrice to retrieve gas price from the nodes
  """

  alias EthereumJSONRPC
  alias Explorer.Chain.Wei

  def get_gas_price_from_rpc() do

    case EthereumJSONRPC.fetch_gas_price(Application.get_env(:explorer, :json_rpc_named_arguments)) do
      {:ok, gas_price} ->
        gas_price_gwei = Wei.to(%Wei{value: gas_price}, :gwei)
        gas_price_gwei_float = gas_price_gwei |> Decimal.to_float()
        {:ok, gas_price_gwei_float}

      {:error, reason} ->
        raise RuntimeError, "error fetching gas price from JSON RPC method eth_gasPrice: #{reason}"
    end

  catch
    error ->
      {:error, error}
  end

end
