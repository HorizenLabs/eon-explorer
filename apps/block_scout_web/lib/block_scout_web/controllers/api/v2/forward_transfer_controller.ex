defmodule BlockScoutWeb.API.V2.ForwardTransferController do
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

  alias BlockScoutWeb.API.V2.ForwardTransferView
  alias Explorer.Chain

  @forward_transfer_necessity_by_association [
    necessity_by_association: %{
      :block => :optional,
      :to_address => :optional
    }
  ]

  action_fallback(BlockScoutWeb.API.V2.FallbackController)

  def forward_transfers(conn, params) do
    options =
      @forward_transfer_necessity_by_association
      |> Keyword.merge(paging_options(params))
      |> Keyword.merge(current_filter(params))

    results = Chain.get_forward_transfers(nil, nil, options)
    {forward_transfers, next_page} = split_list_by_page(results)

    next_page_params =
      next_page |> next_page_params(forward_transfers, params) |> delete_parameters_from_next_page_params()

    conn
    |> put_status(200)
    |> put_view(ForwardTransferView)
    |> render(:forward_transfers, %{forward_transfers: forward_transfers, next_page_params: next_page_params})

  end

end
