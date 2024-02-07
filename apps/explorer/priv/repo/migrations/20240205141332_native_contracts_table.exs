defmodule Explorer.Repo.Migrations.NativeContractsTable do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do

    execute("CREATE TABLE native_contracts (
              hash TEXT PRIMARY KEY,
              name TEXT,
              inserted_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
              updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )")

    execute("INSERT INTO native_contracts (hash, name, inserted_at) VALUES ('0x0000000000000000000011111111111111111111', 'withdrawal request', NOW())")
    execute("INSERT INTO native_contracts (hash, name, inserted_at) VALUES ('0x0000000000000000000022222222222222222222', 'forger stake', NOW())")
    execute("INSERT INTO native_contracts (hash, name, inserted_at) VALUES ('0x0000000000000000000044444444444444444444', 'certificate key rotation', NOW())")
    execute("INSERT INTO native_contracts (hash, name, inserted_at) VALUES ('0x0000000000000000000088888888888888888888', 'mainchain address ownership', NOW())")
  end

  def down do
    execute("DROP TABLE IF EXISTS native_contracts")
  end

end
