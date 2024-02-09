defmodule Explorer.Utility.NativeContracts do
  @moduledoc """
  Module for interacting with the 'native_contracts' table.
  This table store the list of native smart contract defined by the sidechain,
  it has two fields with datatype : address_hash and name
  """

  use Explorer.Schema
  alias Explorer.Repo

  @primary_key {:address_hash, :binary, autogenerate: false}
  schema "native_contracts" do
    field(:name, :string)
  end

  @spec get_all_contracts() :: any()
  def get_all_contracts do
    Repo.all(__MODULE__)
  end

end
