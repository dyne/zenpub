defmodule ValueFlows.Proposal do
  @moduledoc """
  Schema for proposal, using `Pointers.Pointable`
  """
  use Pointers.Pointable,
    otp_app: :commons_pub,
    source: "vf_proposal",
    table_id: "PR0P0SA11SMADE0FTW01NTENTS"

  import CommonsPub.Common.Changeset, only: [change_public: 1]
  alias Ecto.Changeset
  alias CommonsPub.Users.User
  #
  # alias CommonsPub.Communities.Community
  alias ValueFlows.Proposal
  alias ValueFlows.Proposal.{ProposedIntent, ProposedTo}
  alias ValueFlows.Planning.Intent

  @type t :: %__MODULE__{}

  pointable_schema do
    field(:name, :string)
    field(:note, :string)

    field(:created, :utc_datetime_usec)

    field(:has_beginning, :utc_datetime_usec)
    field(:has_end, :utc_datetime_usec)

    # TODO: should be the same as has_beginning?
    field(:published_at, :utc_datetime_usec)

    field(:deleted_at, :utc_datetime_usec)

    field(:is_public, :boolean, virtual: true)
    field(:unit_based, :boolean, default: false)

    belongs_to(:creator, User)

    belongs_to(:context, Pointers.Pointer)

    belongs_to(:eligible_location, Geolocation)

    many_to_many(:publishes, Intent, join_through: ProposedIntent)
    many_to_many(:proposed_to, Pointers.Pointer, join_through: ProposedTo)

    timestamps(inserted_at: false)
  end

  @required ~w(name is_public)a
  @cast @required ++
    ~w(note has_beginning has_end unit_based eligible_location_id context_id)a

  def create_changeset(
        %User{} = creator,
        attrs
      ) do
    %Proposal{}
    |> Changeset.cast(attrs, @cast)
    |> Changeset.validate_required(@required)
    |> Changeset.change(
      created: DateTime.utc_now(),
      creator_id: creator.id,
      is_public: true
    )
    |> common_changeset()
  end

  def update_changeset(%Proposal{} = proposal, attrs) do
    proposal
    |> Changeset.cast(attrs, @cast)
    |> common_changeset()
  end

  defp common_changeset(changeset) do
    changeset
    |> change_public()
    |> Changeset.foreign_key_constraint(
      :eligible_location,
      name: :vf_proposal_eligible_location_id_fkey
    )
  end

  def context_module, do: ValueFlows.Proposal.Proposals

  def queries_module, do: ValueFlows.Proposal.Queries

  def follow_filters, do: [:default]
end
