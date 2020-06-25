defmodule Discord.Gateway.Server do
  @moduledoc false
  # require ExUnit.Assertions

  alias Discord.Gateway.State, as: State
  alias Discord.Gateway.Handlers, as: Handlers
  alias Discord.Gateway.Commands, as: Commands
  alias Discord.EtfFormat, as: EtfFormat
  # alias Commands.{Heartbeat, Identify}

  use GenServer

  @version_and_encoding "/?v=6&encoding=etf"

  def start_link(agent_pid, gateway_url, bot_token, intents) do
    {:ok, pid} =
      GenServer.start_link(__MODULE__, State.new(agent_pid, gateway_url, bot_token, intents))

    connect(pid)
    {:ok, pid}
  end

  def init(state = %State{}) do
    {:ok, state}
  end

  # Private Interface

  defp send_frame(conn_pid, message) do
    IO.puts("Sending frame: #{Kernel.inspect(message)}")
    :gun.ws_send(conn_pid, {:binary, EtfFormat.encode(message)})
  end

  # Async Calls

  defp connect(pid) do
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

  # Async Call Handlers

  defp connect_handler(state = %State{gateway_url: "wss://" <> gateway_url}) do
    IO.puts("Attempting to connect to Discord Gateway...")

    {:ok, _conn_pid} =
      :gun.open(String.to_charlist(gateway_url), 443, %{
        # we handle our own reconnections so we don't have to keep track of gun's retries
        retry: 0,
        # use :http and not :http2 because WS over HTTP/2 is not supported by gun as of 6/21/2020
        protocols: [:http]
      })

    {:noreply, state |> State.set_server_pid(self())}
  end

  defp disconnect_handler(state = %State{stream_ref: stream_ref}, last_stream_ref)
       when is_nil(stream_ref) or stream_ref != last_stream_ref,
       do: {:noreply, state}

  defp disconnect_handler(state = %State{conn_pid: conn_pid}, _last_stream_ref) do
    :gun.shutdown(conn_pid)
    {:noreply, State.clear_conn_data(state)}
  end

  # Heartbeat needs the extra guard because its messages are scheduled
  defp send_heartbeat_handler(state = %State{stream_ref: stream_ref}, last_stream_ref)
       when is_nil(stream_ref) or stream_ref != last_stream_ref,
       do: {:noreply, state}

  defp send_heartbeat_handler(
         state = %State{
           conn_pid: conn_pid,
           stream_ref: stream_ref,
           hb_interval: hb_interval,
           hb_acked: hb_acked
         },
         _last_stream_ref
       ) do
    if hb_acked do
      schedule_heartbeat(self(), hb_interval, stream_ref)
      send_frame(conn_pid, Commands.Heartbeat.new(state))
      {:noreply, State.unset_hb_acked(state)}
    else
      # TODO: "If a client does not receive a heartbeat ack between its attempts at sending heartbeats,
      # it should immediately terminate the connection with a non-1000 close code, reconnect, and attempt to resume."
      :gun.close(conn_pid)
      {:noreply, state}
    end
  end

  defp send_identify_handler(state = %State{stream_ref: stream_ref}, last_stream_ref)
       when is_nil(stream_ref) or stream_ref != last_stream_ref,
       do: {:noreply, state}

  defp send_identify_handler(state = %State{conn_pid: conn_pid}, _last_stream_ref) do
    send_frame(conn_pid, Commands.Identify.new(state))

    {:noreply, state}
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

    {:ok, state} = Handlers.handle_message(binary_message, state)

    {:noreply, state}
  end

  defp on_gun_down(state = %State{}) do
    IO.puts("Lost connection to Discord Gateway.")

    # TODO: make sure we handle any requests that did not get a reply

    connect(self())

    {:noreply, State.clear_conn_data(state)}
  end

  defp on_gun_error(state = %State{}, reason) do
    IO.puts(
      "Encountered an error in the connection to Discord Gateway: #{Kernel.inspect(reason)}."
    )

    {:noreply, state}
  end

  # TODO: :DOWN is when supervised proceses fail, not when we fail
  defp on_down(state = %State{conn_pid: conn_pid}) do
    IO.puts("#{__MODULE__} encountered a fatal error. Crashing.")

    if conn_pid != nil do
      :gun.close(conn_pid)
    end

    # TODO: send the state off to the agent
    {:noreply, state}
  end

  # GenServer Handlers

  # :connect
  def handle_cast(:connect, state = %State{}), do: connect_handler(state)

  def handle_cast({:disconnect, last_stream_ref}, state = %State{}),
    do: disconnect_handler(state, last_stream_ref)

  # :send_identify
  def handle_cast({:send_identify, last_stream_ref}, state = %State{}),
    do: send_identify_handler(state, last_stream_ref)

  # :send_heartbeat (takes a conn_pid so the scheduled calls don't send for the wrong connection)
  def handle_cast({:send_heartbeat, last_stream_ref}, state = %State{}),
    do: send_heartbeat_handler(state, last_stream_ref)

  # :DOWN
  def handle_info(:DOWN, state = %State{}), do: on_down(state)

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
