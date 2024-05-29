defmodule Explorer.Repo.Migrations.InternalTransactionErrorTextDatatype do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      modify(:error, :text, null: true)
    end
    alter table(:internal_transactions) do
      modify(:error, :text, null: true)
    end
  end
end
