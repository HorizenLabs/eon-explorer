defmodule BlockScoutWeb.API.MetricsController do
  use BlockScoutWeb, :controller

  alias Explorer.Metrics

  def total(conn, %{"table_name" => table_name}) do
    inspect "test"
    total = Metrics.total_entries(table_name)
    json(conn, %{"total_#{table_name}" => total})
  end
end
