# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Knowledge.ProcessSpecification.ProcessSpecifications do
  alias CommonsPub.{Activities, Common, Feeds, Repo}
  alias CommonsPub.GraphQL.{Fields, Page}
  alias CommonsPub.Common.Contexts
  alias CommonsPub.Feeds.FeedActivities
  alias CommonsPub.Users.User
  # alias CommonsPub.Meta.Pointers

  # alias Measurement.Measure
  alias ValueFlows.Knowledge.ProcessSpecification
  alias ValueFlows.Knowledge.ProcessSpecification.Queries
  # alias ValueFlows.Knowledge.Action
  # alias ValueFlows.Knowledge.Action.Actions

  def cursor(), do: &[&1.id]
  def test_cursor(), do: &[&1["id"]]

  @doc """
  Retrieves a single one by arbitrary filters.
  Used by:
  * GraphQL Item queries
  * ActivityPub integration
  * Various parts of the codebase that need to query for collections (inc. tests)
  """
  def one(filters), do: Repo.single(Queries.query(ProcessSpecification, filters))

  @doc """
  Retrieves a list of them by arbitrary filters.
  Used by:
  * Various parts of the codebase that need to query for collections (inc. tests)
  """
  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(ProcessSpecification, filters))}

  def fields(group_fn, filters \\ [])
      when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

  @doc """
  Retrieves an Page of process_specs according to various filters

  Used by:
  * GraphQL resolver single-parent resolution
  """
  def page(cursor_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])

  def page(cursor_fn, %{} = page_opts, base_filters, data_filters, count_filters) do
    base_q = Queries.query(ProcessSpecification, base_filters)
    data_q = Queries.filter(base_q, data_filters)
    count_q = Queries.filter(base_q, count_filters)

    with {:ok, [data, counts]} <- Repo.transact_many(all: data_q, count: count_q) do
      {:ok, Page.new(data, counts, cursor_fn, page_opts)}
    end
  end

  @doc """
  Retrieves an Pages of process_specs according to various filters

  Used by:
  * GraphQL resolver bulk resolution
  """
  def pages(
        cursor_fn,
        group_fn,
        page_opts,
        base_filters \\ [],
        data_filters \\ [],
        count_filters \\ []
      )

  def pages(cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters) do
    Contexts.pages(
      Queries,
      ProcessSpecification,
      cursor_fn,
      group_fn,
      page_opts,
      base_filters,
      data_filters,
      count_filters
    )
  end

  ## mutations

  # @spec create(User.t(), Community.t(), attrs :: map) :: {:ok, ProcessSpecification.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, %{id: _id} = context, attrs)
      when is_map(attrs) do
    do_create(creator, attrs, fn ->
      ProcessSpecification.create_changeset(creator, context, attrs)
    end)
  end

  # @spec create(User.t(), attrs :: map) :: {:ok, ProcessSpecification.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, attrs) when is_map(attrs) do
    do_create(creator, attrs, fn ->
      ProcessSpecification.create_changeset(creator, attrs)
    end)
  end

  def do_create(creator, attrs, changeset_fn) do
    Repo.transact_with(fn ->
      cs = changeset_fn.()

      with {:ok, item} <- Repo.insert(cs),
           {:ok, item} <- ValueFlows.Util.try_tag_thing(creator, item, attrs),
           act_attrs = %{verb: "created", is_local: true},
           # FIXME
           {:ok, activity} <- Activities.create(creator, item, act_attrs),
           :ok <- publish(creator, item, activity, :created) do
        item = %{item | creator: creator}
        index(item)
        {:ok, item}
      end
    end)
  end

  defp publish(creator, process_spec, activity, :created) do
    feeds = [
      creator.outbox_id,
      Feeds.instance_outbox_id()
    ]

    with :ok <- FeedActivities.publish(activity, feeds) do
      ap_publish("create", process_spec.id, creator.id)
    end
  end

  defp publish(creator, context, process_spec, activity, :created) do
    feeds = [
      context.outbox_id,
      creator.outbox_id,
      Feeds.instance_outbox_id()
    ]

    with :ok <- FeedActivities.publish(activity, feeds) do
      ap_publish("create", process_spec.id, creator.id)
    end
  end

  defp publish(process_spec, :updated) do
    # TODO: wrong if edited by admin
    ap_publish("update", process_spec.id, process_spec.creator_id)
  end

  defp publish(process_spec, :deleted) do
    # TODO: wrong if edited by admin
    ap_publish("delete", process_spec.id, process_spec.creator_id)
  end

  # FIXME
  defp ap_publish(verb, context_id, user_id) do
    CommonsPub.Workers.APPublishWorker.enqueue(verb, %{
      "context_id" => context_id,
      "user_id" => user_id
    })

    :ok
  end

  defp ap_publish(_, _, _), do: :ok

  # TODO: take the user who is performing the update
  # @spec update(%ProcessSpecification{}, attrs :: map) :: {:ok, ProcessSpecification.t()} | {:error, Changeset.t()}
  def update(%ProcessSpecification{} = process_spec, attrs) do
    do_update(process_spec, attrs, &ProcessSpecification.update_changeset(&1, attrs))
  end

  def update(%ProcessSpecification{} = process_spec, %{id: _id} = context, attrs) do
    do_update(process_spec, attrs, &ProcessSpecification.update_changeset(&1, context, attrs))
  end

  def do_update(process_spec, attrs, changeset_fn) do
    Repo.transact_with(fn ->
      cs =
        process_spec
        |> changeset_fn.()

      with {:ok, process_spec} <- Repo.update(cs),
           {:ok, process_spec} <- ValueFlows.Util.try_tag_thing(nil, process_spec, attrs),
           :ok <- publish(process_spec, :updated) do
        {:ok, process_spec}
      end
    end)
  end

  def soft_delete(%ProcessSpecification{} = process_spec) do
    Repo.transact_with(fn ->
      with {:ok, process_spec} <- Common.soft_delete(process_spec),
           :ok <- publish(process_spec, :deleted) do
        {:ok, process_spec}
      end
    end)
  end

  def indexing_object_format(obj) do
    # icon = CommonsPub.Uploads.remote_url_from_id(obj.icon_id)
    # image = CommonsPub.Uploads.remote_url_from_id(obj.image_id)

    %{
      "index_type" => "ProcessSpecification",
      "id" => obj.id,
      # "canonicalUrl" => obj.actor.canonical_url,
      # "icon" => icon,
      # "image" => image,
      "name" => obj.name,
      "summary" => Map.get(obj, :note),
      "published_at" => obj.published_at,
      "creator" => CommonsPub.Search.Indexer.format_creator(obj)
      # "index_instance" => URI.parse(obj.actor.canonical_url).host, # home instance of object
    }
  end

  defp index(obj) do
    object = indexing_object_format(obj)

    CommonsPub.Search.Indexer.index_object(object)

    :ok
  end
end
