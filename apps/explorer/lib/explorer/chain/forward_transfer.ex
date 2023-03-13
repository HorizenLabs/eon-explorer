defmodule Explorer.Chain.ForwardTransfer do
  @moduledoc "Models a forward_transfer of ZEN from Horizen MC to EVM SC."

  use Explorer.Schema

  @required_attrs ~w(block_number to_address_hash value)a

  @type t :: %__MODULE__{
          block_number: :integer,
          to_address_hash: :string,
          value: :integer,
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


  schema "forward_transfers" do
    field(:block_number, :integer)
    field(:value, :integer)
    field(:to_address_hash, :string)
    timestamps()
  end

  def changeset(%__MODULE__{} = forward_transfer, attrs \\ %{}) do
    attrs_to_cast = @required_attrs

    forward_transfer
    |> cast(attrs, attrs_to_cast)
    |> validate_required(@required_attrs)
  end


end
