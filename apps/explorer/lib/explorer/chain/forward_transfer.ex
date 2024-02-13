defmodule Explorer.Chain.ForwardTransfer do
  @moduledoc "Models a forward_transfer of ZEN from Horizen MC to EVM SC."

  use Explorer.Schema

  alias Explorer.Chain.{
    Address,
    Block,
    Hash,
    Wei
  }

  @required_attrs ~w(block_number block_hash to_address_hash value index)a

  @type t :: %__MODULE__{
          block: %Ecto.Association.NotLoaded{} | Block.t() | nil,
          block_hash: Hash.t() | nil,
          block_number: Block.block_number() | nil,
          to_address: %Ecto.Association.NotLoaded{} | Address.t() | nil,
          to_address_hash: Hash.Address.t() | nil,
          value: Wei.t(),
          index: :integer
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

  @primary_key false
  schema "forward_transfers" do
    field(:block_number, :integer, primary_key: true)
    field(:value, Wei)
    field(:index, :integer, primary_key: true)
    timestamps()

    belongs_to(
      :block,
      Block,
      foreign_key: :block_hash,
      references: :hash,
      type: Hash.Full
    )

    belongs_to(
      :to_address,
      Address,
      foreign_key: :to_address_hash,
      references: :hash,
      type: Hash.Address
    )
  end

  def changeset(%__MODULE__{} = forward_transfer, attrs \\ %{}) do
    attrs_to_cast = @required_attrs

    forward_transfer
    |> cast(attrs, attrs_to_cast)
    |> validate_required(@required_attrs)
  end

  def add_block_hashes(fwts, blocks) do
    Enum.map(fwts, fn fwt ->
      hash =
        Enum.find(blocks, fn block ->
          block.number == fwt.block_number
        end).hash

      Map.put(fwt, :block_hash, hash)
    end)
  end
end
