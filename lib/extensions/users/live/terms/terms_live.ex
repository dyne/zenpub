defmodule CommonsPub.Web.TermsLive do
  use CommonsPub.Web, :live_view
  import CommonsPub.Utils.Web.CommonHelper

  def mount(params, session, socket) do
    socket = init_assigns(params, session, socket)

    {:ok,
     socket
     |> assign(app_name: CommonsPub.Config.get(:app_name))}
  end
end
