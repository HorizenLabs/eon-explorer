defmodule Explorer.Repo.Migrations.WithdrawalRequestNativeContractData do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    execute(
      "DO $$
       BEGIN

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM addresses WHERE hash = E'\\\\x0000000000000000000011111111111111111111') THEN

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
            E'\\\\x0000000000000000000011111111111111111111',
            '/',
            NOW(), NOW(),
            false, false,
            0, 0, 0
           );

         ELSE

           -- Update the contract_code field if the record exists
           UPDATE public.addresses SET contract_code = '/' WHERE hash = E'\\\\x0000000000000000000011111111111111111111';

         END IF;

       END $$"
    )

    execute(
      "DO $$
       BEGIN

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM smart_contracts WHERE address_hash = E'\\\\x0000000000000000000011111111111111111111') THEN

           -- Insert a new record if it doesn't exist
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
              'Withdrawal Request',
              '-',
              false,
              '/',
              '[{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"bytes20\",\"name\":\"mcDest\",\"type\":\"bytes20\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint32\",\"name\":\"epochNumber\",\"type\":\"uint32\"}],\"name\":\"AddWithdrawalRequest\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"PubKeyHash\",\"name\":\"pubKeyHash\",\"type\":\"bytes20\"}],\"name\":\"backwardTransfer\",\"outputs\":[{\"components\":[{\"internalType\":\"PubKeyHash\",\"name\":\"pubKeyHash\",\"type\":\"bytes20\"},{\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"internalType\":\"struct WithdrawalRequests.WithdrawalRequest\",\"name\":\"\",\"type\":\"tuple\"}],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint32\",\"name\":\"withdrawalEpoch\",\"type\":\"uint32\"}],\"name\":\"getBackwardTransfers\",\"outputs\":[{\"components\":[{\"internalType\":\"PubKeyHash\",\"name\":\"pubKeyHash\",\"type\":\"bytes20\"},{\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"internalType\":\"struct WithdrawalRequests.WithdrawalRequest[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]',
              E'\\\\x0000000000000000000011111111111111111111',
              NOW(),
              NOW(),
              '6666cd76f96956469e7be39d750cc7d9'
            );

         END IF;
       END $$"
    )

    execute(
      "DO $$
       BEGIN

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM address_names WHERE address_hash = E'\\\\x0000000000000000000011111111111111111111') THEN

          INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000011111111111111111111', 'Withdrawal Request', true, NOW(), NOW());

         END IF;
       END $$"
    )

    execute("INSERT INTO reserved_addresses(address_hash, name, is_contract, inserted_at) VALUES (E'\\\\x0000000000000000000011111111111111111111', 'withdrawal request', true, NOW())")

  end

  def down do
    execute("DELETE FROM reserved_addresses WHERE address_hash = E'\\\\x0000000000000000000011111111111111111111';")
    execute("DELETE FROM address_names WHERE address_hash = E'\\\\x0000000000000000000011111111111111111111';")
    execute("DELETE FROM smart_contracts WHERE address_hash = E'\\\\x0000000000000000000011111111111111111111';")
    execute("UPDATE addresses SET contract_code = NULL WHERE hash = E'\\\\x0000000000000000000011111111111111111111';")
  end

end
