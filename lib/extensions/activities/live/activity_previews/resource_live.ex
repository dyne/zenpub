defmodule CommonsPub.Web.Component.ResourcePreviewLive do
  use Phoenix.LiveComponent
  import CommonsPub.Web.Helpers.Common
  # import CommonsPub.Web.Helpers.Profiles

  # def mount(_, _session, socket) do
  #   {:ok, assign(socket, current_user: socket.assigns.current_user)}
  # end

  def update(assigns, socket) do
    # IO.inspect(resource_pre_prep: assigns.resource)

    # resource = CommonsPub.Web.Helpers.Profiles.prepare(assigns.resource, %{icon: true, actor: true})

    resource = prepare_common(assigns.resource)

    # IO.inspect(resource_post_prep: resource)

    {:ok,
     socket
     |> assign(
       resource: resource
       #  current_user: assigns.current_user
     )}
  end

  def render(assigns) do
    ~L"""
    <a href="<%= e(@resource, :link, "#") %>" target="_blank">
      <div class="resource__preview">
        <svg class="icon svg-icon svg-icon-note-empty" viewBox="0 0 32 32"><g fill-rule="evenodd"><rect fill="#DBDFE2" x="4" y="2" width="24" height="30" rx="1.5"></rect><rect fill="#F7F9FA" x="4" y="1" width="24" height="30" rx="1.5"></rect></g></svg>
        <div class="preview__info">
          <h4><%= e(@resource, :name, "Resource") %></h4>
          <p><%= e(@resource, :summary, "") %>
          <%= if e(@resource, :license, nil) do  %>
          | License: <%= e(@resource, :license, "Undefined") %>
          <% end %>
          </p>
        </div>
      </div>
    </a>
    """
  end
end
