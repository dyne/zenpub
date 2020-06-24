defmodule MoodleNetWeb.Component.ActivityLive do
  use Phoenix.LiveComponent
  alias MoodleNetWeb.Component.StoryPreviewLive
  alias MoodleNetWeb.Component.CommentPreviewLive
  alias MoodleNetWeb.Component.CommunityPreviewLive
  alias MoodleNetWeb.Component.DiscussionPreviewLive
  alias MoodleNet.{
    Repo,
    Meta.Pointers
  }
  def mount(activity, _session, socket) do
    {:ok, assign(socket, activity: activity)}
  end

  def update(assigns, socket) do
    {:ok, pointer} = Pointers.one(id: assigns.activity.context_id)
    context = Pointers.follow!(pointer)
    meta = Kernel.inspect(context.__meta__)
    type = cond do
      meta =~ "community" ->
        type = "community"
      meta =~ "collection" ->
        type = "collection"
      meta =~ "comment" ->
        type = "comment"
      true ->
        type = "activity"
    end
    activity_with_creator = Repo.preload(assigns.activity, :creator)
    {:ok, from_now} = Timex.shift(assigns.activity.published_at, minutes: -3)
    |> Timex.format("{relative}", :relative)
    {:ok, assign(socket,
      activity: activity_with_creator
        |> Map.merge(%{published_at: from_now})
        |> Map.merge(%{context_type: type})
        |> Map.merge(%{context: context})
        )}
  end

  def render(assigns) do
    ~L"""
    <div class="component__activity">
      <div class="activity__info">
        <img src="https://docs.moodle.org/dev/images_dev/thumb/2/2b/estrella.jpg/100px-estrella.jpg" alt="icon" />
        <div class="info__meta">
          <div class="meta__action">
            <a href="/user/<%= @activity.creator.id %>"><%= @activity.creator.name %></a>
            <p><%= @activity.verb %> a <%= @activity.context_type %></p>
          </div>
          <div class="meta__secondary">
            <%= @activity.published_at %>
          </div>
        </div>
      </div>
      <div class="activity__preview">

        <%= cond do
            @activity.context_type == "community" ->
              live_component(
                @socket,
                CommunityPreviewLive,
                community: @activity.context
              )
              @activity.context_type == "comment" ->
                live_component(
                  @socket,
                  CommentPreviewLive,
                  comment: @activity.context
                )
                true ->
                  live_component(
                    @socket,
                    StoryPreviewLive
                  )
          end %>
      </div>
    </div>
    """
  end
end
