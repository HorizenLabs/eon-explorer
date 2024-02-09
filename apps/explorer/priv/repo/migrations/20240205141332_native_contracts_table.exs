defmodule Explorer.Repo.Migrations.NativeContractsTable do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do

    create table(:native_contracts) do
      add(:address_hash, references(:addresses, column: :hash, on_delete: :delete_all, type: :bytea), null: false)
      add(:name, :string, null: false)
      add(:inserted_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP"))
      add(:updated_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP"))
    end

    create(unique_index(:native_contracts, :address_hash))
  end

end
