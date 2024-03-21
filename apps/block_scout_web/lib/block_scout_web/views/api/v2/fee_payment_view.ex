defmodule BlockScoutWeb.API.V2.FeePaymentView do
  use BlockScoutWeb, :view
  alias Explorer.Chain.Address

  def render("fee_payments.json", %{fee_payments: fee_payments, next_page_params: next_page_params}) do
    %{"items" => Enum.map(fee_payments, &prepare_fee_payment(&1, nil)), "next_page_params" => next_page_params}
  end

  def prepare_fee_payment(fee_payments, _conn) do

    %{
      "to_address" => Address.checksum(fee_payments.to_address_hash),
      "value" => fee_payments.value,
      "block_number" => fee_payments.block_number,
      "block_hash" => fee_payments.block_hash,
      "index" => fee_payments.index
    }
  end

end
