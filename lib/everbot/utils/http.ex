defmodule Everbot.Utils.Http do
  # def await_conn(url, port), do: await_conn(url, port, [])

  def await_conn(url, port, opts) do
    {:ok, conn_pid} = :gun.open(String.to_charlist(url), port, opts)
    :gun.await_up(conn_pid)
  end

  def sync_request() do
  end
end
