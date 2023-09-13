defmodule Indexer.Fetcher.FeePaymentAsyncTest do
  use EthereumJSONRPC.Case, async: false
  use Explorer.DataCase

  import EthereumJSONRPC, only: [integer_to_quantity: 1]

  import Mox

  alias Explorer.Chain
  alias Explorer.Chain.{FeePayment, Wei, LastFetchedCounter}
  alias Indexer.Fetcher.FeePaymentAsync, as: FeePayment

  @moduletag :capture_log

  # MUST use global mode because we aren't guaranteed to get `start_supervised`'s pid back fast enough to `allow` it to
  # use expectations and stubs from test's pid.
  setup :set_mox_global

  setup :verify_on_exit!

  setup do
    start_supervised!({Task.Supervisor, name: Indexer.TaskSupervisor})
    :ok
  end

  describe "async_fetch/1" do
    test "fetch fee_payments for missing block numbers", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      value_string_1 = "0x713e24c43730000"
      value_string_2 = "0x713e24c43730001"
      address_1 = "0x5302c1375912f56a78e15802f30c693c4eae80b5"
      address_2 = "0x6302c1375912f56a78e15802f30c693c4eae80b6"
      block_number_1 = 1
      block_number_2 = 2
      block_quantity_1 = integer_to_quantity(block_number_1)
      block_quantity_2 = integer_to_quantity(block_number_2)
      insert(:block, number: block_number_1)
      insert(:block, number: block_number_2)

      if json_rpc_named_arguments[:transport] == EthereumJSONRPC.Mox do
        EthereumJSONRPC.Mox
        |> expect(:json_rpc, fn [%{id: _id, method: "zen_getFeePayments", params: [^block_quantity_1]}], _options ->
          {:ok,
           [
             %{
               id: 0,
               result: %{
                 "payments" => [
                   %{
                     "address" => address_1,
                     "value" => value_string_1
                   }
                 ]
               }
             }
           ]}
        end)

        EthereumJSONRPC.Mox
        |> expect(:json_rpc, fn [%{id: _id, method: "zen_getFeePayments", params: [^block_quantity_2]}], _options ->
          {:ok,
           [
             %{
               id: 0,
               result: %{
                 "payments" => [
                   %{
                     "address" => address_2,
                     "value" => value_string_2
                   }
                 ]
               }
             }
           ]}
        end)
      end

      FeePayment.Supervisor.Case.start_supervised!(json_rpc_named_arguments: json_rpc_named_arguments)

      fp =
        wait(fn ->
          Repo.one!(from(fee_payment in Explorer.Chain.FeePayment, where: fee_payment.block_number == ^block_number_1))
        end)

      assert fp.to_address_hash == address_1
      assert fp.value == tuple_to_final(Wei.cast(value_string_1))
      assert fp.index == 0

      another_fp =
        wait(fn ->
          Repo.one!(from(fee_payment in Explorer.Chain.FeePayment, where: fee_payment.block_number == ^block_number_2))
        end)

      assert another_fp.to_address_hash == address_2
      assert another_fp.value == tuple_to_final(Wei.cast(value_string_2))
      et_type = Enum.at(LastFetchedCounter.last_fetched_counter_types(), 0)
      assert Chain.get_last_fetched_counter(et_type) == Decimal.new(2)
    end
  end

  describe "run/2" do
    test "simple run/2", %{
      json_rpc_named_arguments: json_rpc_named_arguments
    } do
      value_string_1 = "0x713e24c43730000"
      address = "0x5302c1375912f56a78e15802f30c693c4eae80b5"
      block_number = 1
      block_quantity = integer_to_quantity(block_number)


      if json_rpc_named_arguments[:transport] == EthereumJSONRPC.Mox do
        EthereumJSONRPC.Mox
        |> expect(:json_rpc, fn [%{id: _id, method: "zen_getFeePayments", params: [^block_quantity]}], _options ->
          {:ok,
           [
             %{
               id: 0,
               result: %{
                 "payments" => [
                   %{
                     "address" => address,
                     "value" => value_string_1
                   },
                   %{
                     "address" => address,
                     "value" => value_string_1
                   }
                 ]
               }
             }
           ]}
        end)
      end

      assert FeePayment.run([1], json_rpc_named_arguments) == :ok
       fp =
        wait(fn ->
          Repo.one!(from(fee_payment in Explorer.Chain.FeePayment, where: fee_payment.block_number == ^block_number))
        end)

      assert fp.to_address_hash == address
      assert fp.value == tuple_to_final(Wei.cast(value_string_1))
      assert fp.index == 0
    end
  end

  defp wait(producer) do
    producer.()
  rescue
    Ecto.NoResultsError ->
      Process.sleep(100)
      wait(producer)
  end

  defp tuple_to_final(tuple) do
    {:ok, final} = tuple
    final
  end
end
