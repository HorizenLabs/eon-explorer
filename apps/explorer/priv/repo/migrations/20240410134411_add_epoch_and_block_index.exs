defmodule Explorer.Repo.Migrations.AddEpochAndBlockIndex do
  use Ecto.Migration

  def change do
    alter table(:blocks) do
      add(:epoch, :bigint, null: true)
      add(:slot_number, :bigint, null: true)
    end
  end
end
