defmodule BlockScoutWeb.AddressFeePaymentControllerTest do
  use BlockScoutWeb.ConnCase, async: true
  use ExUnit.Case, async: false

  import Ecto.Query

  import BlockScoutWeb.WebRouter.Helpers, only: [address_fee_payment_path: 3, address_fee_payment_path: 4]
  import Mox

  alias Explorer.Chain.{Address, FeePayment}
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
      conn = get(conn, address_fee_payment_path(conn, :index, "invalid_address"))

      assert html_response(conn, 422)
    end

    test "with valid address hash without address in the DB", %{conn: conn} do
      conn =
        get(
          conn,
          address_fee_payment_path(conn, :index, Address.checksum("0x8bf38d4764929064f2d4d3a56520a76ab3df415b"), %{
            "type" => "JSON"
          })
        )

      assert json_response(conn, 200)
      fee_payment_tiles = json_response(conn, 200)["items"]
      assert fee_payment_tiles |> length() == 0
    end

    test "returns fee_payments for the address", %{conn: conn} do
      address = insert(:address)

      block = insert(:block)

      fp = insert(:fee_payment, to_address_hash: address.hash, block_number: block.number, block_hash: block.hash)

      another_fp =
        insert(:fee_payment, to_address_hash: address.hash, block_number: block.number, block_hash: block.hash, index: 1)

      conn = get(conn, address_fee_payment_path(conn, :index, Address.checksum(address), %{"type" => "JSON"}))

      fee_payment_tiles = json_response(conn, 200)["items"]
      fee_payment_hashes = Enum.map([fp.to_address_hash, another_fp.to_address_hash], &to_string(&1))

      assert Enum.all?(fee_payment_hashes, fn fee_payment_hash ->
               Enum.any?(fee_payment_tiles, &String.contains?(&1, fee_payment_hash))
             end)
    end

    test "returns next page of results based on last seen transaction", %{conn: conn} do
      address = insert(:address)

      # blocks are in oldest to newest order
      blocks =
        50
        |> insert_list(:block)

      second_page_fps =
        Enum.map(
          blocks,
          &insert(:fee_payment,
            to_address_hash: address.hash,
            block_number: &1.number,
            block_hash: &1.hash,
            index: Enum.random(0..9)
          )
        )

      # add one more, this will be the newest, 51st, we will pretend it page one's last entry
      last_pg1_block = insert(:block)

      %FeePayment{block_number: last_pg1_block_number, index: last_pg1_index} =
        :fee_payment
        |> insert(
          to_address_hash: address.hash,
          block_number: last_pg1_block.number,
          block_hash: last_pg1_block.hash,
          index: Enum.random(0..9)
        )

      conn =
        get(conn, address_fee_payment_path(BlockScoutWeb.Endpoint, :index, Address.checksum(address.hash)), %{
          "block_number" => Integer.to_string(last_pg1_block_number),
          "index" => Integer.to_string(last_pg1_index),
          "type" => "JSON"
        })

      fee_payment_tiles = json_response(conn, 200)["items"]

      second_page_fp_block_numbers =
        Enum.map(second_page_fps, fn second_page_fp -> to_string(second_page_fp.block_number) end)

      # expect page two to be entries for second_page_blocks
      assert Enum.all?(second_page_fp_block_numbers, fn fee_payment_block_number ->
               Enum.any?(fee_payment_tiles, &String.contains?(&1, fee_payment_block_number))
             end)
    end
  end
end
