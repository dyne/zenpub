# SPDX-License-Identifier: AGPL-3.0-only

defmodule ActivityPub.HTTP.Connection do
  @moduledoc """
  Specifies connection options for HTTP requests
  """

  @hackney_options [
    connect_timeout: 10_000,
    recv_timeout: 20_000,
    follow_redirect: true,
    pool: :federation
  ]
  @adapter Application.get_env(:tesla, :adapter)

  def new(opts \\ []) do
    Tesla.client([], {@adapter, hackney_options(opts)})
  end

  def hackney_options(opts) do
    options = Keyword.get(opts, :adapter, [])
    adapter_options = CommonsPub.Config.get(:http)[:adapter] || []
    proxy_url = CommonsPub.Config.get(:http)[:proxy_url]

    @hackney_options
    |> Keyword.merge(adapter_options)
    |> Keyword.merge(options)
    |> Keyword.merge(proxy: proxy_url)
  end
end
