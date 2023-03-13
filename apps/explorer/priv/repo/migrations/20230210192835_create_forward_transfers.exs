defmodule Explorer.Repo.Migrations.CreateForwardTransfers do
  use Ecto.Migration

  def change do
    create table(:forward_transfers, primary_key: true) do
      add(:to_address_hash, :string, null: false)
      add(:value, :bigint, null: false)
      add(:block_number, :bigint, null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end

  end
end
