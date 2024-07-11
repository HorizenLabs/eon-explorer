defmodule Explorer.Helper do
  @moduledoc """
  Common explorer helper
  """

  @max_safe_integer round(:math.pow(2, 63)) - 1

  def parse_integer(nil), do: nil

  def parse_integer(string) do
    case Integer.parse(string) do
      {number, ""} -> number
      _ -> nil
    end
  end

    @doc """
    Converts a string to an integer, ensuring it's non-negative and within the
    acceptable range for database insertion.

    ## Examples

        iex> safe_parse_non_negative_integer("0")
        {:ok, 0}

        iex> safe_parse_non_negative_integer("-1")
        {:error, :negative_integer}

        iex> safe_parse_non_negative_integer("27606393966689717254124294199939478533331961967491413693980084341759630764504")
        {:error, :too_big_integer}
  """
  def safe_parse_non_negative_integer(string) do
    case Integer.parse(string) do
      {num, ""} ->
        case num do
          _ when num > @max_safe_integer -> {:error, :too_big_integer}
          _ when num < 0 -> {:error, :negative_integer}
          _ -> {:ok, num}
        end

      _ ->
        {:error, :invalid_integer}
    end
  end

end
