defmodule Explorer.Chain.FeePayment do
  @moduledoc "Models a fee_payment of ZEN from Horizen MC to EVM SC."

  use Explorer.Schema

  alias Explorer.Chain.{
    Block,
    Wei,
    Hash,
    Address
  }

  @required_attrs ~w(block_number block_hash to_address_hash value index)a

  @type t :: %__MODULE__{
          block: %Ecto.Association.NotLoaded{} | Block.t() | nil,
          block_hash: Hash.t() | nil,
          block_number: Block.block_number() | nil,
          to_address: %Ecto.Association.NotLoaded{} | Address.t() | nil,
          to_address_hash: Hash.Address.t() | nil,
          value: Wei.t(),
          value_from_fees: Wei.t() | nil,
          value_from_mainchain: Wei.t() | nil,
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
  schema "fee_payments" do
    field(:block_number, :integer, primary_key: true)
    field(:value, Wei)
    field(:value_from_fees, Wei)
    field(:value_from_mainchain, Wei)
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

  def changeset(%__MODULE__{} = fee_payment, attrs \\ %{}) do
    attrs_to_cast = @required_attrs ++ [:value_from_fees, :value_from_mainchain]

    fee_payment
    |> cast(attrs, attrs_to_cast)
    |> validate_required(@required_attrs)
  end

  def add_block_hashes(fps, blocks) do
    Enum.map(fps, fn fp ->
      hash =
        Enum.find(blocks, fn block ->
          block.number == fp.block_number
        end).hash

      Map.put(fp, :block_hash, hash)
    end)
  end
end
