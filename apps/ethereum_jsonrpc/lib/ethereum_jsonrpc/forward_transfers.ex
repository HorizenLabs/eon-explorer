defmodule EthereumJSONRPC.ForwardTransfers do
  require Logger

  import EthereumJSONRPC, only: [integer_to_quantity: 1, quantity_to_integer: 1, json_rpc: 2, id_to_params: 1]

  alias EthereumJSONRPC
  alias EthereumJSONRPC.ForwardTransfer

  @type elixir :: [ForwardTransfer.elixir()]
  @type params :: [ForwardTransfer.params()]
  @type t :: [ForwardTransfer.t()]

  def fetch(range, json_rpc_named_arguments) do
    id_to_params =
      range
      |> Enum.map(fn number -> %{number: number} end)
      |> id_to_params()

    id_to_params
    |> requests(&request/1)
    |> json_rpc(json_rpc_named_arguments)
    |> format_and_flatten(id_to_params)
  end

  def format_and_flatten(ft_responses, id_to_params) do
    elem(ft_responses, 1)
    |> Enum.map(fn response ->
      Enum.map(response.result["forwardTransfers"], fn ft ->
        %{
          to_address_hash: ft["to"],
          block_number: id_to_params[response.id].number,
          value: quantity_to_integer(ft["value"])
        }
      end)
    end)
    |> Enum.flat_map(fn ft -> ft end)
  end

  def request(%{id: id, number: number}) do
    EthereumJSONRPC.request(%{id: id, method: "zen_getForwardTransfers", params: [integer_to_quantity(number)]})
  end

  def requests(id_to_params, request) when is_map(id_to_params) and is_function(request, 1) do
    Enum.map(id_to_params, fn {id, params} ->
      params
      |> Map.put(:id, id)
      |> request.()
    end)
  end

  def elixir_to_params(elixir) when is_list(elixir) do
    Enum.map(elixir, &ForwardTransfer.elixir_to_params/1)
  end

  def to_elixir(forward_transfers) when is_list(forward_transfers) do
    forward_transfers
    |> Enum.map(&ForwardTransfer.to_elixir/1)
    |> Enum.filter(&(!is_nil(&1)))
  end
end
