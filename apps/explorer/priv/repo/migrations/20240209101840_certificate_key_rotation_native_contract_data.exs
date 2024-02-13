defmodule Explorer.Repo.Migrations.CertificateKeyRotationNativeContractData do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    execute(
      "DO $$
       BEGIN

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM addresses WHERE hash = E'\\\\x0000000000000000000044444444444444444444') THEN

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
            E'\\\\x0000000000000000000044444444444444444444',
            '/',
            NOW(), NOW(),
            false, false,
            0, 0, 0
           );
         ELSE

           -- Update the contract_code field if the record exists
           UPDATE public.addresses SET contract_code = '/' WHERE hash = E'\\\\x0000000000000000000044444444444444444444';

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
        'Certificate Key Rotation',
        'native contract',
        false,
        '/',
        '[{\"inputs\":[{\"internalType\":\"uint32\",\"name\":\"key_type\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"index\",\"type\":\"uint32\"},{\"internalType\":\"bytes32\",\"name\":\"newKey_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"newKey_2\",\"type\":\"bytes1\"},{\"internalType\":\"bytes32\",\"name\":\"signKeySig_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signKeySig_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"masterKeySig_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"masterKeySig_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"newKeySig_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"newKeySig_2\",\"type\":\"bytes32\"}],\"name\":\"submitKeyRotation\",\"outputs\":[{\"internalType\":\"uint32\",\"name\":\"\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"\",\"type\":\"uint32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"\",\"type\":\"bytes1\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]',
        E'\\\\x0000000000000000000044444444444444444444',
        NOW(),
        NOW(),
        '6666cd76f96956469e7be39d750cc7d9'
      );")

    execute("INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000044444444444444444444', 'Certificate Key Rotation', true, NOW(), NOW())")
    execute("INSERT INTO reserved_addresses(address_hash, name, is_contract, inserted_at) VALUES (E'\\\\x0000000000000000000044444444444444444444', 'certificate key rotation', true, NOW())")

  end

end
