defmodule EthereumJSONRPC.FeePayment do
  alias EthereumJSONRPC

  @type t :: %{
          String.t() =>
            EthereumJSONRPC.address()
            | EthereumJSONRPC.quantity()
            | String.t()
            | String.t()
            | String.t()
        }

  @type elixir :: %{
          String.t() => EthereumJSONRPC.address() | String.t() | non_neg_integer() | non_neg_integer() | non_neg_integer()
        }

  @type params :: %{
          block_number: non_neg_integer(),
          to_address_hash: EthereumJSONRPC.address(),
          value: non_neg_integer(),
          value_from_fees: non_neg_integer(),
          value_from_mainchain: non_neg_integer(),
        }
end
