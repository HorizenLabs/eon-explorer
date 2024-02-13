defmodule EthereumJSONRPC.ForwardTransfers do
  @moduledoc """
  Handles fetching and processing of forward transfers from the blockchain.

  This module is responsible for fetching forward transfer data for a given range of block numbers and processing that data into a structured format. It makes use of the Ethereum JSON RPC interface to query for forward transfers and then formats the raw data into a more usable Elixir data structure.

  ## Functions

    - `fetch/2`: Fetches forward transfer data for a given range of block numbers.
    - `format_and_flatten/2`: Formats and flattens the response from the Ethereum JSON RPC into a list of forward transfers.
    - `request/1`: Constructs a request for forward transfer data for a given block number.
    - `requests/2`: Maps over a collection of block numbers to construct multiple requests.
    - `elixir_to_params/1` and `to_elixir/1`: Convert data between raw and processed formats.
  """

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
    ft_responses
    |> elem(1)
    |> Enum.map(fn response ->
      response.result["forwardTransfers"]
      |> Enum.reduce([], fn ft, acc ->
        [%{
          to_address_hash: ft["to"],
          block_number: id_to_params[response.id].number,
          value: quantity_to_integer(ft["value"]),
          index: Enum.count(acc)
        } | acc]
      end)
      |> Enum.reverse()
    end)
    |> Enum.concat()
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
