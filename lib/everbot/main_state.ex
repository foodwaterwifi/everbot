defmodule Everbot.MainState do
  # States:
  # - waiting_on_connection
  # -
  #
  #
  #
  #
  #
  #

  def new() do
    state = %{
      state: :init,
      gateway_url: nil,
      bot_token: nil
    }

    state
  end

  def get_bot_token(state) do
    {:ok, content} = File.read("~/secrets/bot_token")

    bot_token =
      content
      |> String.split("\n", trim: true)
      |> hd()

    %{state | bot_token: bot_token}
  end

  def get_gateway_url(state) do
    {:ok, conn_pid} = :gun.open(String.to_charlist("discord.com"), 443)
    {:ok, _protocol} = :gun.await_up(conn_pid)
    stream_ref = :gun.get(conn_pid, "/api/gateway")
    {:ok, gateway_url} = await_gateway_url(conn_pid, stream_ref)
    %{state | gateway_url: gateway_url}
  end

  defp await_gateway_url(conn_pid, stream_ref) do
    case :gun.await(conn_pid, stream_ref) do
      {:data, is_fin, payload} ->
        await_gateway_url_handle_data(conn_pid, stream_ref, is_fin, payload)

      {:response, :nofin, _, _} ->
        await_gateway_url(conn_pid, stream_ref)

      {:response, :fin, _, _} ->
        :error

      {:error, _} ->
        :error
    end
  end

  defp await_gateway_url_handle_data(conn_pid, stream_ref, :nofin, ""),
    do: await_gateway_url(conn_pid, stream_ref)

  defp await_gateway_url_handle_data(_conn_pid, _stream_ref, :fin, ""), do: :error

  defp await_gateway_url_handle_data(conn_pid, stream_ref, is_fin, payload) do
    IO.puts(Kernel.inspect(Jason.decode!(payload)))

    case {is_fin, Jason.decode!(payload)} do
      {_, %{"url" => url}} -> {:ok, url}
      {:fin, _} -> :error
      {:nofin, _} -> await_gateway_url(conn_pid, stream_ref)
    end
  end
end
