defmodule Explorer.Utility.ReservedAddresses do
  @moduledoc """
  Module for interacting with the 'reserved_addresses' table.
  This table store the list of reserved addresses defined by the sidechain,
  the native contracts have the column is_contract set to true.
  It has three fields:
    - address_hash (bytea)
    - name (string)
    - is_contract (boolean)
  """

  use Explorer.Schema
  alias Explorer.Repo

  @primary_key {:address_hash, :binary, autogenerate: false}
  schema "reserved_addresses" do
    field(:name, :string)
    field(:is_contract, :boolean)
  end

  @spec get_all_reserved_addresses() :: any()
  def get_all_reserved_addresses do
    Repo.all(__MODULE__)
  end

  @spec get_all_contracts() :: any()
  def get_all_contracts do
    Repo.all(from r in __MODULE__, where: r.is_contract == true)
  end

end
