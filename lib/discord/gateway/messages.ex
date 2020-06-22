defmodule Discord.Messages do
  def new_identify(bot_token, intents) do
    %{
      token: bot_token,
      properties: %{
        "$os": "linux",
        "$browser": "elixir",
        "$device": "elixir"
      },
      compress: false,
      large_threshold: 50,
      # shard: nil,
      # presence: nil,
      # guild_subscriptions: nil,
      intents: intents
    }
  end
end
