defmodule Explorer.Repo.Migrations.NativeContractsAddressName do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute("INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000011111111111111111111', 'Withdrawal Request', true, NOW(), NOW())")
    execute("INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000022222222222222222222', 'Forger Stake', true, NOW(), NOW())")
    execute("INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000044444444444444444444', 'Certificate Key Rotation', true, NOW(), NOW())")
    execute("INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000088888888888888888888', 'Mainchain Address Ownership', true, NOW(), NOW())")
  end

end
