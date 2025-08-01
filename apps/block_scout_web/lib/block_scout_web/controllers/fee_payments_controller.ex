defmodule BlockScoutWeb.FeePaymentController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [
      fetch_page_number: 1,
      paging_options: 1,
      next_page_params: 3,
      update_page_parameters: 3,
      split_list_by_page: 2
    ]

  alias BlockScoutWeb.{Controller}

  alias Phoenix.View

  alias Explorer.{Chain}

  @default_options [
    necessity_by_association: %{
      :block => :optional,
      :to_address => :optional
    }
  ]

  def index(conn, %{"type" => "JSON"} = params) do
    options =
      @default_options
      |> Keyword.merge(paging_options(params))

    full_options =
      options
      |> Keyword.put(
        :paging_options,
        params
        |> fetch_page_number()
        |> update_page_parameters(Chain.default_page_size(), Keyword.get(options, :paging_options))
      )

    %{total_fee_payments_count: fee_payments_count, fee_payments: fee_payments_plus_one} =
      Chain.recent_collated_fee_payments_for_rap(full_options)

    {fee_payments, next_page} =
      if fetch_page_number(params) == 1 do
        split_list_by_page(fee_payments_plus_one, Chain.default_page_size())
      else
        {fee_payments_plus_one, nil}
      end

    next_page_params =
      if fetch_page_number(params) == 1 do
        page_size = Chain.default_page_size()

        pages_limit = fee_payments_count |> Kernel./(page_size) |> Float.ceil() |> trunc()

        case next_page_params(next_page, fee_payments, params) do
          nil ->
            nil

          next_page_params ->
            next_page_params
            |> Map.delete("type")
            |> Map.delete("items_count")
            |> Map.put("pages_limit", pages_limit)
            |> Map.put("page_size", page_size)
            |> Map.put("page_number", 1)
        end
      else
        Map.delete(params, "type")
      end

    json(
      conn,
      %{
        items:
          Enum.map(fee_payments, fn transaction ->
            View.render_to_string(
              BlockScoutWeb.FeePaymentView,
              "_tile.html",
              fee_payment: transaction,
              conn: conn
            )
          end),
        next_page_params: next_page_params
      }
    )
  end

  def index(conn, _params) do
    render(
      conn,
      "index.html",
      current_path: Controller.current_full_path(conn)
    )
  end

  def count(conn, _params) do
    ft_count = Chain.fee_payments_count()
    text(conn, "number of fee_payments #{ft_count}")
  end
end
