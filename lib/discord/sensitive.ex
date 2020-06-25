defmodule Discord.Sensitive do
  alias __MODULE__, as: Sensitive
  @derive {Inspect, only: []}
  defstruct value: "invalid"

  def new(token) do
    %Sensitive{
      value: token
    }
  end
end

defimpl String.Chars, for: Discord.Sensitive do
  def to_string(_), do: "%Sensitive{...}"
end
