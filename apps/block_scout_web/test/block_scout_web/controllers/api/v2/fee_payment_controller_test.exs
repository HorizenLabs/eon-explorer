defmodule BlockScoutWeb.API.V2.FeePaymentControllerTest do
  use BlockScoutWeb.ConnCase

  alias Explorer.Chain.{Address, Block, FeePayment, Wei}
  alias Explorer.Repo

  describe "/fee-payment" do

    test "get empty list", %{conn: conn} do
      request = get(conn, "/api/v2/fee-payments")
      assert response = json_response(request, 200)
      assert response["items"] == []
      assert response["next_page_params"] == nil
    end

    test "get fee payments", %{conn: conn} do
      fee_payments = insert_list(3, :fee_payment)
      [fee_payment | _] = Enum.reverse(fee_payments)

      request = get(conn, "/api/v2/fee-payments")
      assert response = json_response(request, 200)
      assert Enum.count(response["items"]) == 3
      assert response["next_page_params"] == nil
      compare_item(fee_payment, Enum.at(response["items"], 0))

      request = get(conn, "/api/v2/fee-payments")
      assert response_1 = json_response(request, 200)
      assert response_1 == response
    end

    test "get fee payments with working next_page_params", %{conn: conn} do
      fee_payments = insert_list(51, :fee_payment)

      request = get(conn, "/api/v2/fee-payments")
      assert response = json_response(request, 200)

      request_2nd_page = get(conn, "/api/v2/fee-payments", response["next_page_params"])
      assert response_2nd_page = json_response(request_2nd_page, 200)

      check_paginated_response(response, response_2nd_page, fee_payments)

      request_1 = get(conn, "/api/v2/fee-payments")
      assert response_1 = json_response(request_1, 200)

      assert response_1 == response

      request_2 = get(conn, "/api/v2/fee-payments", response_1["next_page_params"])
      assert response_2 = json_response(request_2, 200)
      assert response_2 == response_2nd_page
    end

  end

  defp compare_item(%FeePayment{} = fee_payment, json) do
    assert fee_payment.index == json["index"]
    assert Address.checksum(fee_payment.to_address_hash) == json["to_address"]
    assert fee_payment.block_number == json["block_number"]
    assert to_string(fee_payment.block_hash) == json["block_hash"]
    assert Wei.cast(json["value"]) == {:ok, fee_payment.value}
    assert Jason.encode!(Repo.get_by(Block, hash: fee_payment.block_hash).timestamp) =~ String.replace(json["timestamp"], "Z", "")
  end

  defp check_paginated_response(first_page_resp, second_page_resp, list) do
    assert Enum.count(first_page_resp["items"]) == 50
    assert first_page_resp["next_page_params"] != nil
    compare_item(Enum.at(list, 50), Enum.at(first_page_resp["items"], 0))
    compare_item(Enum.at(list, 1), Enum.at(first_page_resp["items"], 49))

    assert Enum.count(second_page_resp["items"]) == 1
    assert second_page_resp["next_page_params"] == nil
    compare_item(Enum.at(list, 0), Enum.at(second_page_resp["items"], 0))
  end
end
