defmodule Explorer.Repo.Migrations.ReservedAddressesTable do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do

    create table(:reserved_addresses) do
      add(:address_hash, references(:addresses, column: :hash, on_delete: :delete_all, type: :bytea), null: false)
      add(:name, :string, null: false)
      add(:is_contract, :boolean, null: true)
      add(:inserted_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP"))
      add(:updated_at, :utc_datetime, default: fragment("CURRENT_TIMESTAMP"))
    end

    create(unique_index(:reserved_addresses, :address_hash))
  end

  def down do
    drop(unique_index(:reserved_addresses, :address_hash))
    drop(table(:reserved_addresses))
  end

end
