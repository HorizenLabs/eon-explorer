defmodule Explorer.Repo.Migrations.ForgerStakeNativeContractData do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute(
      "DO $$ \
       BEGIN \

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM addresses WHERE hash = E'\\\\x0000000000000000000022222222222222222222') THEN \

           -- Insert a new record if it doesn't exist
           INSERT INTO addresses (
            fetched_coin_balance, fetched_coin_balance_block_number,
            hash,
            contract_code,
            inserted_at, updated_at,
            decompiled, verified,
            gas_used, transactions_count, token_transfers_count
           ) \
           VALUES (
            0, 1,
            E'\\\\x0000000000000000000022222222222222222222',
            '/',
            NOW(), NOW(),
            false, false,
            0, 0, 0
           ); \
         ELSE \

           -- Update the contract_code field if the record exists
           UPDATE public.addresses SET contract_code = '/' WHERE hash = E'\\\\x0000000000000000000022222222222222222222'; \

         END IF; \

         INSERT INTO smart_contracts (
          name,
          compiler_version,
          optimization,
          contract_source_code,
          abi,
          address_hash,
          inserted_at,
          updated_at,
          contract_code_md5) \
         VALUES (
          'Forger Stake',
          'native contract',
          false,
          '/', \
          '[{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"publicKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"delegate\",\"outputs\":[{\"internalType\":\"StakeID\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAllForgersStakes\",\"outputs\":[{\"components\":[{\"internalType\":\"StakeID\",\"name\":\"stakeId\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"stakedAmount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"publicKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"}],\"internalType\":\"struct ForgerStakes.StakeInfo[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint32\",\"name\":\"forgerIndex\",\"type\":\"uint32\"},{\"internalType\":\"bytes32\",\"name\":\"signature1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signature2\",\"type\":\"bytes32\"}],\"name\":\"openStakeForgerList\",\"outputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"StakeID\",\"name\":\"stakeId\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"signatureV\",\"type\":\"bytes1\"},{\"internalType\":\"bytes32\",\"name\":\"signatureR\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signatureS\",\"type\":\"bytes32\"}],\"name\":\"withdraw\",\"outputs\":[{\"internalType\":\"StakeID\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]', \
          E'\\\\x0000000000000000000022222222222222222222',
          NOW(),
          NOW(),
          '6666cd76f96956469e7be39d750cc7d9'
         ); \

       END $$"
    )
  end

end
