defmodule Explorer.Repo.Migrations.AddIndexForwardTransfersToAddressHash do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists(
      index(
        :forward_transfers,
        [:to_address_hash, "block_number DESC", "index DESC"],
        name: "forward_transfers_to_address_hash_index",
        concurrently: true
      )
    )
  end
end
