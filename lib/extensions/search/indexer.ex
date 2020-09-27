# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.Search.Indexer do
  require Logger
  alias CommonsPub.Utils.Web.CommonHelper

  @public_index "public"

  def maybe_index_object(object) do
    indexable_object = maybe_indexable_object(object)

    if !is_nil(indexable_object) do
      index_object(indexable_object)
    end
  end

  def maybe_indexable_object(nil) do
    nil
  end

  def maybe_indexable_object(%{} = object) do
    indexable_object = indexing_object_format(object)

    if !is_nil(indexable_object) do
      indexable_object
    else
      thing_name = Map.get(object, :__struct__)

      if(
        !is_nil(thing_name) and
          Kernel.function_exported?(thing_name, :context_module, 0)
      ) do
        thing_context_module = apply(thing_name, :context_module, [])

        if(Kernel.function_exported?(thing_context_module, :indexing_object_format, 1)) do
          # IO.inspect(function_exists_in: thing_context_module)
          indexable_object = apply(thing_context_module, :indexing_object_format, [object])
          indexable_object
        else
          Logger.warn(
            "Could not index #{thing_name} object (no context module with indexing_object_format/1)"
          )

          nil
        end
      else
        Logger.warn("Could not index #{thing_name} object (no known context module)")
        nil
      end
    end
  end

  def maybe_indexable_object(_) do
    nil
  end

  # add to general instance search index
  def index_object(objects) do
    # IO.inspect(search_indexing: objects)
    index_objects(objects, @public_index, true)
  end

  # index several things in an existing index
  def index_objects(objects, index_name, init_index_first \\ true)

  def index_objects(objects, index_name, init_index_first) when is_list(objects) do
    # IO.inspect(objects)
    # FIXME - should create the index only once
    if init_index_first, do: init_index(index_name, true)
    CommonsPub.Search.Meili.put(objects, index_name <> "/documents")
  end

  # index something in an existing index
  def index_objects(object, index_name, init_index_first) do
    # IO.inspect(object)
    index_objects([object], index_name, init_index_first)
  end

  # create a new index
  def init_index(index_name \\ "public", fail_silently \\ false)

  def init_index("public" = index_name, fail_silently) do
    create_index(index_name, fail_silently)
    set_facets(index_name, ["username", "index_type", "index_instance"])
  end

  def init_index(index_name, fail_silently) do
    create_index(index_name, fail_silently)
  end

  def create_index(index_name, fail_silently \\ false) do
    CommonsPub.Search.Meili.post(%{uid: index_name}, "", fail_silently)
  end

  def index_exists(index_name) do
    with {:ok, _index} <- CommonsPub.Search.Meili.get(nil, index_name) do
      true
    else
      _e ->
        false
    end
  end

  # def set_attributes(attrs, index) do
  #   settings(%{attributesForFaceting: attrs}, index)
  # end

  def set_facets(index_name, facets) when is_list(facets) do
    CommonsPub.Search.Meili.post(
      facets,
      index_name <> "/settings/attributes-for-faceting",
      false
    )
  end

  def set_facets(index_name, facet) do
    set_facets(index_name, [facet])
  end

  def list_facets(index_name \\ "public") do
    CommonsPub.Search.Meili.get(nil, index_name <> "/settings/attributes-for-faceting")
  end

  def maybe_delete_object(object) do
    delete_object(object)
    :ok
  end

  defp delete_object(nil) do
    Logger.warn("Couldn't get object ID in order to delete")
  end

  defp delete_object(_object_id) do
    # TODO
  end

  def host(url) when is_binary(url) do
    URI.parse(url).host
  end

  def host(_) do
    ""
  end

  def indexing_object_format(%CommonsPub.Users.User{} = user) do
    follower_count =
      case CommonsPub.Follows.FollowerCounts.one(context: user.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = CommonsPub.Uploads.remote_url_from_id(user.icon_id)
    image = CommonsPub.Uploads.remote_url_from_id(user.image_id)
    url = CommonsPub.ActivityPub.Utils.get_actor_canonical_url(user)

    %{
      "id" => user.id,
      "canonical_url" => url,
      "followers" => %{
        "total_count" => follower_count
      },
      "icon" => icon,
      "image" => image,
      "name" => user.name,
      "username" => CommonsPub.Characters.display_username(user),
      "summary" => Map.get(user, :summary),
      "index_type" => "User",
      "index_instance" => host(url),
      "published_at" => user.published_at
    }
  end

  def indexing_object_format(%CommonsPub.Communities.Community{} = community) do
    community = CommonHelper.maybe_preload(community, :context)
    context = CommonHelper.maybe_preload(community.context, :character)

    follower_count =
      case CommonsPub.Follows.FollowerCounts.one(context: community.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = CommonsPub.Uploads.remote_url_from_id(community.icon_id)
    image = CommonsPub.Uploads.remote_url_from_id(community.image_id)
    url = CommonsPub.ActivityPub.Utils.get_actor_canonical_url(community)

    %{
      "id" => community.id,
      "canonical_url" => url,
      "followers" => %{
        "total_count" => follower_count
      },
      "icon" => icon,
      "image" => image,
      "name" => community.name,
      "username" => CommonsPub.Characters.display_username(community),
      "summary" => Map.get(community, :summary),
      "index_type" => "Community",
      "index_instance" => host(url),
      "published_at" => community.published_at,
      "context" => maybe_indexable_object(context)
    }
  end

  def indexing_object_format(%CommonsPub.Collections.Collection{} = collection) do
    collection = CommonHelper.maybe_preload(collection, :context)
    context = CommonHelper.maybe_preload(collection.context, :character)

    follower_count =
      case CommonsPub.Follows.FollowerCounts.one(context: collection.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = CommonsPub.Uploads.remote_url_from_id(collection.icon_id)
    url = CommonsPub.ActivityPub.Utils.get_actor_canonical_url(collection)

    %{
      "id" => collection.id,
      "canonical_url" => url,
      "followers" => %{
        "total_count" => follower_count
      },
      "icon" => icon,
      "name" => collection.name,
      "username" => CommonsPub.Characters.display_username(collection),
      "summary" => Map.get(collection, :summary),
      "index_type" => "Collection",
      "index_instance" => host(url),
      "published_at" => collection.published_at,
      "context" => maybe_indexable_object(context)
    }
  end

  def indexing_object_format(_) do
    nil
  end

  def format_creator(%{creator: %{id: id}} = obj) when not is_nil(id) do
    creator = CommonsPub.Utils.Web.CommonHelper.maybe_preload(obj, :creator).creator

    %{
      "id" => creator.id,
      "name" => creator.name,
      "username" => CommonsPub.Characters.display_username(creator),
      "canonical_url" => CommonsPub.ActivityPub.Utils.get_actor_canonical_url(creator)
    }
  end

  def format_creator(_) do
    %{}
  end
end