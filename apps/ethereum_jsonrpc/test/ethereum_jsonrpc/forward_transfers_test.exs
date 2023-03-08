defmodule EthereumJSONRPC.ForwardTransfersTest do
  use ExUnit.Case, async: true
  use EthereumJSONRPC.Case

  import EthereumJSONRPC, only: [integer_to_quantity: 1]
  import Mox

  require Logger

  alias EthereumJSONRPC.ForwardTransfers

  setup :verify_on_exit!

  describe "utilities" do
    test "format_and_flatten" do
      ft_responses =
        {:ok,
         [
           %{
             id: 0,
             result: %{
               "forwardTransfers" => [
                 %{"to" => "0x5302c1375912f56a78e15802f30c693c4eae80b5", "value" => "0x713e24c4373000"}
               ]
             }
           },
           %{
             id: 1,
             result: %{
               "forwardTransfers" => [
                 %{"to" => "0x74d254e22fcb4e8d021320b9d4fdfd54134735b1", "value" => "0x713e24c43730000"}
               ]
             }
           }
         ]}

      id_to_params = %{0 => %{number: 346_087}, 1 => %{number: 346_088}}

      expected = [
        %{
          block_number: 346_087,
          to_address_hash: "0x5302c1375912f56a78e15802f30c693c4eae80b5",
          value: 510_000_000_000_000_000
        }
        %{
          block_number: 346_088,
          to_address_hash: "0x74d254e22fcb4e8d021320b9d4fdfd54134735b1",
          value: 510_000_000_000_000_000
        }
      ]

      result = ForwardTransfers.format_and_flatten(ft_responses, id_to_params)
      assert expected == result
    end
  end

  describe "fetch/2" do
    test "with forward_transfers", %{json_rpc_named_arguments: json_rpc_named_arguments} do
      [
        %{
          block_number: block_number_1,
          to_address_hash: to_address_hash,
          value: value
        },
        %{
          block_number: block_number_2,
          to_address_hash: to_address_hash,
          value: value
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
                value: 510_000_000_000_000_000
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
                     "value" => "0x713e24c43730000"
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
                     "value" => "0x713e24c43730000"
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
                 value: ^value
               },
               %{
                 block_number: ^block_number_2,
                 to_address_hash: ^to_address_hash,
                 value: ^value
               }
             ] =
               ForwardTransfers.fetch(
                 346_087..346_088,
                 json_rpc_named_arguments
               )
    end
  end
end
