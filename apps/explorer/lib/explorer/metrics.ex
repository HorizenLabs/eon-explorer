defmodule Explorer.Metrics do
  alias Explorer.{Repo}
  alias Explorer.Counters.AverageBlockTime

  @spec total_accounts() :: number()
  def total_accounts() do
    %Postgrex.Result{rows: [[count]]} = Repo.query!("SELECT COUNT(contract_code IS NULL) FROM addresses;")
    count
  end

  @spec total_entries(String.t()) :: number()
  def total_entries(table_name) do
    %Postgrex.Result{rows: [[count]]} =
      Repo.query!("SELECT reltuples::BIGINT AS estimate FROM pg_class WHERE relname='#{String.downcase(table_name)}';")
    count
  end

  def average_block_time() do
    Timex.format_duration(AverageBlockTime.average_block_time(), Explorer.Counters.AverageBlockTimeDurationFormat)
  end

  def thirty_day_contract_count_list() do
    %Postgrex.Result{rows: rows} = Repo.query!(
      "SELECT to_char(inserted_at, 'yyyy-mm-dd') AS formatted_date, count(contract_code)
      FROM addresses
      WHERE inserted_at BETWEEN CURRENT_DATE - interval '30 days' AND CURRENT_DATE-interval '1 day'
      GROUP BY formatted_date
      ORDER BY formatted_date ASC;")
    Enum.map(rows, fn row -> %{"date" => Enum.at(row, 0), "contract_count" => Enum.at(row, 1)} end)
  end

  def thirty_day_tx_count_list() do
    %Postgrex.Result{rows: rows} = Repo.query!(
      "SELECT to_char(date,'yyyy-mm-dd') AS formatted_date, number_of_transactions
      FROM transaction_stats
      WHERE date BETWEEN CURRENT_DATE - interval '30 days' AND CURRENT_DATE-interval '1 day'
      ORDER BY formatted_date ASC;")
    Enum.map(rows, fn row -> %{"date" => Enum.at(row, 0), "transaction_count" => Enum.at(row, 1)} end)
  end

end
