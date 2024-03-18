defmodule BlockScoutWeb.API.V2.ForwardTransferView do
  use BlockScoutWeb, :view

  def render("message.json", assigns) do
    ApiView.render("message.json", assigns)
  end

  def render("forward_transfers.json", %{forward_transfers: forward_transfers, next_page_params: next_page_params}) do
    %{"items" => Enum.map(forward_transfers, &prepare_forward_transfers(&1, nil)), "next_page_params" => next_page_params}
  end

  def prepare_forward_transfers(forward_transfer, _conn) do

    %{
      "block_number" => forward_transfer.block_number,
      "block_hash" => forward_transfer.block_hash,
      "to_address" => forward_transfer.to_address_hash,
      "value" => forward_transfer.value
    }
  end

end
