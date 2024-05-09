defmodule Explorer.Repo.Migrations.AddFeePaymentsValueFromMcAndValueFromSc do
  use Ecto.Migration

  def change do
    alter table(:fee_payments) do
      add(:value_from_fees, :numeric, precision: 100, null: true)
      add(:value_from_mainchain, :numeric, precision: 100, null: true)
    end
  end
end
