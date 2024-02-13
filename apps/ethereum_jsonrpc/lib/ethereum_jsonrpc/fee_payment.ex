defmodule EthereumJSONRPC.FeePayment do
  @moduledoc """
  Defines the structure and types for handling fee payment data in EON transactions.

  This module specifies the data types for fee payments associated with EON transactions, facilitating the conversion and processing of fee payment data within the application. It serves as a schema for representing fee payment information in a structured and consistent manner.

  ## Types

    - `t`: Represents the raw data structure for a fee payment as received from the blockchain.
    - `elixir`: A structured representation of the fee payment data suitable for use within Elixir applications.
    - `params`: A simplified map format that outlines the essential fields of a fee payment, such as the block number, recipient address, and value of the payment.
  """

  alias EthereumJSONRPC

  @type t :: %{
          String.t() =>
            EthereumJSONRPC.address()
            | EthereumJSONRPC.quantity()
            | String.t()
        }

  @type elixir :: %{
          String.t() => EthereumJSONRPC.address() | String.t() | non_neg_integer()
        }

  @type params :: %{
          block_number: non_neg_integer(),
          to_address_hash: EthereumJSONRPC.address(),
          value: non_neg_integer()
        }
end
