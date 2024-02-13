defmodule EthereumJSONRPC.FeePayments do
  @moduledoc """
  Handles fetching and processing of fee payment data from the blockchain.

  This module communicates with the Ethereum JSON RPC interface to retrieve data on fee payments for a specified range of block numbers. It processes this data into a structured Elixir format for further use within the application.

  The main functionality includes constructing and sending JSON RPC requests to fetch fee payment data, followed by formatting and flattening the response into a structured list of fee payments.

  ## Functions

    - `fetch/2`: Fetches fee payment data for a specified range of block numbers.
    - `format_and_flatten/2`: Processes the raw JSON RPC response, extracting and structuring fee payment data.
    - `request/1`: Builds a single JSON RPC request for fee payment data for a specific block number.
    - `requests/2`: Maps over a collection of block numbers to build and send multiple requests.
    - `response_to_payments/1`: Extracts the fee payment data from the JSON RPC response.
  """

  import EthereumJSONRPC, only: [integer_to_quantity: 1, quantity_to_integer: 1, json_rpc: 2, id_to_params: 1]

  alias EthereumJSONRPC
  alias EthereumJSONRPC.FeePayment

  @type elixir :: [FeePayment.elixir()]
  @type params :: [FeePayment.params()]
  @type t :: [FeePayment.t()]

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

  def format_and_flatten(fp_responses, id_to_params) do
    fp_responses
    |> elem(1)
    |> Enum.flat_map(&response_to_payments(&1))
    |> Enum.with_index()
    |> Enum.reduce([], fn {fp, index}, acc ->
      [
        %{
          to_address_hash: fp["address"],
          block_number: id_to_params[fp.id].number,
          value: quantity_to_integer(fp["value"]),
          index: index
        }
        | acc
      ]
    end)
    |> Enum.reverse()
  end

  def request(%{id: id, number: number}) do
    EthereumJSONRPC.request(%{id: id, method: "zen_getFeePayments", params: [integer_to_quantity(number)]})
  end

  def requests(id_to_params, request) when is_map(id_to_params) and is_function(request, 1) do
    Enum.map(id_to_params, fn {id, params} ->
      params
      |> Map.put(:id, id)
      |> request.()
    end)
  end

  def response_to_payments(response) do
    case response do
      %{result: nil} -> []
      %{result: %{"payments" => payments}} -> payments
      _ -> []
    end
  end
end
