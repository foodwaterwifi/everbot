defmodule Discord.Gateway.State do
  defstruct server_pid: nil,
            agent_pid: nil,
            gateway_url: nil,
            bot_token: nil,
            conn_pid: nil,
            stream_ref: nil,
            heartbeat_interval: nil,
            seq: nil

  def new(server_pid, agent_pid, gateway_url) do
    state = %Discord.Gateway.State{
      # the pid of our server
      server_pid: server_pid,
      # the Agent we use to store our state
      agent_pid: agent_pid,
      # the url we connect to the Gateway with
      gateway_url: gateway_url,
      # the bot token
      bot_token: nil,
      # the pid of the connection process, or nil if not connected
      conn_pid: nil,
      # the stream ref of the WebSocket stream, or nil if none
      stream_ref: nil,
      # the interval at which to send heartbeats
      heartbeat_interval: nil,
      # the sequence number
      seq: nil
    }

    state
  end

  def set_conn_pid(state, conn_pid) do
    %{state | conn_pid: conn_pid}
  end

  def set_stream_ref(state, stream_ref) do
    %{state | stream_ref: stream_ref}
  end

  def clear_conn_data(state) do
    %{state | conn_pid: nil, stream_ref: nil}
  end
end
