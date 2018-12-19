defmodule ActivityPub.Field do
  @enforce_keys [:aspect, :name, :type]
  defstruct aspect: nil,
    name: nil,
    functional: true,
    type: nil,
    default: nil,
    autogenerated: false

  def build(opts) do
    opts = add_default_value(opts)
    struct!(__MODULE__, opts)
  end

  defp add_default_value(keywords) do
    cond do
      Keyword.has_key?(keywords, :default) -> keywords
      keywords[:functional] == false -> Keyword.put(keywords, :default, [])
      true -> Keyword.put(keywords, :default, nil)
    end
  end
end
