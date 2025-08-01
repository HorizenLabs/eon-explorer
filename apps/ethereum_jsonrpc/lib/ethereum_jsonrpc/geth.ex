defmodule EthereumJSONRPC.Geth do
  @moduledoc """
  Ethereum JSONRPC methods that are only supported by [Geth](https://github.com/ethereum/go-ethereum/wiki/geth).
  """

  require Logger

  import EthereumJSONRPC, only: [id_to_params: 1, integer_to_quantity: 1, json_rpc: 2, request: 1]

  alias EthereumJSONRPC.{FetchedBalance, FetchedCode, PendingTransaction, Utility.CommonHelper}
  alias EthereumJSONRPC.Geth.{Calls, PolygonTracer, Tracer}

  @behaviour EthereumJSONRPC.Variant

  @doc """
  Block reward contract beneficiary fetching is not supported currently for Geth.

  To signal to the caller that fetching is not supported, `:ignore` is returned.
  """
  @impl EthereumJSONRPC.Variant
  def fetch_beneficiaries(_block_range, _json_rpc_named_arguments), do: :ignore

  @doc """
  Fetches the `t:Explorer.Chain.InternalTransaction.changeset/2` params.
  """
  @impl EthereumJSONRPC.Variant
  def fetch_internal_transactions(transactions_params, json_rpc_named_arguments) when is_list(transactions_params) do
    id_to_params = id_to_params(transactions_params)

    json_rpc_named_arguments_corrected_timeout = correct_timeouts(json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> debug_trace_transaction_requests()
           |> json_rpc(json_rpc_named_arguments_corrected_timeout) do
      debug_trace_transaction_responses_to_internal_transactions_params(
        responses,
        id_to_params,
        json_rpc_named_arguments
      )
    end
  end

  defp correct_timeouts(json_rpc_named_arguments) do
    debug_trace_transaction_timeout =
      Application.get_env(:ethereum_jsonrpc, __MODULE__)[:debug_trace_transaction_timeout]

    case CommonHelper.parse_duration(debug_trace_transaction_timeout) do
      {:error, :invalid_format} ->
        json_rpc_named_arguments

      parsed_timeout ->
        json_rpc_named_arguments
        |> put_in([:transport_options, :http_options, :timeout], parsed_timeout)
        |> put_in([:transport_options, :http_options, :recv_timeout], parsed_timeout)
    end
  end

  @doc """
  Fetches the first trace from the trace URL.
  """
  @impl EthereumJSONRPC.Variant
  def fetch_first_trace(_transactions_params, _json_rpc_named_arguments), do: :ignore

  @doc """
  Internal transaction fetching for entire blocks is not currently supported for Geth.

  To signal to the caller that fetching is not supported, `:ignore` is returned.
  """
  @impl EthereumJSONRPC.Variant
  def fetch_block_internal_transactions(_block_range, _json_rpc_named_arguments), do: :ignore

  @doc """
  Fetches the pending transactions from the Geth node.
  """
  @impl EthereumJSONRPC.Variant
  def fetch_pending_transactions(json_rpc_named_arguments) do
    PendingTransaction.fetch_pending_transactions_geth(json_rpc_named_arguments)
  end

  defp debug_trace_transaction_requests(id_to_params) when is_map(id_to_params) do
    Enum.map(id_to_params, fn {id, %{hash_data: hash_data}} ->
      debug_trace_transaction_request(%{id: id, hash_data: hash_data})
    end)
  end

  @tracer_path "priv/js/ethereum_jsonrpc/geth/debug_traceTransaction/tracer.js"
  @external_resource @tracer_path
  @tracer File.read!(@tracer_path)

  defp debug_trace_transaction_request(%{id: id, hash_data: hash_data}) do

    tracer =
      case Application.get_env(:ethereum_jsonrpc, __MODULE__)[:tracer] do
        "js" ->
          %{"tracer" => @tracer}

        "call_tracer" ->
          %{"tracer" => "callTracer"}

        _ ->
          %{
            "enableMemory" => true,
            "disableStack" => false,
            "disableStorage" => true,
            "enableReturnData" => false
          }
      end

    request(%{
      id: id,
      method: "debug_traceTransaction",
      params: [hash_data, tracer]
    })
  end

  defp debug_trace_transaction_responses_to_internal_transactions_params(
         [%{result: %{"structLogs" => _}} | _] = responses,
         id_to_params,
         json_rpc_named_arguments
       )
       when is_map(id_to_params) do
    with {:ok, receipts} <-
           id_to_params
           |> Enum.map(fn {id, %{hash_data: hash_data}} ->
             request(%{id: id, method: "eth_getTransactionReceipt", params: [hash_data]})
           end)
           |> json_rpc(json_rpc_named_arguments),
         {:ok, txs} <-
           id_to_params
           |> Enum.map(fn {id, %{hash_data: hash_data}} ->
             request(%{id: id, method: "eth_getTransactionByHash", params: [hash_data]})
           end)
           |> json_rpc(json_rpc_named_arguments) do
      receipts_map = Enum.into(receipts, %{}, fn %{id: id, result: receipt} -> {id, receipt} end)
      txs_map = Enum.into(txs, %{}, fn %{id: id, result: tx} -> {id, tx} end)

      tracer =
        if Application.get_env(:ethereum_jsonrpc, __MODULE__)[:tracer] == "polygon_edge",
          do: PolygonTracer,
          else: Tracer

      responses
      |> Enum.map(fn %{id: id, result: %{"structLogs" => _} = result} ->
        debug_trace_transaction_response_to_internal_transactions_params(
          %{id: id, result: tracer.replay(result, Map.fetch!(receipts_map, id), Map.fetch!(txs_map, id))},
          id_to_params
        )
      end)
      |> reduce_internal_transactions_params()
      |> fetch_missing_data(json_rpc_named_arguments)
    end
  end

  defp debug_trace_transaction_responses_to_internal_transactions_params(
         responses,
         id_to_params,
         _json_rpc_named_arguments
       )
       when is_list(responses) and is_map(id_to_params) do
    responses
    |> EthereumJSONRPC.sanitize_responses(id_to_params)
    |> Enum.map(&debug_trace_transaction_response_to_internal_transactions_params(&1, id_to_params))
    |> reduce_internal_transactions_params()
  end

  defp fetch_missing_data({:ok, transactions}, json_rpc_named_arguments) when is_list(transactions) do
    id_to_params = id_to_params(transactions)

    with {:ok, responses} <-
           id_to_params
           |> Enum.map(fn
             {id, %{created_contract_address_hash: address, block_number: block_number}} ->
               FetchedCode.request(%{id: id, block_quantity: integer_to_quantity(block_number), address: address})

             {id, %{type: "selfdestruct", from_address_hash: hash_data, block_number: block_number}} ->
               FetchedBalance.request(%{id: id, block_quantity: integer_to_quantity(block_number), hash_data: hash_data})

             _ ->
               nil
           end)
           |> Enum.reject(&is_nil/1)
           |> json_rpc(json_rpc_named_arguments) do
      results = Enum.into(responses, %{}, fn %{id: id, result: result} -> {id, result} end)

      transactions =
        id_to_params
        |> Enum.map(fn
          {id, %{created_contract_address_hash: _} = transaction} ->
            %{transaction | created_contract_code: Map.fetch!(results, id)}

          {id, %{type: "selfdestruct"} = transaction} ->
            %{transaction | value: Map.fetch!(results, id)}

          {_, transaction} ->
            transaction
        end)

      {:ok, transactions}
    end
  end

  defp fetch_missing_data(result, _json_rpc_named_arguments), do: result

  defp debug_trace_transaction_response_to_internal_transactions_params(%{id: id, result: calls}, id_to_params)
       when is_map(id_to_params) do
    %{block_number: block_number, hash_data: transaction_hash, transaction_index: transaction_index} =
      Map.fetch!(id_to_params, id)

    internal_transaction_params =
      calls
      |> prepare_calls()
      |> Stream.with_index()
      |> Enum.map(fn {trace, index} ->
        Map.merge(trace, %{
          "blockNumber" => block_number,
          "index" => index,
          "transactionIndex" => transaction_index,
          "transactionHash" => transaction_hash
        })
      end)
      |> Calls.to_internal_transactions_params()

    {:ok, internal_transaction_params}
  end

  defp debug_trace_transaction_response_to_internal_transactions_params(%{id: id, error: error}, id_to_params)
       when is_map(id_to_params) do
    %{
      block_number: block_number,
      hash_data: "0x" <> transaction_hash_digits = transaction_hash,
      transaction_index: transaction_index
    } = Map.fetch!(id_to_params, id)

    not_found_message = "transaction " <> transaction_hash_digits <> " not found"

    normalized_error =
      case error do
        %{code: -32_000, message: ^not_found_message} ->
          %{message: :not_found}

        %{code: -32_000, message: "execution timeout"} ->
          %{message: :timeout}

        _ ->
          error
      end

    annotated_error =
      Map.put(normalized_error, :data, %{
        block_number: block_number,
        transaction_index: transaction_index,
        transaction_hash: transaction_hash
      })

    {:error, annotated_error}
  end

  def prepare_calls(calls) do
    case Application.get_env(:ethereum_jsonrpc, __MODULE__)[:tracer] do
      "call_tracer" -> {calls, 0} |> parse_call_tracer_calls([], [], false) |> Enum.reverse()
      _ -> calls
    end
  end

  defp parse_call_tracer_calls(calls, acc, trace_address, inner? \\ true)
  defp parse_call_tracer_calls([], acc, _trace_address, _inner?), do: acc
  defp parse_call_tracer_calls({%{"type" => 0}, _}, acc, _trace_address, _inner?), do: acc

  defp parse_call_tracer_calls(
         {%{"type" => type, "from" => from} = call, index},
         acc,
         trace_address,
         inner?
       )
       when type in ~w(CALL CALLCODE DELEGATECALL STATICCALL CREATE CREATE2 SELFDESTRUCT REWARD) do
    new_trace_address = [index | trace_address]

    formatted_call =
      %{
        "type" => if(type in ~w(CALL CALLCODE DELEGATECALL STATICCALL), do: "call", else: String.downcase(type)),
        "callType" => String.downcase(type),
        "from" => from,
        "to" => Map.get(call, "to", "0x"),
        "createdContractAddressHash" => Map.get(call, "to", "0x"),
        "value" => Map.get(call, "value", "0x0"),
        "gas" => Map.get(call, "gas", "0x0"),
        "gasUsed" => Map.get(call, "gasUsed", "0x0"),
        "input" => Map.get(call, "input", "0x"),
        "init" => Map.get(call, "input", "0x"),
        "createdContractCode" => Map.get(call, "output", "0x"),
        "traceAddress" => if(inner?, do: Enum.reverse(new_trace_address), else: []),
        "error" => call["error"]
      }
      |> case do
        %{"error" => nil} = ok_call ->
          ok_call
          |> Map.delete("error")
          # to handle staticcall, all other cases handled by EthereumJSONRPC.Geth.Call.elixir_to_internal_transaction_params/1
          |> Map.put("output", Map.get(call, "output", "0x"))

        error_call ->
          error_call
      end

    parse_call_tracer_calls(
      Map.get(call, "calls", []),
      [formatted_call | acc],
      if(inner?, do: new_trace_address, else: [])
    )
  end

  defp parse_call_tracer_calls({call, _}, acc, _trace_address, _inner?) do
    Logger.warning("Call from a callTracer with an unknown type: #{inspect(call)}")
    acc
  end

  defp parse_call_tracer_calls(calls, acc, trace_address, _inner) when is_list(calls) do
    calls
    |> Stream.with_index()
    |> Enum.reduce(acc, &parse_call_tracer_calls(&1, &2, trace_address))
  end

  defp reduce_internal_transactions_params(internal_transactions_params) when is_list(internal_transactions_params) do
    internal_transactions_params
    |> Enum.reduce({:ok, []}, &internal_transactions_params_reducer/2)
    |> finalize_internal_transactions_params()
  end

  defp internal_transactions_params_reducer(
         {:ok, internal_transactions_params},
         {:ok, acc_internal_transactions_params_list}
       ),
       do: {:ok, [internal_transactions_params, acc_internal_transactions_params_list]}

  defp internal_transactions_params_reducer({:ok, _}, {:error, _} = acc_error), do: acc_error
  defp internal_transactions_params_reducer({:error, reason}, {:ok, _}), do: {:error, [reason]}

  defp internal_transactions_params_reducer({:error, reason}, {:error, acc_reasons}) when is_list(acc_reasons),
    do: {:error, [reason | acc_reasons]}

  defp finalize_internal_transactions_params({:ok, acc_internal_transactions_params_list})
       when is_list(acc_internal_transactions_params_list) do
    internal_transactions_params =
      acc_internal_transactions_params_list
      |> Enum.reverse()
      |> List.flatten()

    {:ok, internal_transactions_params}
  end

  defp finalize_internal_transactions_params({:error, acc_reasons}) do
    {:error, Enum.reverse(acc_reasons)}
  end
end
