defmodule ActivityPub.CollectionAspect do
  @moduledoc """
`CollectionAspect` implements _Collection_ as defined in the ActivityPub and ActivityStreams specifications.

An `ActivityPub.Aspect` is a group of fields and functionality that an `ActivityPub.Entity` can have. `Aspects` are similar to [ActivityStreams core types](https://www.w3.org/TR/activitystreams-vocabulary/#types), but not exactly the same.

The `ActivityPub.Aspect` is responsible for an `ActivityPub.Entity`'s fields and associations. An `ActivityPub.Entity` can implement one or more `Aspects` at the same time.
  """

  use ActivityPub.Aspect, persistence: ActivityPub.SQLCollectionAspect

  aspect do
    # FIXME autogenerated is not implemented for fields!
    field(:total_items, :integer, autogenerated: true)
    # FIXME make them virtual?
    # assoc(:current, functional: true)
    # assoc(:first, functional: true)
    # assoc(:last, functional: true)
    # assoc(:items)
    field(:items, :any, virtual: true)

    # FIXME private attribute for the field?
    field(:__ordered__, :boolean)
    # FIXME This should be in SQLCollectionAspect only
    # field(:__table__, :string)
    # field(:__keys__, :string)
  end

  def autogenerate(:total_items, _), do: {:ok, 0}
end
