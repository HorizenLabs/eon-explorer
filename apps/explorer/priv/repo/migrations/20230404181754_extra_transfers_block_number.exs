defmodule Explorer.Repo.Migrations.ExtraTransfersBlockNumber do
  use Ecto.Migration

  def change do
    insert_initial_extra_transfer_counter = """
    INSERT INTO last_fetched_counters (counter_type, value, inserted_at, updated_at)
      VALUES ('extra_transfer_block_number', 0, NOW(), NOW());
    """

    execute(insert_initial_extra_transfer_counter)
  end
end
