defmodule Explorer.Repo.Migrations.AddEpochAndBlockIndex do
  use Ecto.Migration

  def change do
    alter table(:blocks) do
      add(:epoch, :bigint, null: true)
      add(:index, :bigint, null: true)
    end
  end
end
