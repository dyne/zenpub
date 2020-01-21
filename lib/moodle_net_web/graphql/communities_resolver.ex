# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.CommunitiesResolver do
  @moduledoc """
  Performs the GraphQL Community queries.
  """
  import Ecto.Query
  alias MoodleNet.{Collections, Communities, GraphQL, Repo}
  alias MoodleNet.Batching.EdgesPages
  alias MoodleNet.Communities.Community
  alias MoodleNet.Feeds.FeedActivities
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  def community(%{community_id: id}, %{context: %{current_user: user}}) do
    Communities.one(id: id, user: user)
  end

  def communities(args, %{context: %{current_user: user}}) do
    Communities.nodes_page &(&1.id), [user: user],
      join: :follower_count, order: :list
  end

  def create_community(%{community: attrs}, info) do
    with {:ok, user} <- GraphQL.current_user(info) do
      Communities.create(user, attrs)
    end
  end

  def update_community(%{community: changes, community_id: id}, info) do
    Repo.transact_with(fn ->
      with {:ok, user} <- GraphQL.current_user(info),
           {:ok, community} <- community(%{community_id: id}, info) do
        cond do
          user.local_user.is_instance_admin ->
            Communities.update(community, changes)

          community.creator_id == user.id ->
            Communities.update(community, changes)

          is_nil(community.published_at) -> GraphQL.not_found()

          true -> GraphQL.not_permitted()
        end
      end
    end)
  end

  # def delete(%{community_id: id}, info) do
  #   Repo.transact_with(fn ->
  #     with {:ok, user} <- GraphQL.current_user(info),
  #          {:ok, actor} <- Users.fetch_actor(user),
  #          {:ok, community} <- Communities.fetch(id) do
  #       if community.creator_id == actor.id do
  # 	  with {:ok, _} <- Communities.soft_delete(community), do: {:ok, true}
  #       else
  #         GraphQL.not_permitted()
  #       end
  #     end
  #   end)
  #   |> GraphQL.response(info)
  # end

  def collections_count_edge(%Community{}=community, _, info) do
    
  end

  def collections_edge(%Community{collections: cs}, _, info) when is_list(cs), do: {:ok, cs}
  def collections_edge(%Community{id: id}=community, _, %{context: %{current_user: user}}) do
    batch {__MODULE__, :batch_collections_edge, user}, id, EdgesPages.getter(id)
  end

  def batch_collections_edge(user, ids) do
    {:ok, edges} = Collections.edges_pages(
      &(&1.community_id),
      &(&1.id),
      [community_id: ids, user: user],
      [join: :follower_count, order: :followers_desc, preload: :follower_count],
      [group_count: :community_id]
    )
    edges
  end

  def inbox_edge(_community, _, _info) do
    {:ok, EdgesPage.new([], [], &(&1.id))}
  end

  def outbox_edge(%Community{}=community, _, %{context: %{current_user: user}}) do
    Communities.outbox(community)
  end

  def last_activity_edge(_, _, _info), do: {:ok, DateTime.utc_now()}

end
