defmodule Discord.Gateway.MessageHandlers do
  alias Discord.Gateway.State, as: State
  alias Discord.Gateway.Server, as: Server
  alias Discord.EtfFormat

  def handle_message(binary_message, state) do
    # TODO: create a list of possible atoms Discord sends us so we can
    # set [:safe] for the binary_to_term opts
    message = EtfFormat.decode(binary_message)
    IO.puts("Received frame: #{Kernel.inspect(message)}")
    do_handle_message(message, state)
  end

  @doc """
    Dispatch
    "An event was dispatched."
  """
  def do_handle_message(%{op: 0, d: data, s: seq, t: type}, state = %State{}) do
    state =
      case {type, data} do
        {:READY, %{session_id: session_id}} -> State.set_session(state, session_id, seq)
        _ -> state
      end

    # TODO: dispatch this event to subscribers

    {:ok, State.set_seq(state, seq)}
  end

  @doc """
    Heartbeat
    TODO: do we receive these..?
    "Fired periodically by the client to keep the connection alive."
  """
  def do_handle_message(%{op: 1, d: _data}, state = %State{}) do
    # TODO
    IO.puts("WE GOT A HEARTBEAT???")

    {:ok, state}
  end

  @doc """
    Reconnect
    You should attempt to reconnect and resume immediately.
  """
  def do_handle_message(%{op: 7, d: _data}, state = %State{}) do
    # TODO
    {:ok, state}
  end

  @doc """
    Invalid Session
    "The session has been invalidated. You should reconnect and identify/resume accordingly."

    "Sent to indicate one of at least three different situations:
    - the gateway could not initialize a session after receiving an Opcode 2 Identify
      - NOTE: In this case, we will have no session.
    - the gateway could not resume a previous session after receiving an Opcode 6 Resume
      - NOTE: In this case, we will have a session. Wait 1 to 5 seconds before sending Identify.
    - the gateway has invalidated an active session and is requesting client action
      - NOTE: In this case, we will have a session.
    The inner d key is a boolean that indicates whether the session may be resumable."
  """
  def do_handle_message(
        %{op: 9, d: true},
        state = %State{server_pid: pid, stream_ref: stream_ref, session_id: session_id}
      )
      when not is_nil(session_id) do
    Server.send_resume(pid, stream_ref, session_id)

    {:ok, state}
  end

  def do_handle_message(
        %{op: 9},
        state = %State{server_pid: pid, stream_ref: stream_ref, last_sent: last_sent}
      ) do
    Kernel.spawn_link(fn ->
      wait_time =
        case last_sent do
          :resume -> trunc(1000 + :rand.uniform_real() * 4000)
          _ -> 5000
        end

      Process.sleep(wait_time)
      Server.send_identify(pid, stream_ref)
    end)

    {:ok, State.clear_session(state)}
  end

  @doc """
    Hello
    "Sent immediately after connecting, contains the heartbeat_interval to use."
  """
  def do_handle_message(
        %{op: 10, d: %{heartbeat_interval: hb_interval}},
        state = %State{server_pid: pid, stream_ref: stream_ref}
      ) do
    Server.send_heartbeat(pid, stream_ref)
    Server.send_identify(pid, stream_ref)
    {:ok, State.set_hb_interval(state, hb_interval)}
  end

  @doc """
    Heartbeat ACK
    "Sent in response to receiving a heartbeat to acknowledge that it has been received."
  """
  def do_handle_message(%{op: 11, d: _data}, state = %State{}) do
    {:ok, State.set_hb_acked(state)}
  end
end
