defmodule MoodleNet.Accounts do
  @moduledoc """
  The Accounts context.
  """

  # import Ecto.Query, warn: false
  alias MoodleNet.Repo
  alias Ecto.Multi

  alias MoodleNet.Accounts.{User, PasswordAuth}

  alias ActivityPub.SQL.Query

  @doc """
  Creates a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs \\ %{}) do
    # FIXME this should be a only transaction
    actor_attrs =
      attrs
      |> Map.put("type", "Person")
      |> Map.delete(:password)
      |> Map.delete("password")

    with {:ok, actor} <- ActivityPub.new(actor_attrs),
         {:ok, actor} <- ActivityPub.insert(actor) do
      actor_local_id = ActivityPub.Entity.local_id(actor)
      ch = User.changeset(actor_local_id, attrs)

      Multi.new()
      |> Multi.run(:actor, fn _, _ -> {:ok, actor} end)
      |> Multi.insert(:user, ch)
      |> Multi.run(
        :password_auth,
        &(PasswordAuth.create_changeset(&2.user.id, attrs) |> &1.insert())
      )
      |> Repo.transaction()
    end
  end

  def update_user(actor, changes) do
    {icon_url, changes} = Map.pop(changes, :icon)
    {location_content, changes} = Map.pop(changes, :location)
    icon = Query.new() |> Query.belongs_to(:icon, actor) |> Query.one()
    location = Query.new() |> Query.belongs_to(:location, actor) |> Query.one()

    # FIXME this should be a transaction
    with {:ok, _icon} <- ActivityPub.update(icon, url: icon_url),
         {:ok, _location} <- ActivityPub.update(location, content: location_content) do
      ActivityPub.update(actor, changes)
    end
  end

  def delete_user(actor) do
    # FIXME this should be a transaction
    Query.new()
    |> Query.with_type("Note")
    |> Query.has(:attributed_to, actor)
    |> Query.delete_all()

    ActivityPub.delete(actor, [:icon, :location])
    :ok
  end

  def authenticate_by_email_and_pass(email, given_pass) do
    email
    |> user_and_password_auth_query()
    |> Repo.one()
    |> case do
      nil ->
        Comeonin.Pbkdf2.dummy_checkpw()
        {:error, :not_found}

      {user, password_auth} ->
        if Comeonin.Pbkdf2.checkpw(given_pass, password_auth.password_hash),
          do: {:ok, user},
          else: {:error, :unauthorized}
    end
  end

  defp user_and_password_auth_query(email) do
    import Ecto.Query

    from(u in User,
      where: u.email == ^email,
      inner_join: p in PasswordAuth,
      on: p.user_id == u.id,
      select: {u, p}
    )
  end
end
