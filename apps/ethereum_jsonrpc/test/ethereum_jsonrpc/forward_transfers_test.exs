defmodule EthereumJSONRPC.ForwardTransfersTest do
  use ExUnit.Case, async: true
  use EthereumJSONRPC.Case

  import EthereumJSONRPC, only: [integer_to_quantity: 1, quantity_to_integer: 1]
  import Mox

  require Logger

  alias EthereumJSONRPC.ForwardTransfers

  setup :verify_on_exit!

  describe "utilities" do
    test "format_and_flatten" do
      value_string_1 = "0x713e24c43730000"
      value_string_2 = "0x713e24c43730001"

      ft_responses =
        {:ok,
         [
           %{
             id: 0,
             result: %{
               "forwardTransfers" => [
                 %{"to" => "0x5302c1375912f56a78e15802f30c693c4eae80b5", "value" => value_string_1},
                 %{"to" => "0x5302c1375912f56a78e15802f30c693c4eae80b5", "value" => value_string_1}
               ]
             }
           },
           %{
             id: 1,
             result: %{
               "forwardTransfers" => [
                 %{"to" => "0x74d254e22fcb4e8d021320b9d4fdfd54134735b1", "value" => value_string_2},
                 %{"to" => "0x74d254e22fcb4e8d021320b9d4fdfd54134735b1", "value" => value_string_2}
               ]
             }
           }
         ]}

      id_to_params = %{0 => %{number: 346_087}, 1 => %{number: 346_088}}

      expected = [
        %{
          block_number: 346_087,
          to_address_hash: "0x5302c1375912f56a78e15802f30c693c4eae80b5",
          value: quantity_to_integer(value_string_1),
          index: 0
        },
        %{
          block_number: 346_087,
          to_address_hash: "0x5302c1375912f56a78e15802f30c693c4eae80b5",
          value: quantity_to_integer(value_string_1),
          index: 1
        },
        %{
          block_number: 346_088,
          to_address_hash: "0x74d254e22fcb4e8d021320b9d4fdfd54134735b1",
          value: quantity_to_integer(value_string_2),
          index: 0
        },
        %{
          block_number: 346_088,
          to_address_hash: "0x74d254e22fcb4e8d021320b9d4fdfd54134735b1",
          value: quantity_to_integer(value_string_2),
          index: 1
        }
      ]

      result = ForwardTransfers.format_and_flatten(ft_responses, id_to_params)
      assert expected == result
    end
  end

  describe "fetch/2" do
    test "with forward_transfers", %{json_rpc_named_arguments: json_rpc_named_arguments} do
      value_string_1 = "0x713e24c43730000"
      value_string_2 = "0x713e24c43730001"

      [
        %{
          block_number: block_number_1,
          to_address_hash: to_address_hash,
          value: value_1
        },
        %{
          block_number: block_number_2,
          to_address_hash: to_address_hash,
          value: value_2
        }
      ] =
        case Keyword.fetch!(json_rpc_named_arguments, :variant) do
          EthereumJSONRPC.Geth ->
            [
              %{
                block_number: 346_087,
                to_address_hash: "0x5302c1375912f56a78e15802f30c693c4eae80b5",
                value: 510_000_000_000_000_000
              },
              %{
                block_number: 346_088,
                to_address_hash: "0x5302c1375912f56a78e15802f30c693c4eae80b5",
                value: 510_000_000_000_000_001
              }
            ]
        end

      if json_rpc_named_arguments[:transport] == EthereumJSONRPC.Mox do
        expect(EthereumJSONRPC.Mox, :json_rpc, fn _json, _options ->
          {:ok,
           [
             %{
               id: 0,
               result: %{
                 "forwardTransfers" => [
                   %{
                     "to" => "0x5302c1375912f56a78e15802f30c693c4eae80b5",
                     "value" => value_string_1
                   }
                 ]
               }
             },
             %{
               id: 1,
               result: %{
                 "forwardTransfers" => [
                   %{
                     "to" => "0x5302c1375912f56a78e15802f30c693c4eae80b5",
                     "value" => value_string_2
                   }
                 ]
               }
             }
           ]}
        end)
      end

      assert [
               %{
                 block_number: ^block_number_1,
                 to_address_hash: ^to_address_hash,
                 value: ^value_1,
                 index: 0
               },
               %{
                 block_number: ^block_number_2,
                 to_address_hash: ^to_address_hash,
                 value: ^value_2,
                 index: 0
               }
             ] =
               ForwardTransfers.fetch(
                 346_087..346_088,
                 json_rpc_named_arguments
               )
    end
  end
end
