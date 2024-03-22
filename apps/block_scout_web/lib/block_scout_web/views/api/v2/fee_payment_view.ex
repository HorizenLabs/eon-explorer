defmodule BlockScoutWeb.API.V2.FeePaymentView do
  use BlockScoutWeb, :view
  alias Explorer.Chain.Address

  def render("fee_payments.json", %{fee_payments: fee_payments, next_page_params: next_page_params}) do
    %{"items" => Enum.map(fee_payments, &prepare_fee_payment(&1, nil)), "next_page_params" => next_page_params}
  end

  def prepare_fee_payment(fee_payment, _conn) do

    %{
      "to_address" => Address.checksum(fee_payment.to_address_hash),
      "value" => fee_payment.value,
      "block_number" => fee_payment.block_number,
      "block_hash" => fee_payment.block_hash,
      "index" => fee_payment.index
    }
  end

end
