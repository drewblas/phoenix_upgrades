defmodule Upgrade.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :text
      add :tags, {:array, :string}
      add :user_id, references(:users)

      timestamps
    end
    create index(:posts, [:user_id])

  end
end
