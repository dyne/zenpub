# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Feeds.FeedActivity do
  use MoodleNet.Common.Schema
  alias MoodleNet.Activities.Activity
  alias MoodleNet.Feeds.Feed

  table_schema "mn_feed_activity" do
    belongs_to(:feed, Feed)
    belongs_to(:activity, Activity)
  end
end
