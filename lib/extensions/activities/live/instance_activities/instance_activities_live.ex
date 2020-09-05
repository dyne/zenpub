defmodule CommonsPub.Web.InstanceLive.InstanceActivitiesLive do
  use CommonsPub.Web, :live_component

  alias CommonsPub.Web.Component.{
    ActivitiesListLive
  }

  # alias CommonsPub.Web.GraphQL.{
  #   InstanceResolver
  # }

  @doc """
  Handle pushed activities from PubSub
  """
  def update(%{activity: activity}, socket),
    do: CommonsPub.Activities.Web.ActivitiesHelper.pubsub_receive(activity, socket)

  @doc """
  Load initial activities
  """
  def update(assigns, socket) do
    # IO.inspect(update_assigns: assigns)

    {
      :ok,
      socket
      |> assign(assigns)
      |> fetch(assigns)
    }
  end

  @doc """
  Load a page of activities
  """
  def fetch(socket, assigns),
    do:
      CommonsPub.Activities.Web.ActivitiesHelper.outbox_live(
        &CommonsPub.Feeds.instance_outbox_id/0,
        &CommonsPub.Instance.default_outbox_query_contexts/0,
        assigns,
        socket
      )

  def handle_event("load-more", _, socket),
    do: CommonsPub.Utils.Web.CommonHelper.paginate_next(&fetch/2, socket)

  def render(assigns) do
    ~L"""
      <div id="instance_activities">

      <%= live_component(
        @socket,
        ActivitiesListLive,
        assigns
        )
      %>
      </div>
    """
  end
end
