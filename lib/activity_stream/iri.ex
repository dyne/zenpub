defmodule ActivityStream.IRI do
  @moduledoc false
  # This is not a full implementation of IRI protocol.
  # In fact, it just uses the default URI Elixir implementation.
  # The following part of the ActivityStream protocol has not been considered:
  #
  # > https://www.w3.org/TR/activitystreams-core/#urls
  #
  # > This specification uses IRIs [RFC3987].
  # > Every URI [RFC3986] is also an IRI, so a URI may be used wherever an
  # > IRI is named. There are two special considerations:
  # > (1) when an IRI that is not also a URI is given for dereferencing,
  # > it MUST be mapped to a URI using the steps in Section 3.1 of [RFC3987] and
  # > (2) when an IRI is serving as an "id" value, it MUST NOT be so mapped.

  # However, the following is checked:
  #
  # > Relative IRI (and URL) references SHOULD NOT be used within an Activity Streams 2.0
  # > document due to the fact that many JSON parser implementations are not capable
  # > of reliably preserving the base context necessary to properly resolve
  # > relative references.
  @spec validate(String.t()) ::
          :ok
          | {:error, :invalid_scheme}
          | {:error, :invalid_host}
          | {:error, :invalid_path}
          | {:error, :not_string}

  def validate(string) when is_binary(string) do
    case URI.parse(string) do
      %{scheme: scheme} when scheme not in ["http", "https"] -> {:error, :invalid_scheme}
      %{host: nil} -> {:error, :invalid_host}
      %{path: path} when path in [nil, "/"] -> {:error, :invalid_path}
      _ -> :ok
    end
  end

  def validate(_), do: {:error, :not_string}
end