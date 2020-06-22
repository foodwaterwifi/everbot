defmodule GunReference do
  # CONNECTION MESSAGES

  # GUN_UP
  def handle_info(resp = {:gun_up, conn_pid, _protocol}, state) do
    # IO.puts("Gun_up: #{Print.out(resp)}")
    stream_ref = :gun.get(conn_pid, String.to_charlist(""))

    {:noreply,
     state |> Map.put_new(:conn_pid, conn_pid) |> Map.put_new(:init_stream_ref, stream_ref)}
  end

  # GUN_SOCKS_UP
  def handle_info(resp = {:gun_socks_up, _conn_pid, _protocol}, state),
    do: handle_gun_response(resp, state)

  # GUN_DOWN
  def handle_info(resp = {:gun_down, _conn_pid, _protocol, _reason, _killed_streams}, state) do
    # IO.puts("Gun_down: #{Print.out(resp)}")
    {:noreply, %{state | conn_pid: nil}}
  end

  # GUN_UPGRADE
  def handle_info(resp = {:gun_upgrade, _conn_pid, _stream_ref, _protocols, _headers}, state),
    do: handle_gun_response(resp, state)

  # GUN_ERROR
  def handle_info(resp = {:gun_error, _conn_pid, _stream_ref, _reason}, state),
    do: handle_gun_response(resp, state)

  def handle_info(resp = {:gun_error, _conn_pid, _reason}, state),
    do: handle_gun_response(resp, state)

  # RESPONSE MESSAGES

  # GUN_PUSH
  def handle_info(
        resp = {:gun_push, _conn_pid, _stream_ref, _new_stream_ref, _method, _uri, _headers},
        state
      ),
      do: handle_gun_response(resp, state)

  # GUN_INFORM
  def handle_info(resp = {:gun_inform, _conn_pid, _stream_ref, _status, _headers}, state),
    do: handle_gun_response(resp, state)

  # GUN_RESPONSE
  def handle_info(
        resp = {:gun_response, _conn_pid, _stream_ref, _is_fin, _http_status_code, _headers},
        state
      ),
      do: handle_gun_response(resp, state)

  # GUN_DATA
  def handle_info(resp = {:gun_data, _conn_pid, _stream_ref, _is_fin, _data}, state),
    do: handle_gun_response(resp, state)

  # GUN_TRAILERS
  def handle_info(resp = {:gun_trailers, _conn_pid, _stream_ref, _headers}, state),
    do: handle_gun_response(resp, state)

  # WEBSOCKET

  # GUN_WS
  def handle_info(resp = {:gun_ws, _conn_pid, _stream_ref, _frame}, state),
    do: handle_gun_response(resp, state)

  defp handle_gun_response(resp, state) do
    # IO.puts("Gun: #{Print.out(resp)}")
    {:noreply, state}
  end
end
