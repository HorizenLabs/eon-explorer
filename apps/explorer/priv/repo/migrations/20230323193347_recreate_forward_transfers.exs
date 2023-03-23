defmodule Explorer.Repo.Migrations.RecreateForwardTransfers do
  use Ecto.Migration

  def change do
    drop_if_exists(table(:forward_transfers))
    create table(:forward_transfers, primary_key: true) do
      add(:to_address_hash, :string, null: false)
      add(:value, :numeric, precision: 100, null: false)
      add(:block_number, :bigint, null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end
  end
end
