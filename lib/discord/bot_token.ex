defmodule Discord.BotToken do
  @derive {Inspect, only: []}
  defstruct value: "invalid"
end

defimpl String.Chars, for: Everbot.Discord.BotToken do
  def to_string(_), do: "%BotToken{...}"
end
