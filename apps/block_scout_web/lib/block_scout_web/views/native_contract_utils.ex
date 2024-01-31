defmodule BlockScoutWeb.NativeContractUtils do

  @contract_addresses [
    "0x0000000000000000000011111111111111111111", # withdrawal request
    "0x0000000000000000000022222222222222222222", # forger stake
    "0x0000000000000000000044444444444444444444", # certificate key rotation
    "0x0000000000000000000088888888888888888888"  # mainchain address ownership (ZEN-DAO)
  ]

  defp match_in_list?(address, list) do
    Enum.member?(list, address)
  end

  def smart_contract_native?(address) do
    match_in_list?(to_string(address), @contract_addresses)
  end
end
