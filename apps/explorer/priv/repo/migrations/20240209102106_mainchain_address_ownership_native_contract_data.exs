defmodule Explorer.Repo.Migrations.MainchainAddressOwnershipNativeContractData do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    execute(
      "DO $$
       BEGIN

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM addresses WHERE hash = E'\\\\x0000000000000000000088888888888888888888') THEN

           -- Insert a new record if it doesn't exist
           INSERT INTO addresses (
            fetched_coin_balance, fetched_coin_balance_block_number,
            hash,
            contract_code,
            inserted_at, updated_at,
            decompiled, verified,
            gas_used, transactions_count, token_transfers_count
           )
           VALUES (
            0, 1,
            E'\\\\x0000000000000000000088888888888888888888',
            '/',
            NOW(), NOW(),
            false, false,
            0, 0, 0
           );
         ELSE

           -- Update the contract_code field if the record exists
           UPDATE public.addresses SET contract_code = '/' WHERE hash = E'\\\\x0000000000000000000088888888888888888888';

         END IF;

       END $$"
    )

    execute("
      INSERT INTO smart_contracts (
        name,
        compiler_version,
        optimization,
        contract_source_code,
        abi,
        address_hash,
        inserted_at,
        updated_at,
        contract_code_md5)
      VALUES (
        'Mainchain Address Ownership',
        'native contract',
        false,
        '/',
        '[{\"inputs\":[],\"name\":\"getAllKeyOwnerships\",\"outputs\":[{\"components\":[{\"internalType\":\"address\",\"name\":\"scAddress\",\"type\":\"address\"},{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"}],\"internalType\":\"struct McAddrOwnership.McAddrOwnershipData[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getKeyOwnerScAddresses\",\"outputs\":[{\"internalType\":\"address[]\",\"name\":\"\",\"type\":\"address[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"scAddress\",\"type\":\"address\"}],\"name\":\"getKeyOwnerships\",\"outputs\":[{\"components\":[{\"internalType\":\"address\",\"name\":\"scAddress\",\"type\":\"address\"},{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"}],\"internalType\":\"struct McAddrOwnership.McAddrOwnershipData[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"}],\"name\":\"removeKeysOwnership\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes24\",\"name\":\"signature1\",\"type\":\"bytes24\"},{\"internalType\":\"bytes32\",\"name\":\"signature2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signature3\",\"type\":\"bytes32\"}],\"name\":\"sendKeysOwnership\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"mcMultisigAddress\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"redeemScript\",\"type\":\"string\"},{\"internalType\":\"string[]\",\"name\":\"mcSignatures\",\"type\":\"string[]\"}],\"name\":\"sendMultisigKeysOwnership\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]',
        E'\\\\x0000000000000000000088888888888888888888',
        NOW(),
        NOW(),
        '6666cd76f96956469e7be39d750cc7d9'
      );")

    execute("INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000088888888888888888888', 'Mainchain Address Ownership', true, NOW(), NOW())")
    execute("INSERT INTO native_contracts (address_hash, name, inserted_at) VALUES (E'\\\\x0000000000000000000088888888888888888888', 'mainchain address ownership', NOW())")

  end

end
