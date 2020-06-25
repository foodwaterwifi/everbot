defmodule Discord.Gateway.Commands.Identify do
  alias __MODULE__, as: Identify

  @moduledoc """
    Used to trigger the initial handshake with the gateway.
  """
  defstruct safety_container: nil

  def new(_state = %{bot_token: bot_token, intents: intents}) do
    %{
      "op" => 2,
      "d" => %{
        "token" => bot_token,
        "properties" => %{
          "$os" => "linux",
          "$browser" => "everbot",
          "$device" => "everbot"
        },
        "compress" => false,
        # "shard" => nil,
        # "presence" => nil,
        # "guild_subscriptions" => nil,
        "intents" => intents
      }
    }
  end
end
