defmodule BlockScoutWeb.NativeContractUtils do

  alias Explorer.Utility.NativeContracts
  require Logger

  defp match_in_list?(address, list) do
    Enum.member?(list, address)
  end

  def smart_contract_native?(address) do
    all_contracts = NativeContracts.get_all_contracts()
    contract_hashes = Enum.map(all_contracts, &(&1.hash))
    match_in_list?(to_string(address), contract_hashes)
  end
end
