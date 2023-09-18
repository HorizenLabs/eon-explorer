defmodule Explorer.Chain.Cache.TotalAccounts do
  @moduledoc """
  Cache for Total Accounts.
  """

  @default_cache_period :timer.hours(2)

  use Explorer.Chain.MapCache,
    name: :total_accounts,
    key: :cached_result,
    key: :async_task,
    global_ttl: cache_period(),
    ttl_check_interval: :timer.minutes(15),
    callback: &async_task_on_deletion(&1)

  require Logger

  alias Ecto.Adapters.SQL
  alias Explorer.Repo

  def cached_results do
    cached_value = __MODULE__.get_cached_result()

    if is_nil(cached_value) do
      db_results()
    else
      cached_value
    end
  end

  def db_results do
    %Postgrex.Result{rows: [[count]]} =
      SQL.query!(
        Repo,
        "SELECT COUNT(contract_code IS NULL)
      FROM addresses"
      )

    count
  end

  defp handle_fallback(:cached_result) do
    # This will get the task PID if one exists and launch a new task if not
    # See next `handle_fallback` definition
    get_async_task()

    {:return, nil}
  end

  defp handle_fallback(:async_task) do
    # If this gets called it means an async task was requested, but none exists
    # so a new one needs to be launched
    {:ok, task} =
      Task.start(fn ->
        try do
          result = Repo.aggregate(db_results(), :cached_result, :hash, timeout: :infinity)

          set_cached_result(result)
        rescue
          e ->
            Logger.debug([
              "Coudn't update Total Accounts test #{inspect(e)}"
            ])
        end

        set_async_task(nil)
      end)

    {:update, task}
  end

  # By setting this as a `callback` an async task will be started each time the
  # `count` expires (unless there is one already running)
  defp async_task_on_deletion({:delete, _, :cached_result}), do: get_async_task()

  defp async_task_on_deletion(_data), do: nil

  defp cache_period do
    "CACHE_TOTAL_ACCOUNTS"
    |> System.get_env("")
    |> Integer.parse()
    |> case do
      {integer, ""} -> :timer.seconds(integer)
      _ -> @default_cache_period
    end
  end
end
