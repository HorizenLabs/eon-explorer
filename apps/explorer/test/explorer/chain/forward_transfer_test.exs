defmodule Explorer.Chain.ForwardTransferTest do
  use Explorer.DataCase

  import Explorer.Factory

  alias Ecto.Changeset
  alias Explorer.Chain.ForwardTransfer

  describe "add_hashes" do
    test "with valid attributes" do
      block = build(:block, number: 11)
      assert block.number == 11
      fwt = build(:forward_transfer, block_number: 11)
      assert fwt.block_number == 11
      forward_transfers = ForwardTransfer.add_block_hashes([fwt], [block])
      assert hd(forward_transfers).block_hash == block.hash
    end
  end
end
