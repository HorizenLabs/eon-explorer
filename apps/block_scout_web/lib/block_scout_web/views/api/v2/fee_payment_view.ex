defmodule BlockScoutWeb.API.V2.FeePaymentView do
  use BlockScoutWeb, :view

  def render("message.json", assigns) do
    ApiView.render("message.json", assigns)
  end

  def render("fee_payments.json", %{fee_payments: fee_payments, next_page_params: next_page_params}) do
    %{"items" => Enum.map(fee_payments, &prepare_fee_payments(&1, nil)), "next_page_params" => next_page_params}
  end

  def prepare_fee_payments(fee_payments, _conn) do

    %{
      "to_address" => fee_payments.to_address_hash,
      "value" => fee_payments.value,
      "block_number" => fee_payments.block_number,
      "block_hash" => fee_payments.block_hash,
      "index" => fee_payments.index
    }
  end

end
