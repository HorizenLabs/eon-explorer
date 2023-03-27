defmodule Explorer.Metrics do

  alias Explorer.{Repo}
  alias Explorer.Counters.AverageBlockTime

  @spec total_entries(String.t()) :: number()
  def total_entries(table_name) do
    %Postgrex.Result{rows: [[count]]} =
     Repo.query!("SELECT reltuples::BIGINT AS estimate FROM pg_class WHERE relname='#{String.downcase(table_name)}';")
    count
  end

  def average_block_time() do
    Timex.format_duration(AverageBlockTime.average_block_time(), Explorer.Counters.AverageBlockTimeDurationFormat)
  end


end
