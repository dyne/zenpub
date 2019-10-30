# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.CommunitiesTest do
  use MoodleNet.DataCase, async: true

  import MoodleNet.Test.Faking
  alias MoodleNet.Test.Fake
  alias MoodleNet.{Communities, Localisation}

  defp english(), do: Localisation.language!("en")

  describe "Communities.create/3" do
    test "creates a community valid attributes" do
      assert actor = fake_actor!()
      assert language = english()
      attrs = Fake.community()
      assert {:ok, community} = Communities.create(actor, language, attrs)
      assert community.creator_id == actor.id
      assert community.primary_language_id == language.id
      assert community.is_public == attrs[:is_public]
    end

    test "fails if given invalid attributes" do
      actor = fake_actor!()
      language = fake_language!()
      assert {:error, changeset} = Communities.create(actor, language, %{})
      assert Keyword.get(changeset.errors, :is_public)
    end
  end

  describe "Communities.update/2" do

    test "updates a community with valid attributes" do
      assert actor = fake_actor!()
      assert language = english()
      assert community = fake_community!(actor, language, %{is_public: true})
      assert {:ok, updated_community} = Communities.update(community, %{is_public: false})
      assert updated_community.id == community.id
      refute updated_community.is_public
    end

  end
end