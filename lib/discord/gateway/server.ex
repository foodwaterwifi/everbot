defmodule Discord.Gateway.Server do
  @moduledoc false
  # require ExUnit.Assertions

  alias Discord.Gateway.ServerHandlers
  alias Discord.Gateway.State
  alias Discord.Gateway.MessageHandlers
  # alias Commands.{Heartbeat, Identify}

  use GenServer

  @version_and_encoding "/?v=6&encoding=etf"

  def start_link(agent_pid, gateway_url, bot_token, intents) do
    {:ok, pid} = GenServer.start_link(__MODULE__, {agent_pid, gateway_url, bot_token, intents})

    connect(pid)
    {:ok, pid}
  end

  def init({agent_pid, gateway_url, bot_token, intents}) do
    {:ok, State.new(self(), agent_pid, gateway_url, bot_token, intents)}
  end

  # Async Calls

  def connect(pid) do
    GenServer.cast(pid, :connect)
  end

  def disconnect(pid, stream_ref) do
    GenServer.cast(pid, {:disconnect, stream_ref})
  end

  def send_heartbeat(pid, stream_ref) do
    GenServer.cast(pid, {:send_heartbeat, stream_ref})
  end

  def schedule_heartbeat(pid, hb_interval, stream_ref) do
    Kernel.spawn_link(fn ->
      Process.sleep(hb_interval)
      send_heartbeat(pid, stream_ref)
    end)
  end

  def send_identify(pid, stream_ref) do
    GenServer.cast(pid, {:send_identify, stream_ref})
  end

  def send_resume(pid, stream_ref, session_id) do
    GenServer.cast(pid, {:send_resume, stream_ref, session_id})
  end

  # Event Handlers

  defp on_gun_up(state = %State{}, conn_pid, :http) do
    IO.puts("Connected to Discord Gateway via HTTP.")

    :gun.ws_upgrade(conn_pid, String.to_charlist(@version_and_encoding))

    {:noreply, state |> State.set_conn_pid(conn_pid)}
  end

  defp on_gun_upgrade(state = %State{}, stream_ref) do
    IO.puts("Upgraded connection to Discord Gateway to WebSocket.")

    {:noreply, state |> State.set_stream_ref(stream_ref)}
  end

  defp on_gun_ws(state = %State{}, frame) do
    IO.puts("Got a WebSocket frame: #{Kernel.inspect(frame)}")

    {:binary, binary_message} = frame

    {:ok, state} = MessageHandlers.handle_message(binary_message, state)

    {:noreply, state}
  end

  defp on_gun_down(state = %State{}) do
    IO.puts("Lost connection to Discord Gateway.")

    # Reconnect automatically, but only after 5 seconds so we don't
    # flood identifies
    Kernel.spawn_link(fn ->
      Process.sleep(5000)
      connect(self())
    end)

    {:noreply, State.clear_conn(state)}
  end

  defp on_gun_error(state = %State{}, reason) do
    IO.puts(
      "Encountered an error in the connection to Discord Gateway: #{Kernel.inspect(reason)}."
    )

    {:noreply, state}
  end

  # GenServer Handlers

  # :connect
  def handle_cast(:connect, state = %State{}), do: ServerHandlers.handle_connect(state)

  def handle_cast({:disconnect, last_stream_ref}, state = %State{}),
    do: ServerHandlers.handle_disconnect(state, last_stream_ref)

  # :send_identify
  def handle_cast({:send_identify, last_stream_ref}, state = %State{}),
    do: ServerHandlers.handle_send_identify(state, last_stream_ref)

  # :send_resume
  def handle_cast({:send_resume, last_stream_ref, session_id}, state = %State{}),
    do: ServerHandlers.handle_send_resume(state, last_stream_ref, session_id)

  # :send_heartbeat (takes a conn_pid so the scheduled calls don't send for the wrong connection)
  def handle_cast({:send_heartbeat, last_stream_ref}, state = %State{}),
    do: ServerHandlers.handle_send_heartbeat(state, last_stream_ref)

  # :gun_up
  def handle_info({:gun_up, conn_pid, protocol}, state = %State{}),
    do: on_gun_up(state, conn_pid, protocol)

  # :gun_down
  def handle_info({:gun_down, _conn_pid, _protocol, _reason, _killed_streams}, state = %State{}),
    do: on_gun_down(state)

  # :gun_upgrade
  def handle_info({:gun_upgrade, _conn_pid, stream_ref, _protocols, _headers}, state = %State{}),
    do: on_gun_upgrade(state, stream_ref)

  # :gun_error
  def handle_info({:gun_error, _conn_pid, _stream_ref, reason}, state = %State{}),
    do: on_gun_error(state, reason)

  # :gun_ws
  def handle_info({:gun_ws, _conn_pid, _stream_ref, frame}, state = %State{}),
    do: on_gun_ws(state, frame)

  def handle_info(message, state = %State{}) do
    IO.puts(
      "Got an unhandled message: #{Kernel.inspect(message)}, state: #{Kernel.inspect(state)}."
    )

    {:noreply, state}
  end
end
