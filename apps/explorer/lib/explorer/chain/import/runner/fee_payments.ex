defmodule Explorer.Chain.Import.Runner.FeePayments do
  @moduledoc """
  Bulk imports `t:Explorer.Chain.FeePayment.t/0`.
  """

  require Ecto.Query

  alias Ecto.{Multi, Repo}
  alias Explorer.Chain.{Hash, Import, FeePayment}
  alias Explorer.Prometheus.Instrumenter

  @behaviour Import.Runner

  # milliseconds
  @timeout 60_000

  @type imported :: [Hash.Full.t()]

  @impl Import.Runner
  def ecto_schema_module, do: FeePayment

  @impl Import.Runner
  def option_key, do: :fee_payments

  @impl Import.Runner
  def imported_table_row do
    %{
      value_type: "[#{ecto_schema_module()}.t()]",
      value_description: "List of `t:#{ecto_schema_module()}.t/0`s"
    }
  end

  @impl Import.Runner
  def run(multi, changes_list, %{timestamps: timestamps} = options) do
    insert_options =
      options
      |> Map.get(option_key(), %{})
      |> Map.put_new(:timeout, @timeout)
      |> Map.put(:timestamps, timestamps)

    multi
    |> Multi.run(:fee_payments, fn repo, _ ->
      Instrumenter.block_import_stage_runner(
        fn -> insert(repo, changes_list, insert_options) end,
        :block_referencing,
        :fee_payments,
        :fee_payments
      )
    end)
  end

  @impl Import.Runner
  def timeout, do: @timeout

  @spec insert(Repo.t(), [map()], %{
          optional(:on_conflict) => Import.Runner.on_conflict(),
          required(:timeout) => timeout,
          required(:timestamps) => Import.timestamps()
        }) :: {:ok, [Hash.t()]}
  defp insert(
         repo,
         changes_list,
         %{
           timeout: timeout,
           timestamps: timestamps
         } = _options
       )
       when is_list(changes_list) do
    Import.insert_changes_list(
      repo,
      changes_list,
      for: FeePayment,
      on_conflict: :nothing,
      returning: true,
      timeout: timeout,
      timestamps: timestamps
    )
  end
end
