defmodule Discord.Gateway.ServerHandlers do
  import Discord.Gateway.ServerMacros

  alias Discord.Gateway.Server
  alias Discord.Gateway.State
  alias Discord.Gateway.Commands
  alias Discord.EtfFormat

  #
  # - connect
  # - disconnect
  # - heartbeat
  # - identify
  # - resume
  #

  @doc """
    Connect
  """
  def handle_connect(state = %State{gateway_url: "wss://" <> gateway_url}) do
    IO.puts("Attempting to connect to Discord Gateway...")

    {:ok, _conn_pid} =
      :gun.open(String.to_charlist(gateway_url), 443, %{
        # we handle our own reconnections so we don't have to keep track of gun's retries
        retry: 0,
        # use :http and not :http2 because WS over HTTP/2 is not supported by gun as of 6/21/2020
        protocols: [:http]
      })

    state
    |> State.set_last_sent(:connect)
    |> noreply
  end

  @doc """
    Disconnect
  """
  invalid_stream_guard(:handle_disconnect)

  def handle_disconnect(state = %State{conn_pid: conn_pid}, _last_stream_ref) do
    :gun.shutdown(conn_pid)

    state
    |> State.clear_conn()
    |> State.set_last_sent(:disconnect)
    |> noreply
  end

  @doc """
    Heartbeat
  """
  invalid_stream_guard(:send_heartbeat_handler)

  @spec handle_send_heartbeat(Discord.Gateway.State.t(), any) ::
          {:noreply, Discord.Gateway.State.t()}
  def handle_send_heartbeat(
        state = %State{
          conn_pid: conn_pid,
          stream_ref: stream_ref,
          hb_interval: hb_interval,
          hb_acked: hb_acked
        },
        _last_stream_ref
      ) do
    if hb_acked do
      Server.schedule_heartbeat(self(), hb_interval, stream_ref)
      send_frame(conn_pid, Commands.Heartbeat.new(state))

      state
      |> State.unset_hb_acked()
    else
      # TODO: "If a client does not receive a heartbeat ack between its attempts at sending heartbeats,
      # it should immediately terminate the connection with a non-1000 close code, reconnect, and attempt to resume."
      :gun.close(conn_pid)
      state
    end
    |> State.set_last_sent(:heartbeat)
    |> noreply
  end

  @doc """
    Identify
  """
  invalid_stream_guard(:send_identify_handler)

  def handle_send_identify(state = %State{conn_pid: conn_pid}, _last_stream_ref) do
    send_frame(conn_pid, Commands.Identify.new(state))

    state
    |> State.set_last_sent(:identify)
    |> noreply
  end

  @doc """
    Resume
  """
  invalid_stream_or_session_guard(:send_resume_handler)

  def handle_send_resume(state = %State{conn_pid: conn_pid}, _last_stream_ref, _session_id) do
    # TODO: DOUBLE CHECK OVER THIS WHEN YOU ARE NOT TIRED

    send_frame(conn_pid, Commands.Resume.new(state))

    state
    |> State.set_last_sent(:resume)
    |> noreply
  end

  # HELPERS
  defp send_frame(conn_pid, message) do
    IO.puts("Sending frame: #{Kernel.inspect(message)}")
    :gun.ws_send(conn_pid, {:binary, EtfFormat.encode(message)})
  end

  defp noreply(state), do: {:noreply, state}
end
