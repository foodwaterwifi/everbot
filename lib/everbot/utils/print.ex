defmodule Everbot.Utils.Print do
  def out(list) when is_list(list), do: "[" <> out_list(list, nil) <> "]"
  def out(tuple) when is_tuple(tuple), do: "{" <> out_list(Tuple.to_list(tuple), nil) <> "}"
  def out(bin) when is_binary(bin), do: Kernel.inspect(bin)
  def out(any), do: Kernel.inspect(any)

  def out_list([head | tail], nil), do: out_list(tail, out(head))
  def out_list([head | tail], acc), do: out_list(tail, acc <> ", " <> out(head))
  def out_list([], nil), do: ""
  def out_list([], acc), do: acc
end
