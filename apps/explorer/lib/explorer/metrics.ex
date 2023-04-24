defmodule Explorer.Metrics do
  alias Explorer.{Repo}
  alias Explorer.Counters.AverageBlockTime
  alias Explorer.Chain.Cache.Transaction, as: TransactionCache
  alias Explorer.Chain.Cache.Block, as: BlockCache

  @spec total_accounts() :: number()
  def total_accounts() do
    %Postgrex.Result{rows: [[count]]} = Repo.query!("SELECT COUNT(contract_code IS NULL) FROM addresses;")
    count
  end

  @spec total_smart_contracts() :: number()
  def total_smart_contracts() do
    %Postgrex.Result{rows: [[count]]} = Repo.query!("SELECT COUNT(contract_code) FROM addresses WHERE contract_code IS NOT NULL;")
    count
  end

  @spec total_transactions() :: number()
  def total_transactions() do
    TransactionCache.estimated_count()
  end

  @spec total_blocks() :: number()
  def total_blocks() do
    BlockCache.estimated_count()
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

  def thirty_day_active_dev_count_list() do
    %Postgrex.Result{rows: rows} = Repo.query!(
      "SELECT to_char(inserted_at, 'yyyy-mm-dd') as formatted_date,
        count(DISTINCT hash)
      FROM addresses
      WHERE contract_code IS NOT NULL
        AND inserted_at BETWEEN CURRENT_DATE - interval '30 days' AND CURRENT_DATE - interval '1 day'
      GROUP BY formatted_date
      ORDER BY formatted_date ASC;")
    Enum.map(rows, fn row -> %{"date" => Enum.at(row, 0), "active_dev_count" => Enum.at(row, 1)} end)
  end

  def thirty_day_avg_tx_fee_list() do
    %Postgrex.Result{rows: rows} = Repo.query!(
      "SELECT to_char(inserted_at, 'yyyy-mm-dd') as formatted_date,
        avg(gas_used*(gas_price/10^18)) AS avg_gas_fee_zen
      FROM transactions
      WHERE inserted_at BETWEEN CURRENT_DATE - interval '30 days' AND CURRENT_DATE - interval '1 day'
      GROUP BY formatted_date
      ORDER BY formatted_date asc;")
    Enum.map(rows, fn row -> %{"date" => Enum.at(row, 0), "avg_tx_fee" => Enum.at(row, 1)} end)
  end

  def thirty_day_gas_used_list() do
    %Postgrex.Result{rows: rows} = Repo.query!(
      "WITH DATA AS
        (SELECT date, gas_used
        FROM transaction_stats ts
        WHERE date BETWEEN CURRENT_DATE - interval '30 days' AND CURRENT_DATE - interval '1 day')
      SELECT to_char(date, 'yyyy-mm-dd') as formatted_date, sum(gas_used) OVER
        (ORDER BY date ASC ROWS BETWEEN UNBOUNDED preceding AND CURRENT ROW) AS gas_used
      FROM DATA")
    Enum.map(rows, fn row -> %{"date" => Enum.at(row, 0), "gas_used" => Enum.at(row, 1)} end)
  end

  def thirty_day_active_account_count_list() do
    %Postgrex.Result{rows: rows} = Repo.query!(
      "SELECT to_char(inserted_at, 'yyyy-mm-dd') as formatted_date, count(DISTINCT from_address_hash)
      FROM transactions
      WHERE inserted_at BETWEEN CURRENT_DATE - interval '30 days' AND CURRENT_DATE - interval '1 day'
      GROUP BY formatted_date
      ORDER BY formatted_date ASC")
    Enum.map(rows, fn row -> %{"date" => Enum.at(row, 0), "active_accounts" => Enum.at(row, 1)} end)
  end


end
