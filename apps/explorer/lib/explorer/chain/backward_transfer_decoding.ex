defmodule BackwardTransfersDecoding do
  @moduledoc """
  Decodes backward transfers from blockchain transactions.

  This module is responsible for handling the decoding of backward transfers, including the conversion of public key hashes to addresses and the interaction with the blockchain's native contract for backward transfers. It utilizes predefined ABI for the smart contract interactions and processes transactions to determine the correct address format based on the network's mainnet or testnet configuration.

  ## Functionality

  - `pub_key_hash_to_addr/1`: Converts a public key hash into a blockchain address, prepending the appropriate network prefix.
  - `backward_transfer_contract_address/0`: Returns the predefined address for the backward transfer contract.
  - `backward_transfer_abi/0`: Provides the ABI for interacting with the backward transfer native contract.

  The module leverages environment variables to determine network settings (mainnet or testnet) and applies specific logic based on these settings for address conversion.
  """

  @backward_transfer_contract_address <<
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    17,
    17,
    17,
    17,
    17,
    17,
    17,
    17,
    17,
    17
  >>

  defp pub_key_hash_prefix do
    # from zencash: https://github.com/HorizenOfficial/zencashjs/blob/master/lib/config.js#L23
    is_mainnet = System.get_env("IS_MAINNET") || "true"

    if is_mainnet == "true" do
      # mainnet, 2089
      <<32, 137>>
    else
      # testnet, 2098
      <<32, 152>>
    end
  end

  @backward_transfer_abi [
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

    hash_result =
      :crypto.hash(:sha256, :crypto.hash(:sha256, prepended_key))

    checksum = extract_binary_part(hash_result)

    payload_with_checksum = <<prepended_key::binary, checksum::binary>>
    Base58.encode(payload_with_checksum)
    
  end

  defp extract_binary_part(binary_data) do
    binary_part(binary_data, 0, 4)
  end

  def backward_transfer_contract_address, do: @backward_transfer_contract_address
  def backward_transfer_abi, do: @backward_transfer_abi
end
