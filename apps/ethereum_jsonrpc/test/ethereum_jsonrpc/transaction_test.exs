defmodule EthereumJSONRPC.TransactionTest do
  use ExUnit.Case, async: true

  doctest EthereumJSONRPC.Transaction

  alias EthereumJSONRPC.Transaction

  describe "to_elixir/1" do
    test "skips unsupported keys" do
      map = %{"key" => "value", "key1" => "value1"}

      assert %{nil: nil} = Transaction.to_elixir(map)
    end
  end


  describe "elixir_to_params/1" do
    test "handles to field" do
      assert EthereumJSONRPC.Transaction.elixir_to_params(%{
               "blockHash" => "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
               "blockNumber" => 99471,
               "chainId" => 1661,
               "from" => "0x72661045ba9483edd3fede4a73688605b51d40c0",
               "gas" => 72281,
               "gasPrice" => 2_500_000_007,
               "hash" => "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
               "input" =>
                 "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
               "maxFeePerGas" => 2_500_000_014,
               "maxPriorityFeePerGas" => 2_500_000_000,
               "nonce" => 27,
               "r" =>
                 53_831_856_565_103_535_398_436_018_449_944_465_608_690_895_675_071_425_783_072_041_632_110_090_104_144,
               "s" =>
                 31_015_273_762_438_762_440_725_115_906_686_828_078_457_886_252_017_577_082_206_483_297_318_718_115_247,
               "transactionIndex" => 0,
               "to" => "0x5df9b87991262f6ba471f09758cde1c0fc1de734",
               "type" => 2,
               "v" => 27,
               "value" => 0
             }) == %{
              block_hash: "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
              block_number: 99471,
              from_address_hash: "0x72661045ba9483edd3fede4a73688605b51d40c0",
              gas: 72281,
              gas_price: 2500000007,
              hash: "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
              index: 0,
              input: "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
              max_fee_per_gas: 2500000014,
              max_priority_fee_per_gas: 2500000000,
              nonce: 27,
              r: 53831856565103535398436018449944465608690895675071425783072041632110090104144,
              s: 31015273762438762440725115906686828078457886252017577082206483297318718115247,
              to_address_hash: "0x5df9b87991262f6ba471f09758cde1c0fc1de734",
              transaction_index: 0,
              type: 2,
              v: 27,
              value: 0
            }
    end

    test "handles omitted to field" do
      assert EthereumJSONRPC.Transaction.elixir_to_params(%{
               "blockHash" => "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
               "blockNumber" => 99471,
               "chainId" => 1661,
               "from" => "0x72661045ba9483edd3fede4a73688605b51d40c0",
               "gas" => 72281,
               "gasPrice" => 2_500_000_007,
               "hash" => "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
               "input" =>
                 "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
               "maxFeePerGas" => 2_500_000_014,
               "maxPriorityFeePerGas" => 2_500_000_000,
               "nonce" => 27,
               "r" =>
                 53_831_856_565_103_535_398_436_018_449_944_465_608_690_895_675_071_425_783_072_041_632_110_090_104_144,
               "s" =>
                 31_015_273_762_438_762_440_725_115_906_686_828_078_457_886_252_017_577_082_206_483_297_318_718_115_247,
               "transactionIndex" => 0,
               "type" => 2,
               "v" => 27,
               "value" => 0
             }) == %{
              block_hash: "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
              block_number: 99471,
              from_address_hash: "0x72661045ba9483edd3fede4a73688605b51d40c0",
              gas: 72281,
              gas_price: 2500000007,
              hash: "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
              index: 0,
              input: "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
              max_fee_per_gas: 2500000014,
              max_priority_fee_per_gas: 2500000000,
              nonce: 27,
              r: 53831856565103535398436018449944465608690895675071425783072041632110090104144,
              s: 31015273762438762440725115906686828078457886252017577082206483297318718115247,
              to_address_hash: nil,
              transaction_index: 0,
              type: 2,
              v: 27,
              value: 0
            }
    end

    test "handles omitted to field with pre-london txs" do
      assert EthereumJSONRPC.Transaction.elixir_to_params(%{
               "blockHash" => "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
               "blockNumber" => 99471,
               "chainId" => 1661,
               "from" => "0x72661045ba9483edd3fede4a73688605b51d40c0",
               "gas" => 72281,
               "gasPrice" => 2_500_000_007,
               "hash" => "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
               "input" =>
                 "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
               "nonce" => 27,
               "r" =>
                 53_831_856_565_103_535_398_436_018_449_944_465_608_690_895_675_071_425_783_072_041_632_110_090_104_144,
               "s" =>
                 31_015_273_762_438_762_440_725_115_906_686_828_078_457_886_252_017_577_082_206_483_297_318_718_115_247,
               "transactionIndex" => 0,
               "type" => 2,
               "v" => 27,
               "value" => 0
             }) == %{
              block_hash: "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
              block_number: 99471,
              from_address_hash: "0x72661045ba9483edd3fede4a73688605b51d40c0",
              gas: 72281,
              gas_price: 2500000007,
              hash: "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
              index: 0,
              input: "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
              nonce: 27,
              r: 53831856565103535398436018449944465608690895675071425783072041632110090104144,
              s: 31015273762438762440725115906686828078457886252017577082206483297318718115247,
              to_address_hash: nil,
              transaction_index: 0,
              type: 2,
              v: 27,
              value: 0
            }
    end

    test "handles pre-london txs" do
      assert EthereumJSONRPC.Transaction.elixir_to_params(%{
               "blockHash" => "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
               "blockNumber" => 99471,
               "chainId" => 1661,
               "from" => "0x72661045ba9483edd3fede4a73688605b51d40c0",
               "gas" => 72281,
               "gasPrice" => 2_500_000_007,
               "hash" => "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
               "input" =>
                 "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
               "nonce" => 27,
               "r" =>
                 53_831_856_565_103_535_398_436_018_449_944_465_608_690_895_675_071_425_783_072_041_632_110_090_104_144,
               "s" =>
                 31_015_273_762_438_762_440_725_115_906_686_828_078_457_886_252_017_577_082_206_483_297_318_718_115_247,
               "transactionIndex" => 0,
               "to" => "0x5df9b87991262f6ba471f09758cde1c0fc1de734",
               "type" => 2,
               "v" => 27,
               "value" => 0
             }) == %{
              block_hash: "0xf34e557a80b8419eb6ae50350000565360311f39d8392e2ddb188d85e73eb90b",
              block_number: 99471,
              from_address_hash: "0x72661045ba9483edd3fede4a73688605b51d40c0",
              gas: 72281,
              gas_price: 2500000007,
              hash: "0x208ea0cb83f14a28ce27de8cda7ad12db804fbe73edc4cd877572fcf49f05944",
              index: 0,
              input: "0x60566050600b82828239805160001a6073146043577f4e487b7100000000000000000000000000000000000000000000000000000000600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea264697066735822122097cdd4e635e1c12ad4e6be57d0d94c85f5ba1d9994fa407db368c6b21c24594664736f6c63430008070033",
              nonce: 27,
              r: 53831856565103535398436018449944465608690895675071425783072041632110090104144,
              s: 31015273762438762440725115906686828078457886252017577082206483297318718115247,
              to_address_hash: "0x5df9b87991262f6ba471f09758cde1c0fc1de734",
              transaction_index: 0,
              type: 2,
              v: 27,
              value: 0
            }
    end
  end
end
