defmodule Explorer.Repo.Migrations.DropAndRecreateFeePayments do
  use Ecto.Migration

  def change do
    drop_if_exists(table(:fee_payments))

    create table(:fee_payments, primary_key: false) do
      add(:to_address_hash, references(:addresses, column: :hash, on_delete: :delete_all, type: :bytea), null: false)
      add(:value, :numeric, precision: 100, null: false)
      add(:block_number, :bigint, null: false, primary_key: true)
      add(:block_hash, references(:blocks, column: :hash, on_delete: :delete_all, type: :bytea), null: true)
      add(:index, :integer, null: false, primary_key: true)
      timestamps(null: false, type: :utc_datetime_usec)
    end
  end
end
