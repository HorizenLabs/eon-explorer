defmodule Explorer.Metrics do
  alias Explorer.Chain.Cache.Block, as: BlockCache
  alias Explorer.Chain.Cache.ThirtyDayActiveAccountCountList
  alias Explorer.Chain.Cache.ThirtyDayActiveDevCountList
  alias Explorer.Chain.Cache.ThirtyDayAverageTransactionFeeList
  alias Explorer.Chain.Cache.ThirtyDayContractCountList
  alias Explorer.Chain.Cache.ThirtyDayGasUsedList
  alias Explorer.Chain.Cache.ThirtyDayTransactionCountList
  alias Explorer.Chain.Cache.TotalSmartContracts
  alias Explorer.Chain.Cache.TotalValueLocked
  alias Explorer.Chain.Cache.TotalAccounts
  alias Explorer.Chain.Cache.TotalEntries
  alias Explorer.Chain.Cache.Transaction, as: TransactionCache
  alias Explorer.Counters.AverageBlockTime

  @spec total_accounts() :: number()
  def total_accounts() do
    TotalAccounts.cached_results()
  end

  @spec total_blocks() :: number()
  def total_blocks() do
    BlockCache.estimated_count()
  end

  @spec total_entries(String.t()) :: number()
  def total_entries(table_name) do
    TotalEntries.cached_results(table_name)
  end

  @spec total_smart_contracts() :: number()
  def total_smart_contracts() do
    TotalSmartContracts.cached_results()
  end

  @spec total_transactions() :: number()
  def total_transactions() do
    TransactionCache.estimated_count()
  end

  @spec total_value_locked() :: map()
  def total_value_locked() do
    TotalValueLocked.cached_results()
  end

  @spec average_block_time() :: String.t()
  def average_block_time() do
    Timex.format_duration(AverageBlockTime.average_block_time(), Explorer.Counters.AverageBlockTimeDurationFormat)
  end

  @spec thirty_day_active_account_count_list() :: list()
  def thirty_day_active_account_count_list() do
    ThirtyDayActiveAccountCountList.cached_results()
  end

  @spec thirty_day_active_dev_count_list() :: list()
  def thirty_day_active_dev_count_list() do
    ThirtyDayActiveDevCountList.cached_results()
  end

  @spec thirty_day_avg_tx_fee_list() :: list()
  def thirty_day_avg_tx_fee_list() do
    ThirtyDayAverageTransactionFeeList.cached_results()
  end

  @spec thirty_day_contract_count_list() :: list()
  def thirty_day_contract_count_list() do
    ThirtyDayContractCountList.cached_results()
  end

  @spec thirty_day_gas_used_list() :: list()
  def thirty_day_gas_used_list() do
    ThirtyDayGasUsedList.cached_results()
  end

  @spec thirty_day_tx_count_list() :: list()
  def thirty_day_tx_count_list() do
    ThirtyDayTransactionCountList.cached_results()
  end
end
