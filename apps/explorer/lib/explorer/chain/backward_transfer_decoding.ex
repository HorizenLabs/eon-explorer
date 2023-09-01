defmodule BackwardTransfersDecoding do
  @backward_transfer_contract_address <<
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17
  >>

  defp pub_key_hash_prefix do
    # from zencash: https://github.com/HorizenOfficial/zencashjs/blob/master/lib/config.js#L23
    is_mainnet = System.get_env("IS_MAINNET") || "true"

    if is_mainnet == "true" do
      <<32, 137>> # mainnet, 2089
    else
      <<32, 152>> # testnet, 2098
    end
  end

  @backward_transfer_ABI [
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

  def pub_key_hash_to_addr(pub_key_hash) do
    env_pub_key_hash_prefix = pub_key_hash_prefix()
    prepended_key = env_pub_key_hash_prefix <> pub_key_hash
    checksum =
      :crypto.hash(:sha256, :crypto.hash(:sha256, prepended_key))
      |> binary_part(0, 4)
    payload_with_checksum = <<prepended_key::binary, checksum::binary>>
    Base58.encode(payload_with_checksum)
  end

  def backward_transfer_contract_address, do: @backward_transfer_contract_address
  def backward_transfer_ABI, do: @backward_transfer_ABI
end
