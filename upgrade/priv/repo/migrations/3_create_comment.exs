defmodule Upgrade.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :body, :text
      add :user_id, references(:users)

      timestamps
    end
    create index(:comments, [:user_id])

  end
end
