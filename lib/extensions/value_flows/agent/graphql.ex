# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Agent.GraphQL do
  use Absinthe.Schema.Notation

  # alias CommonsPub.Web.GraphQL.{CommonResolver}

  # alias CommonsPub.Utils.Simulation
  # alias ValueFlows.Simulate

  require Logger

  # import_sdl path: "lib/value_flows/graphql/schemas/agent.gql"

  # fake data
  # def all_agents(_, _) do
  #   {:ok, long_list(&Simulate.agent/0)}
  # end

  # def agent(%{id: id}, info) do
  #   {:ok, Simulate.agent()}
  # end

  # proper resolvers

  # with pagination
  def people(page_opts, info) do
    {:ok, users_pages} = CommonsPub.Web.GraphQL.UsersResolver.users(page_opts, info)

    people =
      Enum.map(
        users_pages.edges,
        &(&1
          |> ValueFlows.Agent.People.actor_to_person())
      )

    people_pages = %{
      edges: people,
      page_info: users_pages.page_info,
      total_count: users_pages.total_count
    }

    {:ok, people_pages}
  end

  # TODO: pagination
  def all_people(%{}, info) do
    {:ok, ValueFlows.Agent.People.people(CommonsPub.GraphQL.current_user(info))}
  end

  def person(%{id: id}, info) do
    {:ok, ValueFlows.Agent.People.person(id, CommonsPub.GraphQL.current_user(info))}
  end

  # with pagination
  def organizations(page_opts, info) do
    {:ok, orgs_pages} = Organisation.GraphQL.Resolver.organisations(page_opts, info)

    orgz =
      Enum.map(
        orgs_pages.edges,
        &(&1
          |> ValueFlows.Agent.Organizations.actor_to_organization())
      )

    orgz_pages = %{
      edges: orgz,
      page_info: orgs_pages.page_info,
      total_count: orgs_pages.total_count
    }

    {:ok, orgz_pages}
  end

  # without pagination
  def all_organizations(%{}, info) do
    {:ok, ValueFlows.Agent.Organizations.organizations(CommonsPub.GraphQL.current_user(info))}
  end

  def organization(%{id: id}, info) do
    {:ok,
     ValueFlows.Agent.Organizations.organization(
       id,
       CommonsPub.GraphQL.current_user(info)
     )}
  end

  def all_agents(%{}, info) do
    {:ok, ValueFlows.Agent.Agents.agents(CommonsPub.GraphQL.current_user(info))}
  end

  def agent(%{id: id}, info) do
    {:ok, ValueFlows.Agent.Agents.agent(id, CommonsPub.GraphQL.current_user(info))}
  end
end