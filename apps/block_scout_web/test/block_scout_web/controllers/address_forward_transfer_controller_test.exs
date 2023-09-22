defmodule BlockScoutWeb.AddressForwardTransferControllerTest do
  use BlockScoutWeb.ConnCase, async: true
  use ExUnit.Case, async: false

  import Ecto.Query

  import BlockScoutWeb.WebRouter.Helpers, only: [address_forward_transfer_path: 3, address_forward_transfer_path: 4]
  import Mox

  alias Explorer.Chain.{Address, ForwardTransfer}
  alias Explorer.ExchangeRates.Token

  setup :verify_on_exit!

  describe "GET index/2" do
    setup :set_mox_global

    setup do
      configuration = Application.get_env(:explorer, :checksum_function)
      Application.put_env(:explorer, :checksum_function, :eth)

      :ok

      on_exit(fn ->
        Application.put_env(:explorer, :checksum_function, configuration)
      end)
    end

    test "with invalid address hash", %{conn: conn} do
      conn = get(conn, address_forward_transfer_path(conn, :index, "invalid_address"))

      assert html_response(conn, 422)
    end

    test "with valid address hash without address in the DB", %{conn: conn} do
      conn =
        get(
          conn,
          address_forward_transfer_path(conn, :index, Address.checksum("0x8bf38d4764929064f2d4d3a56520a76ab3df415b"), %{
            "type" => "JSON"
          })
        )

      assert json_response(conn, 200)
      forward_transfer_tiles = json_response(conn, 200)["items"]
      assert forward_transfer_tiles |> length() == 0
    end

    test "returns forward_transfers for the address", %{conn: conn} do
      address = insert(:address)

      block = insert(:block)

      ft = insert(:forward_transfer, to_address_hash: address.hash, block_number: block.number, block_hash: block.hash)

      another_ft = insert(:forward_transfer, to_address_hash: address.hash, block_number: block.number, block_hash: block.hash, index: 1)

      conn = get(conn, address_forward_transfer_path(conn, :index, Address.checksum(address), %{"type" => "JSON"}))

      forward_transfer_tiles = json_response(conn, 200)["items"]
      forward_transfer_hashes = Enum.map([ft.to_address_hash, another_ft.to_address_hash], &to_string(&1))

      assert Enum.all?(forward_transfer_hashes, fn forward_transfer_hash ->
               Enum.any?(forward_transfer_tiles, &String.contains?(&1, forward_transfer_hash))
             end)
    end
    test "returns next page of results based on last seen transaction", %{conn: conn} do
      address = insert(:address)

      oldest_block = insert(:block)

      blocks =
        50
        |> insert_list(:block)


      second_page_fts =
        Enum.map(blocks, & insert(:forward_transfer, to_address_hash: address.hash, block_number: &1.number, block_hash: &1.hash, index: Enum.random(0..9)))


      %ForwardTransfer{block_number: oldest_block_number, index: oldest_index} =
        :forward_transfer
        |> insert(to_address_hash: address.hash, block_number: oldest_block.number, block_hash: oldest_block.hash, index: Enum.random(0..9))


      conn =
        get(conn, address_forward_transfer_path(BlockScoutWeb.Endpoint, :index, Address.checksum(address.hash)), %{
          "block_number" => Integer.to_string(oldest_block_number),
          "index" => Integer.to_string(oldest_index),
          "type" => "JSON"
        })

      transaction_tiles = json_response(conn, 200)["items"]

      assert Enum.all?(second_page_fts, fn ft ->
               Enum.any?(transaction_tiles, &String.contains?(&1, to_string(ft.to_address_hash)))
             end)
    end
end
end
