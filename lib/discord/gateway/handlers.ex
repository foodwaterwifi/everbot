defmodule Discord.Gateway.Handlers do
  alias Discord.Gateway.State, as: State
  alias Discord.Gateway.Server, as: Server
  alias Discord.EtfFormat

  def handle_message(binary_message, state) do
    # TODO: create a list of possible atoms Discord sends us so we can
    # set [:safe] for the binary_to_term opts
    message = EtfFormat.decode(binary_message)
    IO.puts("Received frame: #{Kernel.inspect(message)}")
    handle(message, state)
  end

  @doc """
    Dispatch
    "An event was dispatched."
  """
  def handle(%{op: 0, d: _data, s: seq, t: _type}, state = %State{}) do
    # TODO: dispatch this event to subscribers

    {:ok, State.set_seq(state, seq)}
  end

  @doc """
    Heartbeat
    TODO: do we receive these..?
    "Fired periodically by the client to keep the connection alive."
  """
  def handle(%{op: 1, d: _data}, state = %State{}) do
    # TODO
    IO.puts("WE GOT A HEARTBEAT???")

    {:ok, state}
  end

  @doc """
    Reconnect
    You should attempt to reconnect and resume immediately.
  """
  def handle(%{op: 7, d: _data}, state = %State{}) do
    # TODO
    {:ok, state}
  end

  @doc """
    Invalid Session
    "The session has been invalidated. You should reconnect and identify/resume accordingly."

    "Sent to indicate one of at least three different situations:
    - the gateway could not initialize a session after receiving an Opcode 2 Identify
    - the gateway could not resume a previous session after receiving an Opcode 6 Resume
    - the gateway has invalidated an active session and is requesting client action
    The inner d key is a boolean that indicates whether the session may be resumable."
  """
  def handle(%{op: 9, d: _data}, state = %State{}) do
    # TODO clear session data
    {:ok, State.clear_session_data(state)}
  end

  @doc """
    Hello
    "Sent immediately after connecting, contains the heartbeat_interval to use."
  """
  def handle(
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
  def handle(%{op: 11, d: _data}, state = %State{}) do
    {:ok, State.set_hb_acked(state)}
  end
end
