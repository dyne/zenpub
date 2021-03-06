defmodule CommonsPub.Web.SettingsLive do
  use CommonsPub.Web, :live_view

  import CommonsPub.Utils.Web.CommonHelper
  # alias CommonsPub.Profiles.Web.ProfilesHelper
  alias CommonsPub.Web.GraphQL.UsersResolver

  alias CommonsPub.Web.SettingsLive.{
    SettingsNavigationLive,
    SettingsGeneralLive
  }

  def mount(params, session, socket) do
    # IO.inspect(session)
    socket = init_assigns(params, session, socket)

    {:ok,
     socket
     |> assign(
       page_title: "Settings",
       selected_tab: "general",
       trigger_submit: false
       #  current_user: user,
       #  session: session_token
     )}
  end

  def handle_params(%{"tab" => tab}, _url, socket) do
    {:noreply, assign(socket, selected_tab: tab)}
  end

  def handle_params(_, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("profile_save", _data, %{assigns: %{trigger_submit: trigger_submit}} = socket)
      when trigger_submit == true do
    {
      :noreply,
      assign(socket, trigger_submit: false)
    }
  end

  def handle_event("profile_save", params, socket) do
    params = input_to_atoms(params)

    {:ok, _edit_profile} =
      UsersResolver.update_profile(params, %{
        context: %{current_user: socket.assigns.current_user}
      })

    cond do
      strlen(params.icon) > 0 or strlen(params.image) > 0 ->
        {
          :noreply,
          assign(socket, trigger_submit: true)
          |> put_flash(:info, "Details saved!")
          #  |> push_redirect(to: "/~/profile")
        }

      true ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile saved!")
         |> push_redirect(to: "/~/profile")}
    end
  end
end
