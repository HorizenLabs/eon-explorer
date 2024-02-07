defmodule Explorer.Repo.Migrations.WithdrawalRequestNativeContractData do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute(
      "DO $$ \
       BEGIN \

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM addresses WHERE hash = E'\\\\x0000000000000000000011111111111111111111') THEN \

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
            E'\\\\x0000000000000000000011111111111111111111',
            '/',
            NOW(), NOW(),
            false, false,
            0, 0, 0
           ); \
         ELSE \

           -- Update the contract_code field if the record exists
           UPDATE public.addresses SET contract_code = '/' WHERE hash = E'\\\\x0000000000000000000011111111111111111111'; \

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
          'Withdrawal Request',
          'native contract',
          false,
          '/', \
          '[{\"type\":\"function\",\"name\":\"getBackwardTransfers\",\"stateMutability\":\"view\",\"constant\":true,\"payable\":false,\"inputs\":[{\"type\":\"uint32\",\"name\":\"epochNum\"}],\"outputs\":[{\"type\":\"tuple[]\",\"components\":[{\"type\":\"bytes20\",\"name\":\"mcAddress\"},{\"type\":\"uint256\",\"name\":\"amount\"}]}]},{\"type\":\"function\",\"name\":\"‘backwardTransfer’\",\"stateMutability\":\"payable\",\"payable\":true,\"constant\":false,\"inputs\":[{\"type\":\"bytes20\",\"name\":\"mcAddress\"}],\"outputs\":[{\"type\":\"tuple\",\"components\":[{\"type\":\"bytes20\",\"name\":\"mcAddress\"},{\"type\":\"uint256\",\"name\":\"amount\"}]}]},{\"type\":\"event\",\"anonymous\":false,\"name\":\"AddWithdrawalRequest\",\"inputs\":[{\"name\":\"from\",\"type\":\"address\",\"indexed\":true},{\"name\":\"mcDest\",\"type\":\"bytes20\",\"indexed\":true},{\"name\":\"value\",\"type\":\"uint256\",\"indexed\":false},{\"name\":\"epochNumber\",\"type\":\"uint32\",\"indexed\":false}]}]', \
          E'\\\\x0000000000000000000011111111111111111111',
          NOW(),
          NOW(),
          '6666cd76f96956469e7be39d750cc7d9'
         ); \

       END $$"
    )
  end

end
