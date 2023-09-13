defmodule Explorer.Chain.Import.Runner.ForwardTransfersTest do
  use Explorer.DataCase

  alias Ecto.Multi
  alias Explorer.Chain.{ForwardTransfer, Address}
  alias Explorer.Chain.Import.Runner.ForwardTransfers

  describe "run/1" do
    test "forward_transfer" do
      ft = insert(:forward_transfer)

      assert not is_nil(ft.to_address_hash)

      forward_transfer_params = %{
        block_number: 70889,
        to_address_hash: "0x530ec1a4b0e5c939455280c8709447ccf15932b0",
        value: 510_000_000_000_000_000
      }

      assert {:ok, _} = run_transactions([forward_transfer_params])
    end
  end

  defp run_transactions(changes_list) when is_list(changes_list) do
    Multi.new()
    |> ForwardTransfers.run(changes_list, %{
      timeout: :infinity,
      timestamps: %{inserted_at: DateTime.utc_now(), updated_at: DateTime.utc_now()}
    })
    |> Repo.transaction()
  end
end
