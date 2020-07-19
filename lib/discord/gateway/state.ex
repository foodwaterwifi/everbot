defmodule Discord.Gateway.State do
  alias __MODULE__, as: State
  alias Discord.Gateway.Intents, as: Intents

  #         # a priori state
  defstruct server_pid: nil,
            agent_pid: nil,
            gateway_url: nil,
            bot_token: nil,
            intents: nil,
            # :gun values
            conn_pid: nil,
            stream_ref: nil,
            # gateway session state
            hb_interval: nil,
            hb_acked: nil,
            session_id: nil,
            seq: nil,
            last_sent: nil,
            # client state
            event_subs: nil

  def new(server_pid, agent_pid, gateway_url, bot_token, intents) do
    %State{
      # the pid of our server
      server_pid: server_pid,
      # the Agent we use to store our state
      agent_pid: agent_pid,
      # the url we connect to the Gateway with
      gateway_url: gateway_url,
      # the bot token
      bot_token: bot_token,
      # an integer representing the events the bot intends to receive
      intents: Intents.new(intents),
      #
      # the pid of the connection process, or nil if not connected
      conn_pid: nil,
      # the stream ref of the WebSocket stream, or nil if none
      stream_ref: nil,
      #
      # the interval at which to send heartbeats
      hb_interval: nil,
      # whether the most recent heartbeat we sent out has been acked
      hb_acked: true,
      # the session id, used for resuming sessions
      session_id: nil,
      # the sequence number
      seq: nil,
      # the last command we sent
      last_sent: :disconnect,
      #
      # event subscriptions: the events we should dispatch to the client
      event_subs: nil
    }
  end

  # def set_server_pid(state = %State{}, server_pid) do
  #   %{state | server_pid: server_pid}
  # end

  def set_last_sent(state = %State{}, last_sent) do
    %{state | last_sent: last_sent}
  end

  def set_conn_pid(state = %State{}, conn_pid) do
    %{state | conn_pid: conn_pid}
  end

  def set_stream_ref(state = %State{}, stream_ref) do
    %{state | stream_ref: stream_ref}
  end

  def set_hb_interval(state = %State{}, interval) do
    %{state | hb_interval: interval}
  end

  def unset_hb_acked(state = %State{}) do
    %{state | hb_acked: false}
  end

  def set_hb_acked(state = %State{}) do
    %{state | hb_acked: true}
  end

  def clear_conn(state = %State{}) do
    %{
      state
      | conn_pid: nil,
        stream_ref: nil,
        hb_interval: nil,
        hb_acked: true,
        last_sent: :disconnect
    }
  end

  def set_session(state = %State{}, session_id, seq) do
    %{state | session_id: session_id, seq: seq}
  end

  def clear_session(state = %State{}) do
    %{state | session_id: nil, seq: nil}
  end
end
