defmodule EthereumJSONRPC.ReceiptTest do
  use ExUnit.Case, async: true

  alias EthereumJSONRPC.Receipt

  doctest Receipt

  describe "to_elixir/1" do
    test "with new key raise ArgumentError with full receipt" do
      assert_raise ArgumentError,
                   """
                   Could not convert receipt to elixir

                   Receipt:
                     %{"new_key" => "new_value", "transactionHash" => "0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060"}

                   Errors:
                     {:unknown_key, %{key: "new_key", value: "new_value"}}
                   """,
                   fn ->
                     Receipt.to_elixir(%{
                       "new_key" => "new_value",
                       "transactionHash" => "0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060"
                     })
                   end
    end

    # Regression test for https://github.com/poanetwork/blockscout/issues/638
    test ~s|"status" => nil is treated the same as no status| do
      assert Receipt.to_elixir(%{"status" => nil, "transactionHash" => "0x0"}) == %{"transactionHash" => "0x0"}
    end
  end

  test "leaves nil if blockNumber is nil" do
    assert Receipt.to_elixir(%{"blockNumber" => nil, "transactionHash" => "0x0"}) == %{
             "transactionHash" => "0x0",
             "blockNumber" => nil
           }
  end

  describe "elixir_to_params/1" do
    test "handles contract address" do
      assert EthereumJSONRPC.Receipt.elixir_to_params(%{
               "cumulativeGasUsed" => 21000,
               "effectiveGasPrice" => "0x59682f07",
               "from" => "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
               "gas" => 21000,
               "gasUsed" => 21000,
               "logs" => [],
               "logsBloom" =>
                 "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
               "status" => :ok,
               "contractAddress" => "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
               "transactionHash" => "0xb8dedadedf168a7fcc2c19d77e7733d732fa0c31ef5898226139b7ef9432679f",
               "transactionIndex" => 0,
               "type" => "0x02"
             }) ==
             %{
              cumulative_gas_used: 21000,
              gas_used: 21000,
              created_contract_address_hash: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
              status: :ok,
              transaction_hash: "0xb8dedadedf168a7fcc2c19d77e7733d732fa0c31ef5898226139b7ef9432679f",
              transaction_index: 0
            }
    end
    test "handles no contract address" do
      assert EthereumJSONRPC.Receipt.elixir_to_params(%{
               "cumulativeGasUsed" => 21000,
               "effectiveGasPrice" => "0x59682f07",
               "from" => "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
               "gas" => 21000,
               "gasUsed" => 21000,
               "logs" => [],
               "logsBloom" =>
                 "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
               "status" => :ok,
               "transactionHash" => "0xb8dedadedf168a7fcc2c19d77e7733d732fa0c31ef5898226139b7ef9432679f",
               "transactionIndex" => 0,
               "type" => "0x02"
             }) ==
             %{
              cumulative_gas_used: 21000,
              gas_used: 21000,
              created_contract_address_hash: nil,
              status: :ok,
              transaction_hash: "0xb8dedadedf168a7fcc2c19d77e7733d732fa0c31ef5898226139b7ef9432679f",
              transaction_index: 0
            }
    end
  end
end
