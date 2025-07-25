defmodule BlockScoutWeb.API.MetricsController do
  use BlockScoutWeb, :controller

  alias Explorer.Metrics

  def average_block_time(conn, _params) do
    avg_block_time = Metrics.average_block_time()
    json(conn, %{"avg_block_time" => avg_block_time})
  end

  def thirty_day_active_account_count_list(conn, _params) do
    thirty_day_active_account_count_list = Metrics.thirty_day_active_account_count_list()
    json(conn, thirty_day_active_account_count_list)
  end

  def thirty_day_active_dev_count_list(conn, _params) do
    thirty_day_active_dev_count_list = Metrics.thirty_day_active_dev_count_list()
    json(conn, thirty_day_active_dev_count_list)
  end

  def thirty_day_avg_tx_fee_list(conn, _params) do
    thirty_day_avg_tx_fee_list = Metrics.thirty_day_avg_tx_fee_list()
    json(conn, thirty_day_avg_tx_fee_list)
  end

  def thirty_day_contract_count_list(conn, _params) do
    thirty_day_contract_count_list = Metrics.thirty_day_contract_count_list()
    json(conn, thirty_day_contract_count_list)
  end

  def thirty_day_gas_used_list(conn, _params) do
    thirty_day_gas_used_list = Metrics.thirty_day_gas_used_list()
    json(conn, thirty_day_gas_used_list)
  end

  def thirty_day_tx_count_list(conn, _params) do
    thirty_day_tx_count_list = Metrics.thirty_day_tx_count_list()
    json(conn, thirty_day_tx_count_list)
  end

  def total(conn, %{"table_name" => table_name}) do
    total = Metrics.total_entries(table_name)
    json(conn, %{"total_#{table_name}" => total})
  end

  def total_accounts(conn, _params) do
    total_accounts = Metrics.total_accounts()
    json(conn, %{"total_accounts" => total_accounts})
  end

  def total_blocks(conn, _params) do
    total_blocks = Metrics.total_blocks()
    json(conn, %{"total_blocks" => total_blocks})
  end

  def total_smart_contracts(conn, _params) do
    total_smart_contracts = Metrics.total_smart_contracts()
    json(conn, %{"total_smart_contracts" => total_smart_contracts})
  end

  def total_transactions(conn, _params) do
    total_transactions = Metrics.total_transactions()
    json(conn, %{"total_transactions" => total_transactions})
  end

  def total_value_locked(conn, _params) do
    total_value_locked = Metrics.total_value_locked()
    json(conn, %{"total_value_locked" => total_value_locked})
  end
end
