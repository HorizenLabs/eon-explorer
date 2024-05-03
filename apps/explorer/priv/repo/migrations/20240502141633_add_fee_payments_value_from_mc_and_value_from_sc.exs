defmodule Explorer.Repo.Migrations.AddFeePaymentsValueFromMcAndValueFromSc do
  use Ecto.Migration

  def change do
    alter table(:fee_payments) do
      add(:value_from_mc, :numeric, precision: 100, null: true)
      add(:value_from_sc, :numeric, precision: 100, null: true)
    end
  end
end
