defmodule Explorer.Repo.Migrations.CreateFeePayments do
  use Ecto.Migration

  def change do
    create table(:fee_payments, primary_key: true) do
      add(:to_address_hash, :string, null: false)
      add(:value, :numeric, precision: 100, null: false)
      add(:block_number, :bigint, null: false)
      timestamps(null: false, type: :utc_datetime_usec)
    end
  end
end
