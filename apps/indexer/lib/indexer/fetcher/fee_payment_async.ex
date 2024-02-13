defmodule Indexer.Fetcher.FeePaymentAsync do
  @moduledoc """
  Fetches information about fee payments, extra transfer events
  which are associated with a block but are not recorded as block transactions.
  """

  require Logger

  use Indexer.Fetcher, restart: :permanent
  use Spandex.Decorators

  alias Explorer.Chain
  alias Indexer.{BufferedTask, Tracer}

  @behaviour BufferedTask

  @defaults [
    flush_interval: :timer.seconds(3),
    max_batch_size: 1,
    max_concurrency: 1,
    task_supervisor: Indexer.Fetcher.FeePayment.TaskSupervisor
  ]

  @counter_type "extra_transfer_block_number"

  @doc """
  Fetches fee_payments asynchronously given a list of block numbers.
  """
  @spec async_fetch([integer()]) :: :ok
  def async_fetch(entries) do
    BufferedTask.buffer(__MODULE__, entries)
  end

  @doc false
  def child_spec([init_options, gen_server_options]) do
    {state, mergeable_init_options} = Keyword.pop(init_options, :json_rpc_named_arguments)

    unless state do
      raise ArgumentError,
            ":json_rpc_named_arguments must be provided to `#{__MODULE__}.child_spec " <>
              "to allow for json_rpc calls when running."
    end

    merged_init_opts =
      @defaults
      |> Keyword.merge(mergeable_init_options)
      |> Keyword.put(:state, state)

    Supervisor.child_spec({BufferedTask, [{__MODULE__, merged_init_opts}, gen_server_options]},
      id: __MODULE__
    )
  end

  @impl BufferedTask
  def init(initial_acc, reducer, _) do
    {:ok, final} =
      Chain.stream_unfetched_extra_transfers(initial_acc, fn block_number, acc ->
        reducer.(block_number, acc)
      end)

    final
  end

  @impl BufferedTask
  @decorate trace(
              name: "fetch",
              resource: "Indexer.Fetcher.FeePayment.run/2",
              service: :indexer,
              tracer: Tracer
            )
  def run(entries, json_rpc_named_arguments) do
    start_entry = Enum.at(entries, 0)
    end_entry = List.last(entries)
    range = Range.new(start_entry, end_entry)

    range
    |> EthereumJSONRPC.FeePayments.fetch(json_rpc_named_arguments)
    |> import_fee_payments(entries)
  end


  defp import_fee_payments(fee_payments, entries) do
    case Chain.import(%{fee_payments: %{params: fee_payments}, timeout: :infinity}) do
      {:ok, _imported} ->
        with false <- Enum.empty?(entries) do
          Chain.upsert_last_fetched_counter(%{counter_type: @counter_type, value: List.last(entries)})
        end

        :ok

      {:error, step, reason, _changes_so_far} ->
        Logger.error(
          fn ->
            [
              "failed to import fee payments: ",
              inspect(reason)
            ]
          end,
          step: step
        )

        {:retry, entries}
    end
  end
end
