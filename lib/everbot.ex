defmodule Everbot do
  require Everbot.MainState, as: State
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

    {:ok, pid} = GatewayServer.start_link(self(), state.gateway_url, state.bot_token)
    IO.puts("Started Gateway Server, pid: #{pid}")
  end
end
