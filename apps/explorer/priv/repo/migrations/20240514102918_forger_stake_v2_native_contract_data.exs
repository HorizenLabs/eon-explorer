defmodule Explorer.Repo.Migrations.ForgerStakeV2NativeContractData do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true
  def up do
    execute(
      "DO $$
       BEGIN

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM addresses WHERE hash = E'\\\\x0000000000000000000022222222222222222333') THEN \

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
            E'\\\\x0000000000000000000022222222222222222333',
            '/',
            NOW(), NOW(),
            false, false,
            0, 0, 0
           );

         ELSE

           -- Update the contract_code field if the record exists
           UPDATE public.addresses SET contract_code = '/' WHERE hash = E'\\\\x0000000000000000000022222222222222222333'; \

         END IF;

       END $$"
    )

    execute(
      "DO $$
       BEGIN

         -- Check if the record with the specified hash exists
         IF NOT EXISTS (SELECT 1 FROM smart_contracts WHERE address_hash = E'\\\\x0000000000000000000022222222222222222333') THEN

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
              'Forger Stake V2',
              '-',
              false,
              '/',
              '[{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"name\":\"DelegateForgerStake\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint32\",\"name\":\"rewardShare\",\"type\":\"uint32\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"reward_address\",\"type\":\"address\"}],\"name\":\"RegisterForger\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"indexed\":false,\"internalType\":\"uint32\",\"name\":\"rewardShare\",\"type\":\"uint32\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"reward_address\",\"type\":\"address\"}],\"name\":\"UpdateForger\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"indexed\":true,\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"name\":\"WithdrawForgerStake\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"}],\"name\":\"delegate\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getCurrentConsensusEpoch\",\"outputs\":[{\"internalType\":\"uint32\",\"name\":\"epoch\",\"type\":\"uint32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"}],\"name\":\"getForger\",\"outputs\":[{\"components\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"uint32\",\"name\":\"rewardShare\",\"type\":\"uint32\"},{\"internalType\":\"address\",\"name\":\"reward_address\",\"type\":\"address\"}],\"internalType\":\"struct ForgerStakesV2.ForgerInfo\",\"name\":\"forgerInfo\",\"type\":\"tuple\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"int32\",\"name\":\"startIndex\",\"type\":\"int32\"},{\"internalType\":\"int32\",\"name\":\"pageSize\",\"type\":\"int32\"}],\"name\":\"getPagedForgers\",\"outputs\":[{\"internalType\":\"int32\",\"name\":\"nextIndex\",\"type\":\"int32\"},{\"components\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"uint32\",\"name\":\"rewardShare\",\"type\":\"uint32\"},{\"internalType\":\"address\",\"name\":\"reward_address\",\"type\":\"address\"}],\"internalType\":\"struct ForgerStakesV2.ForgerInfo[]\",\"name\":\"listOfForgerInfo\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"delegator\",\"type\":\"address\"},{\"internalType\":\"int32\",\"name\":\"startIndex\",\"type\":\"int32\"},{\"internalType\":\"int32\",\"name\":\"pageSize\",\"type\":\"int32\"}],\"name\":\"getPagedForgersStakesByDelegator\",\"outputs\":[{\"internalType\":\"int32\",\"name\":\"nextIndex\",\"type\":\"int32\"},{\"components\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"uint256\",\"name\":\"stakedAmount\",\"type\":\"uint256\"}],\"internalType\":\"struct ForgerStakesV2.StakeDataForger[]\",\"name\":\"listOfForgerStakes\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"int32\",\"name\":\"startIndex\",\"type\":\"int32\"},{\"internalType\":\"int32\",\"name\":\"pageSize\",\"type\":\"int32\"}],\"name\":\"getPagedForgersStakesByForger\",\"outputs\":[{\"internalType\":\"int32\",\"name\":\"nextIndex\",\"type\":\"int32\"},{\"components\":[{\"internalType\":\"address\",\"name\":\"delegator\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"stakedAmount\",\"type\":\"uint256\"}],\"internalType\":\"struct ForgerStakesV2.StakeDataDelegator[]\",\"name\":\"listOfDelegatorStakes\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrfKey1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrfKey2\",\"type\":\"bytes1\"},{\"internalType\":\"uint32\",\"name\":\"rewardShare\",\"type\":\"uint32\"},{\"internalType\":\"address\",\"name\":\"rewardAddress\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"sign1_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign1_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign2_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign2_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign2_3\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"sign2_4\",\"type\":\"bytes1\"}],\"name\":\"registerForger\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"uint32\",\"name\":\"consensusEpochStart\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"maxNumOfEpoch\",\"type\":\"uint32\"}],\"name\":\"rewardsReceived\",\"outputs\":[{\"internalType\":\"uint256[]\",\"name\":\"listOfRewards\",\"type\":\"uint256[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"address\",\"name\":\"delegator\",\"type\":\"address\"}],\"name\":\"stakeStart\",\"outputs\":[{\"internalType\":\"int32\",\"name\":\"consensusEpochStart\",\"type\":\"int32\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"address\",\"name\":\"delegator\",\"type\":\"address\"},{\"internalType\":\"uint32\",\"name\":\"consensusEpochStart\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"maxNumOfEpoch\",\"type\":\"uint32\"}],\"name\":\"stakeTotal\",\"outputs\":[{\"internalType\":\"uint256[]\",\"name\":\"listOfStakes\",\"type\":\"uint256[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"uint32\",\"name\":\"rewardShare\",\"type\":\"uint32\"},{\"internalType\":\"address\",\"name\":\"rewardAddress\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"sign1_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign1_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign2_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign2_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"sign2_3\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"sign2_4\",\"type\":\"bytes1\"}],\"name\":\"updateForger\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"signPubKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"}],\"name\":\"withdraw\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]',
              E'\\\\x0000000000000000000022222222222222222333',
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
         IF NOT EXISTS (SELECT 1 FROM address_names WHERE address_hash = E'\\\\x0000000000000000000022222222222222222333') THEN

          INSERT INTO address_names(address_hash, name, \"primary\", inserted_at, updated_at) VALUES (E'\\\\x0000000000000000000022222222222222222333', 'Forger Stake V2', true, NOW(), NOW());

         END IF;
       END $$"
    )

    execute("INSERT INTO reserved_addresses(address_hash, name, is_contract, inserted_at) VALUES (E'\\\\x0000000000000000000022222222222222222333', 'forger stake v2', true, NOW())")

  end

  def down do
    execute("DELETE FROM reserved_addresses WHERE address_hash = E'\\\\x0000000000000000000022222222222222222333';")
    execute("DELETE FROM address_names WHERE address_hash = E'\\\\x0000000000000000000022222222222222222333';")
    execute("DELETE FROM smart_contracts WHERE address_hash = E'\\\\x0000000000000000000022222222222222222333';")
    execute("UPDATE addresses SET contract_code = NULL WHERE hash = E'\\\\x0000000000000000000022222222222222222333';")
  end

end
