defmodule ActivityPub.SQLEntity do
  use Ecto.Schema
  alias Ecto.Multi
  require ActivityPub.Guards, as: APG

  alias ActivityPub.Entity
  alias ActivityPub.{SQLAspect, Context, UrlBuilder, Metadata}
  alias ActivityPub.SQL.{AssociationNotLoaded, FieldNotLoaded}
  alias MoodleNet.Repo

  @primary_key {:local_id, :id, autogenerate: true}
  schema "activity_pub_objects" do
    field(:id, :string)
    field(:"@context", Context)
    field(:type, {:array, :string})
    field(:local, :boolean, default: false)
    field(:extension_fields, :map, default: %{})

    timestamps()

    require ActivityPub.SQLAspect

    for sql_aspect <- SQLAspect.all() do
      ActivityPub.SQLAspect.inject_in_sql_entity_schema(sql_aspect)
    end
  end

  def create(entity) when APG.is_entity(entity) do
    case Entity.status(entity) do
      :new ->
        {:ok, %{entity: sql_entity}} =
          Multi.new()
          |> Multi.insert(:_entity, create_changeset(entity))
          |> Multi.run(:entity, &set_ap_id/2)
          |> MoodleNet.Repo.transaction()

        {:ok, to_entity(sql_entity)}
    end
  end

  defp create_changeset(entity) do
    ch =
      %__MODULE__{}
      |> Ecto.Changeset.change(from_entity_fields(entity))

    Entity.aspects(entity)
    |> Enum.reduce(ch, fn aspect, ch ->
      aspect.persistence().create_changeset(ch, entity)
    end)
  end

  defp from_entity_fields(entity) when APG.is_entity(entity) do
    entity
    # FIXME add context and local_id
    |> Map.take([:"@context", :id, :type])
    # |> Map.take([:id, :type])
    |> Map.put(:local, Entity.local?(entity))
    |> Map.put(:extension_fields, Entity.extension_fields(entity))
  end

  def set_ap_id(repo, %{_entity: %{id: nil, local_id: local_id, local: true} = e}) do
    id = UrlBuilder.id(local_id)

    e
    |> Ecto.Changeset.change(id: id)
    |> repo.update()
  end

  def set_ap_id(_repo, %{_entity: %{id: id} = e}) when not is_nil(id),
    do: {:ok, e}

  def to_entity(%__MODULE__{} = sql_entity) do
    {loaded_aspects, not_loaded_aspects} = get_loaded_and_unloaded_aspects(sql_entity)
    no_loaded_params = generate_not_loaded_data(not_loaded_aspects)
    loaded_params = generate_loaded_data(loaded_aspects)
    %{
      __ap__: Metadata.load(sql_entity),
      id: sql_entity.id,
      "@context": Map.fetch!(sql_entity, :"@context"),
      type: sql_entity.type
    }
    |> Map.merge(no_loaded_params)
    |> Map.merge(loaded_params)
    |> Map.merge(sql_entity.extension_fields)

    # sql_aspects = 
    # {:ok, entity} =
    #   sql_entity
    #   |> to_entity_fields()
    #   |> Entity.parse()

    # preload_aspect_names =
    #   entity
    #   |> Entity.aspects()
    #   |> Enum.filter(&(&1.persistence().persistence_method() == :table))
    #   |> Enum.map(& &1.name())

    # # FIXME set to nil not implemented aspects
    # sql_entity = Repo.preload(sql_entity, preload_aspect_names)

    # entity
    # |> Entity.aspects()
    # |> Enum.reduce(entity, fn aspect, entity ->
    #   aspect_data = aspect_data(sql_entity, aspect)
    #   Map.merge(entity, aspect_data)
    # end)
  end

  defp get_loaded_and_unloaded_aspects(%__MODULE__{} = sql_entity) do
    sql_entity.type
    |> ActivityPub.Types.aspects()
    |> Enum.reduce({[], []}, fn aspect, {loaded_aspects, not_loaded_aspects} ->
        sql_aspect = aspect.persistence()
        case sql_aspect.persistence_method() do
          :fields ->
            loaded_aspects = [{aspect, sql_entity} | loaded_aspects]
            {loaded_aspects, not_loaded_aspects}
          :embedded ->
            sql_data = Map.fetch!(sql_entity, aspect.name())
            loaded_aspects = [{aspect, sql_data} | loaded_aspects]
            {loaded_aspects, not_loaded_aspects}
          :table ->
            case Map.fetch!(sql_entity, aspect.name()) do
              %Ecto.Association.NotLoaded{} ->
                {loaded_aspects, [aspect | not_loaded_aspects]}
              sql_data ->
                loaded_aspects = [{aspect, sql_data} | loaded_aspects]
                {loaded_aspects, not_loaded_aspects}
            end
        end
      end)
  end

  defp generate_not_loaded_data(not_loaded_aspects) do
    Enum.reduce(not_loaded_aspects, %{}, fn aspect, params ->
      params =
        aspect.__aspect__(:fields)
        |> Enum.into(params, & {&1, %FieldNotLoaded{}})

      # FIXME maybe the assocs are loaded
      aspect.__aspect__(:associations)
      |> Enum.into(params, &{&1, %AssociationNotLoaded{}})
    end)
  end

  def generate_loaded_data(loaded_aspects) do
    Enum.reduce(loaded_aspects, %{}, fn {aspect, sql_data}, params ->
      params =
        sql_data
        |> Map.take(aspect.__aspect__(:fields))
        |> Map.merge(params)

        # FIXME assocs!
        aspect.__aspect__(:associations)
        |> Enum.into(params, fn assoc_name ->
          value = if aspect.__aspect__(:association, assoc_name).cardinality == :many, do: [], else: nil
          {assoc_name, value}
        end)
    end)
  end

  defp to_entity_fields(%__MODULE__{} = sql_entity) do
    sql_entity
    |> Map.take([:id, :type, :"@context"])
    |> Map.merge(sql_entity.extension_fields)
  end

  # FIXME move to sql_aspect
  defp aspect_data(%__MODULE__{} = sql_entity, aspect) do
    sql_aspect = aspect.persistence()

    case sql_aspect.persistence_method() do
      x when x in [:table, :embedded] ->
        Map.fetch!(sql_entity, aspect.name())

      :fields ->
        sql_entity
    end
    |> Map.take(aspect.__aspect__(:fields))
  end
end