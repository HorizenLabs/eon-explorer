defmodule BlockScoutWeb.API.V2.ForwardTransferView do
  use BlockScoutWeb, :view
  alias Explorer.Chain.Address

  def render("forward_transfers.json", %{forward_transfers: forward_transfers, next_page_params: next_page_params}) do
    %{"items" => Enum.map(forward_transfers, &prepare_forward_transfer(&1, nil)), "next_page_params" => next_page_params}
  end

  def prepare_forward_transfer(forward_transfer, _conn) do

    %{
      "to_address" => Address.checksum(forward_transfer.to_address_hash),
      "value" => forward_transfer.value,
      "block_number" => forward_transfer.block_number,
      "block_hash" => forward_transfer.block_hash,
      "index" => forward_transfer.index
    }
  end

end
