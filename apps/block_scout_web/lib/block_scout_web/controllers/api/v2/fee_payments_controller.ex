defmodule BlockScoutWeb.API.V2.FeePaymentsController do
  use BlockScoutWeb, :controller

  import BlockScoutWeb.Chain,
    only: [
      next_page_params: 3,
      paging_options: 1,
      split_list_by_page: 1,
      current_filter: 1
    ]

  import BlockScoutWeb.PagingHelper,
    only: [delete_parameters_from_next_page_params: 1]

  alias BlockScoutWeb.API.V2.FeePaymentView
  alias Explorer.Chain

  @fee_payments_necessity_by_association [
    necessity_by_association: %{
      :block => :optional,
      :to_address => :optional
    }
  ]

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  def fee_payments(conn, params) do
    options =
      @fee_payments_necessity_by_association
      |> Keyword.merge(paging_options(params))
      |> Keyword.merge(current_filter(params))
    options = add_value_from_mainchain(options, params)

    results = Chain.get_fee_payments(nil, nil, options)
    {fee_payments, next_page} = split_list_by_page(results)

    next_page_params =
      next_page |> next_page_params(fee_payments, params) |> delete_parameters_from_next_page_params()

    conn
    |> put_status(200)
    |> put_view(FeePaymentView)
    |> render(:fee_payments, %{fee_payments: fee_payments, next_page_params: next_page_params})

  end

  # check if "value_from_mainchain" parameter exists in params
  # if the parameter exists, add it to options
  defp add_value_from_mainchain(options, params) do
    value_from_mainchain = Enum.find_value(params, fn {key, _} -> key == "value_from_mainchain" end)
    case value_from_mainchain do
      nil -> options
      _ -> Keyword.put_new(options, :value_from_mainchain, true)
    end
  end

end
