defmodule Explorer.Chain.FeePayment do
  @moduledoc "Models a fee_payment of ZEN from Horizen MC to EVM SC."

  use Explorer.Schema

  alias Explorer.Chain.{
    Wei,
  }

  @required_attrs ~w(block_number to_address_hash value)a

  @type t :: %__MODULE__{
          block_number: :integer,
          to_address_hash: :string,
          value: Wei.t(),
        }

  @derive {Poison.Encoder,
           only: [
             :block_number,
             :value
           ]}

  @derive {Jason.Encoder,
           only: [
             :block_number,
             :value
           ]}


  schema "fee_payments" do
    field(:block_number, :integer)
    field(:value, Wei)
    field(:to_address_hash, :string)
    timestamps()
  end

  def changeset(%__MODULE__{} = fee_payment, attrs \\ %{}) do
    attrs_to_cast = @required_attrs

    fee_payment
    |> cast(attrs, attrs_to_cast)
    |> validate_required(@required_attrs)
  end


end
