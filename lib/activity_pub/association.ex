defmodule ActivityPub.Association do
  @enforce_keys [:aspect, :name]
  defstruct aspect: nil,
            name: nil,
            functional: false,
            type: :any,
            autogenerated: false,
            inv: false
end