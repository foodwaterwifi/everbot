defmodule Everbot do
  require Everbot.State, as: State
  require Discord.Gateway.Server, as: GatewayServer

  @moduledoc """
  Documentation for `Everbot`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Everbot.hello()
      :world

  """
  def hello do
    state =
      State.new()
      |> State.get_bot_token()
      |> State.get_gateway_url()

    IO.puts("Main state: #{Kernel.inspect(state)}")

    intents = [
      :guilds,
      :guild_messages
    ]

    {:ok, pid} = GatewayServer.start_link(self(), state.gateway_url, state.bot_token, intents)

    IO.puts("Started Gateway Server, pid: #{pid}")
  end
end
