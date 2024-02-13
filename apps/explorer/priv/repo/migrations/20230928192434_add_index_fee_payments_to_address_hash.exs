defmodule Explorer.Repo.Migrations.AddIndexFeePaymentsToAddressHash do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists(
      index(
        :fee_payments,
        [:to_address_hash, "block_number DESC", "index DESC"],
        name: "fee_payments_to_address_hash_index",
        concurrently: true
      )
    )
  end
end
