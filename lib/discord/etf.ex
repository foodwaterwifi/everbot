defmodule Discord.EtfFormat do
  @sensitive_fields [:password, :token, :secret, "password", "token", "secret"]

  def encode(term) do
    unwrapped = unwrap_sensitive(term)
    :erlang.term_to_binary(unwrapped, [])
  end

  defp unwrap_sensitive(%Discord.Sensitive{value: value}), do: value

  defp unwrap_sensitive(map) when is_map(map) or is_struct(map) do
    map
    |> Map.keys()
    |> Enum.reduce(map, fn key, acc ->
      acc
      |> Map.get_and_update(key, fn term -> {term, unwrap_sensitive(term)} end)
      |> elem(1)
    end)
  end

  defp unwrap_sensitive(list) when is_list(list),
    do: Enum.map(list, fn elem -> unwrap_sensitive(elem) end)

  defp unwrap_sensitive(term), do: term

  def decode(binary) do
    wrap_sensitive(:erlang.binary_to_term(binary))
  end

  defp wrap_sensitive(map) when is_map(map) or is_struct(map) do
    map
    |> Map.keys()
    |> Enum.reduce(map, fn key, acc ->
      if key in @sensitive_fields do
        acc
        |> Map.get_and_update(key, fn term -> {term, Discord.Sensitive.new(term)} end)
        |> elem(1)
      else
        acc
      end
    end)
  end

  defp wrap_sensitive(list) when is_list(list),
    do: Enum.map(list, fn elem -> wrap_sensitive(elem) end)

  defp wrap_sensitive(term), do: term
end
