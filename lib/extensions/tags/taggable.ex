# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Tag.Taggable do
  use CommonsPub.Common.Schema

  use Pointers.Mixin,
    otp_app: :my_app,
    source: "taggable"

  # use Pointers.Pointable,
  #   otp_app: :commons_pub,
  #   source: "tags",
  #   table_id: "TAGSCANBECATEG0RY0RHASHTAG"

  alias Ecto.Changeset
  alias CommonsPub.Tag.Taggable
  alias CommonsPub.Repo

  @type t :: %__MODULE__{}
  @required ~w(id prefix facet)a

  mixin_schema do
    # pointable_schema do

    # field(:id, Pointers.ULID, autogenerate: true)

    # eg. @ or + or #
    field(:prefix, :string)

    field(:facet, :string)

    # Optionally, a profile and character (if not using context)
    has_one(:category, CommonsPub.Tag.Category, references: :id, foreign_key: :id)
    ## stores common fields like name/description
    has_one(:profile, CommonsPub.Profiles.Profile, references: :id, foreign_key: :id)
    ## allows it to be follow-able and federate activities
    has_one(:character, CommonsPub.Characters.Character, references: :id, foreign_key: :id)

    many_to_many(:things, Pointers.Pointer,
      join_through: "tags_things",
      unique: true,
      join_keys: [tag_id: :id, pointer_id: :id],
      on_replace: :delete
    )
  end

  def create_changeset(attrs) do
    %Taggable{}
    |> Changeset.cast(attrs, @required)
    |> common_changeset()
  end

  def update_changeset(
        %Taggable{} = tag,
        attrs
      ) do
    tag
    |> Changeset.cast(attrs, @required)
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    # |> Changeset.foreign_key_constraint(:pointer_id, name: :tag_pointer_id_fkey)
    # |> change_public()
    # |> change_disabled()
  end

  @doc """
  Add things (Pointer objects) to a tag. You usually want to add tags to a thing instead, see `thing_tags_changeset`
  """
  def tag_things_changeset(
        %Taggable{} = tag,
        things
      ) do
    tag
    |> Repo.preload(:things)
    |> Changeset.change()
    # Set the association
    |> Ecto.Changeset.put_assoc(:things, things)
    |> common_changeset()
  end

  @doc """
  Add tags to a thing (any Pointer object which defines a many_to_many relation to taggable). This function applies to your object schema but is here for convenience.
  """
  def thing_tags_changeset(
        %{} = thing,
        tags
      ) do
    thing
    |> Repo.preload(:tags)
    |> Changeset.change()
    # Set the association
    |> Ecto.Changeset.put_assoc(:tags, tags)
    |> common_changeset()
  end

  def context_module, do: CommonsPub.Tag.Taggables

  def queries_module, do: CommonsPub.Tag.Taggable.Queries

  def follow_filters, do: [:default]
end
