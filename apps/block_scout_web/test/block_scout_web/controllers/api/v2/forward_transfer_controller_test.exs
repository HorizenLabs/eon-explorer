defmodule BlockScoutWeb.API.V2.ForwardTransferControllerTest do
  use BlockScoutWeb.ConnCase

  alias Explorer.Chain.{Address, Block, ForwardTransfer, Wei}
  alias Explorer.Repo

  describe "/forward-transfers" do

    test "get empty list", %{conn: conn} do
      request = get(conn, "/api/v2/forward-transfers")
      assert response = json_response(request, 200)
      assert response["items"] == []
      assert response["next_page_params"] == nil
    end

    test "get forward tranfers", %{conn: conn} do
      forward_transfers = insert_list(3, :forward_transfer)
      [forward_transfer | _] = Enum.reverse(forward_transfers)

      request = get(conn, "/api/v2/forward-transfers")
      assert response = json_response(request, 200)
      assert Enum.count(response["items"]) == 3
      assert response["next_page_params"] == nil
      compare_item(forward_transfer, Enum.at(response["items"], 0))

      request = get(conn, "/api/v2/forward-transfers")
      assert response_1 = json_response(request, 200)
      assert response_1 == response
    end

    test "get forward tranfers with working next_page_params", %{conn: conn} do
      forward_transfers = insert_list(51, :forward_transfer)

      request = get(conn, "/api/v2/forward-transfers")
      assert response = json_response(request, 200)

      request_2nd_page = get(conn, "/api/v2/forward-transfers", response["next_page_params"])
      assert response_2nd_page = json_response(request_2nd_page, 200)

      check_paginated_response(response, response_2nd_page, forward_transfers)

      request_1 = get(conn, "/api/v2/forward-transfers")
      assert response_1 = json_response(request_1, 200)

      assert response_1 == response

      request_2 = get(conn, "/api/v2/forward-transfers", response_1["next_page_params"])
      assert response_2 = json_response(request_2, 200)
      assert response_2 == response_2nd_page
    end

  end

  defp compare_item(%ForwardTransfer{} = forward_transfer, json) do
    assert forward_transfer.index == json["index"]
    assert Address.checksum(forward_transfer.to_address_hash) == json["to_address"]
    assert forward_transfer.block_number == json["block_number"]
    assert to_string(forward_transfer.block_hash) == json["block_hash"]
    assert Wei.cast(json["value"]) == {:ok, forward_transfer.value}
    assert Jason.encode!(Repo.get_by(Block, hash: forward_transfer.block_hash).timestamp) =~ String.replace(json["timestamp"], "Z", "")
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
