defmodule Discord.Gateway.Server do
  @moduledoc false
  require ExUnit.Assertions

  require Discord.Gateway.State, as: State
  require Discord.Gateway.Handler, as: Handler

  alias Discord.Gateway.Commands, as: Commands
  require Commands.{Heartbeat, Identify}

  use GenServer

  @version_and_encoding "/?v=6&encoding=etf"

  def start_link(agent_pid, gateway_url, bot_token) do
    {:ok, pid} = GenServer.start_link(__MODULE__, State.new(agent_pid, gateway_url, bot_token))
    connect(pid)
    {:ok, pid}
  end

  def init(state) do
    {:ok, state}
  end

  # Private Interface

  defp send_frame(conn_pid, message) do
    :gun.ws_send(conn_pid, {:binary, :erlang.term_to_binary(message)})
  end

  # Async Calls

  defp connect(pid) do
    GenServer.cast(pid, :connect)
  end

  defp send_heartbeat(pid) do
    GenServer.cast(pid, :send_heartbeat)
  end

  defp send_identify(pid) do
    GenServer.cast(pid, :send_identify)
  end

  # Async Call Handlers

  defp do_connect(state = %{gateway_url: "wss://" <> gateway_url}) do
    IO.puts("Attempting to connect to Discord Gateway...")

    {:ok, conn_pid} =
      :gun.open(String.to_charlist(gateway_url), 443, %{
        # we handle our own reconnections so we don't have to keep track of gun's retries
        retry: 0,
        # use :http and not :http2 because WS over HTTP/2 is not supported by gun as of 6/21/2020
        protocols: [:http]
      })

    {:noreply, state}
  end

  defp do_send_heartbeat(state = %{conn_pid: conn_pid, heartbeat_interval: interval}) do
    Process.send_after(self(), :send_heartbeat, interval)

    send_frame(conn_pid, Commands.Heartbeat.new(state))

    {:noreply, state}
  end

  defp do_send_identify(state = %{conn_pid: conn_pid}) do
    send_frame(conn_pid, Commands.Identify.new(state))

    {:noreply, state}
  end

  # Event Handlers

  defp on_gun_up(state = %{conn_pid: conn_pid}, :http) do
    IO.puts("Connected to Discord Gateway via HTTP.")

    :gun.ws_upgrade(conn_pid, String.to_charlist(@version_and_encoding))

    {:noreply, state |> State.set_conn_pid(conn_pid)}
  end

  defp on_gun_upgrade(state, stream_ref) do
    IO.puts("Upgraded connection to Discord Gateway to WebSocket.")

    {:noreply, state |> State.set_stream_ref(stream_ref)}
  end

  defp on_gun_ws(state, frame) do
    IO.puts("Got a WebSocket frame: #{Kernel.inspect(frame)}")

    {:binary, message} = frame

    Handler.handle_message(message)

    {:noreply, state}
  end

  defp on_gun_down(state) do
    IO.puts("Lost connection to Discord Gateway.")

    # TODO: make sure we handle any requests that did not get a reply

    connect(self())

    {:noreply, state |> State.clear_conn_data()}
  end

  defp on_gun_error(state, reason) do
    IO.puts(
      "Encountered an error in the connection to Discord Gateway: #{Kernel.inspect(reason)}."
    )

    {:noreply, state}
  end

  defp on_down(state = %{conn_pid: conn_pid}) do
    IO.puts("#{__MODULE__} encountered a fatal error. Crashing.")

    if conn_pid != nil do
      :gun.close(conn_pid)
    end

    # TODO: send the state off to the agent
    {:noreply, state}
  end

  # GenServer Handlers

  # :connect
  def handle_cast(:connect, state), do: do_connect(state)

  # :send_heartbeat
  def handle_info(:send_heartbeat, state), do: do_send_heartbeat(state)

  # :send_identify
  def handle_info(:send_identify, state), do: do_send_identify(state)

  # :DOWN
  def handle_info(:DOWN, state), do: on_down(state)

  # :gun_up
  def handle_info({:gun_up, _conn_pid, protocol}, state),
    do: on_gun_up(state, protocol)

  # :gun_down
  def handle_info({:gun_down, _conn_pid, _protocol, _reason, _killed_streams}, state),
    do: on_gun_down(state)

  # :gun_upgrade
  def handle_info({:gun_upgrade, _conn_pid, stream_ref, _protocols, _headers}, state),
    do: on_gun_upgrade(state, stream_ref)

  # :gun_error
  def handle_info({:gun_error, _conn_pid, _stream_ref, reason}, state),
    do: on_gun_error(state, reason)

  # :gun_ws
  def handle_info({:gun_ws, _conn_pid, _stream_ref, frame}, state),
    do: on_gun_ws(state, frame)

  def handle_info(message, state) do
    IO.puts(
      "Got an unhandled message: #{Kernel.inspect(message)}, state: #{Kernel.inspect(state)}."
    )

    {:noreply, state}
  end
end
