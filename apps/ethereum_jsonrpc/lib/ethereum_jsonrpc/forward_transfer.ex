defmodule EthereumJSONRPC.ForwardTransfer do
  require Logger

  import EthereumJSONRPC, only: [quantity_to_integer: 1]

  alias EthereumJSONRPC

  @type t :: %{
          String.t() =>
            EthereumJSONRPC.address()
            | EthereumJSONRPC.quantity()
            | String.t()
        }

  @type elixir :: %{
          String.t() => EthereumJSONRPC.address() | String.t() | non_neg_integer()
        }

  @type params :: %{
          block_number: non_neg_integer(),
          to_address_hash: EthereumJSONRPC.address(),
          value: non_neg_integer()
        }

  @spec elixir_to_params(elixir) :: params
  def elixir_to_params(%{
        "blockNumber" => block_number,
        "to" => to_address_hash,
        "value" => value
      }) do
    result = %{
      block_number: block_number,
      to_address_hash: to_address_hash,
      value: value
    }
    result
  end

  @spec to_elixir(t) :: elixir
  def to_elixir(forward_transfer) when is_map(forward_transfer) do
    forward_transfer
    |> Enum.reduce({:ok, %{}}, &entry_reducer/2)
    |> ok!(forward_transfer)
  end

  defp entry_reducer(entry, acc) do
    entry
    |> entry_to_elixir()
    |> elixir_reducer(acc)
  end

  defp elixir_reducer({:ok, {key, elixir_value}}, {:ok, elixir_map}) do
    {:ok, Map.put(elixir_map, key, elixir_value)}
  end

  defp elixir_reducer({:ok, {_, _}}, {:error, _reasons} = acc_error), do: acc_error
  defp elixir_reducer({:error, reason}, {:ok, _}), do: {:error, [reason]}
  defp elixir_reducer({:error, reason}, {:error, reasons}), do: {:error, [reason | reasons]}
  defp elixir_reducer(:ignore, acc), do: acc

  defp ok!({:ok, elixir}, _forward_transfer), do: elixir

  defp ok!({:error, reasons}, forward_transfer) do
    formatted_errors = Enum.map_join(reasons, "\n", fn reason -> "  #{inspect(reason)}" end)

    raise ArgumentError,
          """
          Could not convert forward_transfer to elixir

          forward_transfer:
            #{inspect(forward_transfer)}

          Errors:
          #{formatted_errors}
          """
  end

  def entry_to_elixir({key, value})
       when key in ~w(to),
       do: {key, value}

  def entry_to_elixir({key, quantity})
       when key in ~w(value blockNumber) and
              quantity != nil do
    {key, quantity_to_integer(quantity)}
  end

  def entry_to_elixir(_) do
    {nil, nil}
  end
end
