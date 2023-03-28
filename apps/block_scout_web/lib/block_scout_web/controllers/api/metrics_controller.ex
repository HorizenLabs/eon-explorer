defmodule BlockScoutWeb.API.MetricsController do
  use BlockScoutWeb, :controller

  alias Explorer.Metrics

  def total_accounts(conn, _params) do
    inspect "test"
    total_accounts = Metrics.total_accounts()
    json(conn, %{"total_accounts" => total_accounts})
  end

  def total(conn, %{"table_name" => table_name}) do
    total = Metrics.total_entries(table_name)
    json(conn, %{"total_#{table_name}" => total})
  end

  def average_block_time(conn, _params) do
    avg_block_time = Metrics.average_block_time()
    json(conn, %{"avg_block_time" => avg_block_time})
  end

   def thirty_day_contracts_list(conn, _params) do
    thirty_day_contracts_list = Metrics.thirty_day_contracts_list()
    json(conn, thirty_day_contracts_list)
   end
end
