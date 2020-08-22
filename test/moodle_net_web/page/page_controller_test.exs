# SPDX-License-Identifier: AGPL-3.0-only

defmodule MoodleNetWeb.PageControllerTest do
  use MoodleNetWeb.ConnCase, async: true

  describe "index" do
    test "redirects to frontend" do
      redirect_url = Application.get_env(:moodle_net, :frontend_base_url)
      assert resp = build_conn() |> get("/") |> response(301)
      assert resp =~ redirect_url
    end
  end
end
