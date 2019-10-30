# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Common.Changeset do
  @moduledoc "Helper functions for changesets"

  alias Ecto.Changeset
  alias MoodleNet.Mail.Checker

  @spec validate_http_url(Changeset.t(), atom) :: Changeset.t()
  @doc "Validates that a URL uses HTTP(S) and has a correct format."
  def validate_http_url(changeset, field) do
    Changeset.validate_change(changeset, field, fn ^field, url ->
      if valid_http_uri?(URI.parse(url)) do
        []
      else
        [{field, "has an invalid URL format"}]
      end
    end)
  end

  defp valid_http_uri?(%URI{scheme: scheme, host: host, path: path}) do
    scheme in ["http", "https"] && not is_nil(host)
  end

  @spec validate_email(Changeset.t(), atom) :: Changeset.t()
  @doc "Validates an email for correctness"
  def validate_email(changeset, field) do
    with {:ok, email} <- Changeset.fetch_change(changeset, field),
         {:error, reason} <- Checker.validate_email(email) do
      message = validate_email_message(reason)
      Changeset.add_error(changeset, field, message, validation: reason)
    else
      _ -> changeset
    end
  end

  @spec validate_email_domain(Changeset.t(), atom) :: Changeset.t()
  def validate_email_domain(changeset, field) do
    with {:ok, domain} <- Changeset.fetch_change(changeset, field),
         {:error, reason} <- Checker.validate_domain(domain) do
      message = validate_email_message(reason)
      Changeset.add_error(changeset, field, message, validation: reason)
    else
      _ -> changeset
    end
  end

  defp validate_email_message(:format), do: "is of the wrong format"
  defp validate_email_message(:mx), do: "failed an MX record check"

  @spec validate_not_expired(Changeset.t(), DateTime.t(), atom, binary) :: Changeset.t()
  @doc "Validates that the entity has not expired"
  def validate_not_expired(
        cs,
        now \\ DateTime.utc_now(),
        column \\ :expires_at,
        message \\ "expired"
      ) do
    case Changeset.fetch_field(cs, column) do
      {_, time} ->
        case DateTime.compare(time, now) do
          :gt -> cs
          _ -> Changeset.add_error(cs, column, message)
        end
    end
  end

  @doc "Adds a foreign key constraint for pointer on the id"
  @spec meta_pointer_constraint(Changeset.t()) :: Changeset.t()
  def meta_pointer_constraint(changeset),
    do: Changeset.foreign_key_constraint(changeset, :id)

  @doc "Creates a changeset for claiming an entity"
  def claim_changeset(it, column \\ :claimed_at, error \\ "was already claimed"),
    do: soft_delete_changeset(it, column, error)

  @spec soft_delete_changeset(Changeset.t(), atom, any) :: Changeset.t()
  @doc "Creates a changeset for deleting an entity"
  def soft_delete_changeset(it, column \\ :deleted_at, error \\ "was already deleted") do
    cs = Changeset.cast(it, %{}, [])

    case Changeset.fetch_field(cs, column) do
      :error -> Changeset.change(cs, [{column, DateTime.utc_now()}])
      {_, nil} -> Changeset.change(cs, [{column, DateTime.utc_now()}])
      {_, _} -> Changeset.add_error(cs, column, error)
    end
  end

  @spec change_public(Changeset.t()) :: Changeset.t()
  @doc "Keeps published_at in accord with is_public"
  def change_public(%Changeset{} = changeset),
    do: change_synced_timestamp(changeset, :is_public, :published_at)

  @spec change_muted(Changeset.t()) :: Changeset.t()
  @doc "Keeps muted_at in accord with is_muted"
  def change_muted(%Changeset{} = changeset),
    do: change_synced_timestamp(changeset, :is_muted, :muted_at)

  @spec change_synced_timestamp(Changeset.t(), atom, atom) :: Changeset.t()
  @doc """
  If a changeset includes a change to `bool`, we ensure that the
  `timestamp` field is updated if required. In the case of true, this
  means setting it to now if it is null and in the case of false, this
  means setting it to null if it is not null.
  """
  def change_synced_timestamp(changeset, bool_field, timestamp_field) do
    bool_val = Changeset.fetch_change(changeset, bool_field)
    timestamp_val = Changeset.fetch_field(changeset, timestamp_field)

    case {bool_val, timestamp_val} do
      {{:ok, true}, {:data, value}} when not is_nil(value) ->
        changeset

      {{:ok, true}, _} ->
        Changeset.change(changeset, [{timestamp_field, DateTime.utc_now()}])

      {{:ok, false}, {:data, value}} when not is_nil(value) ->
        Changeset.change(changeset, [{timestamp_field, nil}])

      _ ->
        changeset
    end
  end
end