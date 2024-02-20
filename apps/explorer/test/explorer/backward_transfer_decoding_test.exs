defmodule BackwardTransfersDecodingTest do
  use ExUnit.Case
  import BackwardTransfersDecoding

  import Explorer.Chain.Transaction

  test "pub_key_hash_to_addr converts public key hash to address" do
    pub_key_hash = <<80, 123, 144, 240, 20, 80, 54, 168, 59, 92, 137, 79, 81, 132, 243, 71, 48, 230, 11, 240>>
    expected_prefix = <<32, 152>>

    expected_address = "ztaVWqvnzQ7cC58rC94UB1VpMzfv5Cpvts4"
    assert pub_key_hash_to_addr(pub_key_hash) == expected_address
  end

  test "backward_transfer_contract_address returns the correct address" do
    expected_address = <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17>>

    assert backward_transfer_contract_address() == expected_address
  end

  test "backward_transfer_ABI returns the ABI" do
    expected_abi = [
      %{
        "type" => "function",
        "name" => "backwardTransfer",
        "stateMutability" => "payable",
        "payable" => true,
        "constant" => false,
        "inputs" => [
          %{"type" => "bytes20", "name" => "mcAddress"}
        ],
        "outputs" => [
          %{
            "type" => "tuple",
            "components" => [
              %{"type" => "bytes20", "name" => "mcAddress"},
              %{"type" => "uint256", "name" => "amount"}
            ]
          }
        ]
      },
      %{
        "type" => "event",
        "anonymous" => false,
        "name" => "AddWithdrawalRequest",
        "inputs" => [
          %{"name" => "from", "type" => "address", "indexed" => true},
          %{"name" => "mcDest", "type" => "bytes20", "indexed" => true},
          %{"name" => "value", "type" => "uint256", "indexed" => false},
          %{"name" => "epochNumber", "type" => "uint32", "indexed" => false}
        ]
      }
    ]

    assert backward_transfer_abi() == expected_abi
  end

  test "decoded_input_data returns expected output" do
    input_data = %Explorer.Chain.Transaction{
      input: %{
        bytes:
          <<66, 103, 236, 94, 80, 123, 144, 240, 20, 80, 54, 168, 59, 92, 137, 79, 81, 132, 243, 71, 48, 230, 11, 240,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
      },
      hash: %Explorer.Chain.Hash{
        byte_count: 32,
        bytes:
          <<117, 221, 76, 112, 42, 234, 190, 2, 176, 77, 83, 55, 124, 152, 185, 44, 78, 59, 23, 240, 46, 17, 105, 68,
            243, 35, 34, 230, 192, 177, 135, 219>>
      },
      to_address: %{
        hash: %Explorer.Chain.Hash{
          byte_count: 20,
          bytes: backward_transfer_contract_address()
        }
      }
    }

    expected_output = {
      {:ok, "4267ec5e", "backwardTransfer(bytes20 mcAddress)",
       [
         {"decoded mcAddress", "string", "ztaVWqvnzQ7cC58rC94UB1VpMzfv5Cpvts4"},
         {"mcAddress", "bytes20",
          <<80, 123, 144, 240, 20, 80, 54, 168, 59, 92, 137, 79, 81, 132, 243, 71, 48, 230, 11, 240>>}
       ]},
      %{},
      %{}
    }

    assert decoded_input_data(input_data, %{}, %{}, %{}, %{}) == expected_output
  end
end
