defmodule BlockScoutWeb.ReservedAddressesUtils do

  alias Explorer.Utility.ReservedAddresses

  defp match_in_list?(address, list) do
    Enum.member?(list, address)
  end

  def smart_contract_native?(address) do
    all_contracts = ReservedAddresses.get_all_contracts()
    contract_hashes = Enum.map(all_contracts, &(Base.encode16(&1.address_hash)))
    contract_hashes_with_prefix = Enum.map(contract_hashes, fn(element) ->
      "0x" <> element
    end)

    match_in_list?(to_string(address), contract_hashes_with_prefix)
  end
end
