defmodule Explorer.Repo.Migrations.AddFeePaymentsValueFromMcAndValueFromSc do
  use Ecto.Migration

  def change do
    alter table(:fee_payments) do
      add(:value_from_mc, :numeric, precision: 100, null: false)
      add(:value_from_sc, :numeric, precision: 100, null: false)
    end
  end
end
