defmodule EthereumJSONRPC.FeePayments do

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
    elem(fp_responses, 1)
    |> Enum.map(fn response ->
      Enum.reduce(response_to_payments(response), [], fn fp, acc ->
        [%{
          to_address_hash: fp["address"],
          block_number: id_to_params[response.id].number,
          value: quantity_to_integer(fp["value"]),
          index: Enum.count(acc)
        } | acc]
      end)
      |>
      Enum.reverse()
    end)
    |> Enum.flat_map(fn fp -> fp end)
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
