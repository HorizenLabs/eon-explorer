defmodule BlockScoutWeb.API.V2.VerificationControllerTest do
  use BlockScoutWeb.ConnCase
  use BlockScoutWeb.ChannelCase, async: false

  alias BlockScoutWeb.UserSocketV2
  alias Tesla.Multipart

  require Logger

  @moduletag timeout: :infinity

  describe "/api/v2/smart-contracts/verification/config" do
    test "get cfg", %{conn: conn} do
      request = get(conn, "/api/v2/smart-contracts/verification/config")

      assert response = json_response(request, 200)

      assert is_list(response["solidity_evm_versions"])
      assert is_list(response["solidity_compiler_versions"])
      assert is_list(response["vyper_compiler_versions"])
      assert is_list(response["verification_options"])
      assert is_list(response["vyper_evm_versions"])
      assert response["is_rust_verifier_microservice_enabled"] == false
    end
  end

  describe "/api/v2/smart-contracts/{address_hash}/verification/via/flattened-code" do
    test "get 200 for verified contract", %{conn: conn} do
      contract = insert(:smart_contract)

      params = %{"compiler_version" => "", "source_code" => ""}
      request = post(conn, "/api/v2/smart-contracts/#{contract.address_hash}/verification/via/flattened-code", params)

      assert %{"message" => "Already verified"} = json_response(request, 200)
    end

    test "success verification", %{conn: conn} do
      before = Application.get_env(:explorer, :solc_bin_api_url)

      Application.put_env(:explorer, :solc_bin_api_url, "https://solc-bin.ethereum.org")

      path = File.cwd!() <> "/../explorer/test/support/fixture/smart_contract/solidity_0.5.9_smart_contract.sol"
      contract = File.read!(path)

      constructor_arguments =
        "0000000000000000000000000000000000000000000000000003635c9adc5dea0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000000000000954657374546f6b656e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005546f6b656e000000000000000000000000000000000000000000000000000000"

      bytecode =
        "0x608060405234801561001057600080fd5b50600436106100a95760003560e01c80633177029f116100715780633177029f1461025f57806354fd4d50146102c557806370a082311461034857806395d89b41146103a0578063a9059cbb14610423578063dd62ed3e14610489576100a9565b806306fdde03146100ae578063095ea7b31461013157806318160ddd1461019757806323b872dd146101b5578063313ce5671461023b575b600080fd5b6100b6610501565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156100f65780820151818401526020810190506100db565b50505050905090810190601f1680156101235780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b61017d6004803603604081101561014757600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919050505061059f565b604051808215151515815260200191505060405180910390f35b61019f610691565b6040518082815260200191505060405180910390f35b610221600480360360608110156101cb57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610696565b604051808215151515815260200191505060405180910390f35b61024361090f565b604051808260ff1660ff16815260200191505060405180910390f35b6102ab6004803603604081101561027557600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610922565b604051808215151515815260200191505060405180910390f35b6102cd610a14565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561030d5780820151818401526020810190506102f2565b50505050905090810190601f16801561033a5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b61038a6004803603602081101561035e57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610ab2565b6040518082815260200191505060405180910390f35b6103a8610afa565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156103e85780820151818401526020810190506103cd565b50505050905090810190601f1680156104155780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b61046f6004803603604081101561043957600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610b98565b604051808215151515815260200191505060405180910390f35b6104eb6004803603604081101561049f57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610cfe565b6040518082815260200191505060405180910390f35b60038054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156105975780601f1061056c57610100808354040283529160200191610597565b820191906000526020600020905b81548152906001019060200180831161057a57829003601f168201915b505050505081565b600081600160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040518082815260200191505060405180910390a36001905092915050565b600090565b6000816000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410158015610762575081600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410155b801561076e5750600082115b1561090357816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282540192505081905550816000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254039250508190555081600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825403925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a360019050610908565b600090505b9392505050565b600460009054906101000a900460ff1681565b600081600160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040518082815260200191505060405180910390a36001905092915050565b60068054600181600116156101000203166002900480601f016020809104026020016040519081016040528092919081815260200182805460018160011615610100020316600290048015610aaa5780601f10610a7f57610100808354040283529160200191610aaa565b820191906000526020600020905b815481529060010190602001808311610a8d57829003601f168201915b505050505081565b60008060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b60058054600181600116156101000203166002900480601f016020809104026020016040519081016040528092919081815260200182805460018160011615610100020316600290048015610b905780601f10610b6557610100808354040283529160200191610b90565b820191906000526020600020905b815481529060010190602001808311610b7357829003601f168201915b505050505081565b6000816000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410158015610be85750600082115b15610cf357816000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282540392505081905550816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a360019050610cf8565b600090505b92915050565b6000600160008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205490509291505056fea265627a7a723058202bede3d06720cdf63e8e43fa1d96f228a476cc899ae007bf684e802f2484ce7664736f6c63430005090032"

      input =
        "0x60806040526040518060400160405280600381526020017f302e3100000000000000000000000000000000000000000000000000000000008152506006908051906020019062000051929190620001e2565b503480156200005f57600080fd5b506040516200105b3803806200105b833981810160405260808110156200008557600080fd5b81019080805190602001909291908051640100000000811115620000a857600080fd5b82810190506020810184811115620000bf57600080fd5b8151856001820283011164010000000082111715620000dd57600080fd5b50509291906020018051906020019092919080516401000000008111156200010457600080fd5b828101905060208101848111156200011b57600080fd5b81518560018202830111640100000000821117156200013957600080fd5b5050929190505050836000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002081905550836002819055508260039080519060200190620001a3929190620001e2565b5081600460006101000a81548160ff021916908360ff1602179055508060059080519060200190620001d7929190620001e2565b505050505062000291565b828054600181600116156101000203166002900490600052602060002090601f016020900481019282601f106200022557805160ff191683800117855562000256565b8280016001018555821562000256579182015b828111156200025557825182559160200191906001019062000238565b5b50905062000265919062000269565b5090565b6200028e91905b808211156200028a57600081600090555060010162000270565b5090565b90565b610dba80620002a16000396000f3fe608060405234801561001057600080fd5b50600436106100a95760003560e01c80633177029f116100715780633177029f1461025f57806354fd4d50146102c557806370a082311461034857806395d89b41146103a0578063a9059cbb14610423578063dd62ed3e14610489576100a9565b806306fdde03146100ae578063095ea7b31461013157806318160ddd1461019757806323b872dd146101b5578063313ce5671461023b575b600080fd5b6100b6610501565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156100f65780820151818401526020810190506100db565b50505050905090810190601f1680156101235780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b61017d6004803603604081101561014757600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff1690602001909291908035906020019092919050505061059f565b604051808215151515815260200191505060405180910390f35b61019f610691565b6040518082815260200191505060405180910390f35b610221600480360360608110156101cb57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610696565b604051808215151515815260200191505060405180910390f35b61024361090f565b604051808260ff1660ff16815260200191505060405180910390f35b6102ab6004803603604081101561027557600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610922565b604051808215151515815260200191505060405180910390f35b6102cd610a14565b6040518080602001828103825283818151815260200191508051906020019080838360005b8381101561030d5780820151818401526020810190506102f2565b50505050905090810190601f16801561033a5780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b61038a6004803603602081101561035e57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610ab2565b6040518082815260200191505060405180910390f35b6103a8610afa565b6040518080602001828103825283818151815260200191508051906020019080838360005b838110156103e85780820151818401526020810190506103cd565b50505050905090810190601f1680156104155780820380516001836020036101000a031916815260200191505b509250505060405180910390f35b61046f6004803603604081101561043957600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff16906020019092919080359060200190929190505050610b98565b604051808215151515815260200191505060405180910390f35b6104eb6004803603604081101561049f57600080fd5b81019080803573ffffffffffffffffffffffffffffffffffffffff169060200190929190803573ffffffffffffffffffffffffffffffffffffffff169060200190929190505050610cfe565b6040518082815260200191505060405180910390f35b60038054600181600116156101000203166002900480601f0160208091040260200160405190810160405280929190818152602001828054600181600116156101000203166002900480156105975780601f1061056c57610100808354040283529160200191610597565b820191906000526020600020905b81548152906001019060200180831161057a57829003601f168201915b505050505081565b600081600160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040518082815260200191505060405180910390a36001905092915050565b600090565b6000816000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410158015610762575081600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410155b801561076e5750600082115b1561090357816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282540192505081905550816000808673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000206000828254039250508190555081600160008673ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825403925050819055508273ffffffffffffffffffffffffffffffffffffffff168473ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a360019050610908565b600090505b9392505050565b600460009054906101000a900460ff1681565b600081600160003373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040518082815260200191505060405180910390a36001905092915050565b60068054600181600116156101000203166002900480601f016020809104026020016040519081016040528092919081815260200182805460018160011615610100020316600290048015610aaa5780601f10610a7f57610100808354040283529160200191610aaa565b820191906000526020600020905b815481529060010190602001808311610a8d57829003601f168201915b505050505081565b60008060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020549050919050565b60058054600181600116156101000203166002900480601f016020809104026020016040519081016040528092919081815260200182805460018160011615610100020316600290048015610b905780601f10610b6557610100808354040283529160200191610b90565b820191906000526020600020905b815481529060010190602001808311610b7357829003601f168201915b505050505081565b6000816000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205410158015610be85750600082115b15610cf357816000803373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008282540392505081905550816000808573ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff168152602001908152602001600020600082825401925050819055508273ffffffffffffffffffffffffffffffffffffffff163373ffffffffffffffffffffffffffffffffffffffff167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040518082815260200191505060405180910390a360019050610cf8565b600090505b92915050565b6000600160008473ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff16815260200190815260200160002060008373ffffffffffffffffffffffffffffffffffffffff1673ffffffffffffffffffffffffffffffffffffffff1681526020019081526020016000205490509291505056fea265627a7a723058202bede3d06720cdf63e8e43fa1d96f228a476cc899ae007bf684e802f2484ce7664736f6c63430005090032"

      contract_address = insert(:contract_address, contract_code: bytecode)

      :transaction
      |> insert(
        created_contract_address_hash: contract_address.hash,
        input: input <> constructor_arguments
      )
      |> with_block(status: :ok)

      topic = "addresses:#{contract_address.hash}"

      {:ok, _reply, _socket} =
        BlockScoutWeb.UserSocketV2
        |> socket("no_id", %{})
        |> subscribe_and_join(topic)

      params = %{
        "source_code" => contract,
        "compiler_version" => "v0.5.9+commit.e560f70d",
        "evm_version" => "petersburg",
        "contract_name" => "TestToken",
        "is_optimization_enabled" => false
      }

      request = post(conn, "/api/v2/smart-contracts/#{contract_address.hash}/verification/via/flattened-code", params)

      assert %{"message" => "Verification started"} = json_response(request, 200)

      assert_receive %Phoenix.Socket.Message{
                       payload: %{status: "success"},
                       event: "verification_result",
                       topic: ^topic
                     },
                     :timer.seconds(300)

      Application.put_env(:explorer, :solc_bin_api_url, before)
    end

    test "get error on empty contract name", %{conn: conn} do
      before = Application.get_env(:explorer, :solc_bin_api_url)

      Application.put_env(:explorer, :solc_bin_api_url, "https://solc-bin.ethereum.org")

      contract_address = insert(:contract_address, contract_code: "0x")

      :transaction
      |> insert(
        created_contract_address_hash: contract_address.hash,
        input: "0x"
      )
      |> with_block(status: :ok)

      topic = "addresses:#{contract_address.hash}"

      {:ok, _reply, _socket} =
        BlockScoutWeb.UserSocketV2
        |> socket("no_id", %{})
        |> subscribe_and_join(topic)

      params = %{
        "source_code" => "123",
        "compiler_version" => "v0.5.9+commit.e560f70d",
        "evm_version" => "petersburg",
        "contract_name" => "",
        "is_optimization_enabled" => false
      }

      request = post(conn, "/api/v2/smart-contracts/#{contract_address.hash}/verification/via/flattened-code", params)

      assert %{"message" => "Verification started"} = json_response(request, 200)

      assert_receive %Phoenix.Socket.Message{
                       payload: %{status: "error", errors: %{name: ["Wrong contract name, please try again."]}},
                       event: "verification_result",
                       topic: ^topic
                     },
                     :timer.seconds(2)

      Application.put_env(:explorer, :solc_bin_api_url, before)
    end
  end

  describe "/api/v2/smart-contracts/{address_hash}/verification/via/standard-input" do
    test "get 200 for verified contract", %{conn: conn} do
      contract = insert(:smart_contract)

      params = %{"compiler_version" => "", "files" => ""}
      request = post(conn, "/api/v2/smart-contracts/#{contract.address_hash}/verification/via/standard-input", params)

      assert %{"message" => "Already verified"} = json_response(request, 200)
    end

    test "success verification", %{conn: conn} do
      before = Application.get_env(:explorer, :solc_bin_api_url)

      Application.put_env(:explorer, :solc_bin_api_url, "https://solc-bin.ethereum.org")

      path = File.cwd!() <> "/../explorer/test/support/fixture/smart_contract/standard_input.json"
      json = File.read!(path)

      bytecode =
        "0x608060405234801561001057600080fd5b50600436106100365760003560e01c8063893d20e81461003b578063a6f9dae11461005a575b600080fd5b600054604080516001600160a01b039092168252519081900360200190f35b61006d61006836600461011e565b61006f565b005b6000546001600160a01b031633146100c35760405162461bcd60e51b815260206004820152601360248201527221b0b63632b91034b9903737ba1037bbb732b960691b604482015260640160405180910390fd5b600080546040516001600160a01b03808516939216917f342827c97908e5e2f71151c08502a66d44b6f758e3ac2f1de95f02eb95f0a73591a3600080546001600160a01b0319166001600160a01b0392909216919091179055565b60006020828403121561013057600080fd5b81356001600160a01b038116811461014757600080fd5b939250505056fea26469706673582212206570365ac95ba46c8d0928763befe51fb6fc8a93499f7dabfda28d18ee673a3e64736f6c63430008110033"

      input =
        "0x608060405234801561001057600080fd5b5060405161026438038061026483398101604081905261002f91610076565b600080546001600160a01b0319163390811782556040519091907f342827c97908e5e2f71151c08502a66d44b6f758e3ac2f1de95f02eb95f0a735908290a35050506100d1565b60008060006060848603121561008b57600080fd5b83516001600160701b03811681146100a257600080fd5b60208501519093506001600160a01b03811681146100bf57600080fd5b80925050604084015190509250925092565b610184806100e06000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c8063893d20e81461003b578063a6f9dae11461005a575b600080fd5b600054604080516001600160a01b039092168252519081900360200190f35b61006d61006836600461011e565b61006f565b005b6000546001600160a01b031633146100c35760405162461bcd60e51b815260206004820152601360248201527221b0b63632b91034b9903737ba1037bbb732b960691b604482015260640160405180910390fd5b600080546040516001600160a01b03808516939216917f342827c97908e5e2f71151c08502a66d44b6f758e3ac2f1de95f02eb95f0a73591a3600080546001600160a01b0319166001600160a01b0392909216919091179055565b60006020828403121561013057600080fd5b81356001600160a01b038116811461014757600080fd5b939250505056fea26469706673582212206570365ac95ba46c8d0928763befe51fb6fc8a93499f7dabfda28d18ee673a3e64736f6c6343000811003300000000000000000000000000000000000000000000000000000002d2982db3000000000000000000000000bb36c792b9b45aaf8b848a1392b0d6559202729e666f6f0000000000000000000000000000000000000000000000000000000000"

      contract_address = insert(:contract_address, contract_code: bytecode)

      :transaction
      |> insert(
        created_contract_address_hash: contract_address.hash,
        input: input
      )
      |> with_block(status: :ok)

      topic = "addresses:#{contract_address.hash}"

      {:ok, _reply, _socket} =
        BlockScoutWeb.UserSocketV2
        |> socket("no_id", %{})
        |> subscribe_and_join(topic)

      multipart =
        Multipart.new()
        |> Multipart.add_field("compiler_version", "v0.8.17+commit.8df45f5f")
        |> Multipart.add_file_content(json, "name.json",
          name: "files[0]",
          headers: [{"content-type", "application/json"}]
        )

      body =
        multipart
        |> Multipart.body()
        |> Enum.to_list()
        |> to_str()

      [{name, value}] = Multipart.headers(multipart)

      request =
        post(
          conn
          |> Plug.Conn.put_req_header(
            name,
            value
          ),
          "/api/v2/smart-contracts/#{contract_address.hash}/verification/via/standard-input",
          body
        )

      assert %{"message" => "Verification started"} = json_response(request, 200)

      assert_receive %Phoenix.Socket.Message{
                       payload: %{status: "success"},
                       event: "verification_result",
                       topic: ^topic
                     },
                     :timer.seconds(300)

      Application.put_env(:explorer, :solc_bin_api_url, before)
    end
  end

  describe "/api/v2/smart-contracts/{address_hash}/verification/via/sourcify" do
    @tag :skip
    test "get 200 for verified contract", %{conn: conn} do
      contract = insert(:smart_contract)

      params = %{"files" => ""}
      request = post(conn, "/api/v2/smart-contracts/#{contract.address_hash}/verification/via/sourcify", params)

      assert %{"message" => "Already verified"} = json_response(request, 200)
    end

    @tag :skip
    test "verify contract from sourcify repo", %{conn: conn} do
      address = "0x18d89C12e9463Be6343c35C9990361bA4C42AfC2"

      _contract = insert(:address, hash: address, contract_code: "0x01")

      topic = "addresses:#{String.downcase(address)}"

      {:ok, _reply, _socket} =
        UserSocketV2
        |> socket("no_id", %{})
        |> subscribe_and_join(topic)

      multipart =
        Multipart.new()
        |> Multipart.add_file_content("content", "name.json",
          name: "files[0]",
          headers: [{"content-type", "application/json"}]
        )

      body =
        multipart
        |> Multipart.body()
        |> Enum.to_list()
        |> to_str()

      [{name, value}] = Multipart.headers(multipart)

      request =
        post(
          conn
          |> Plug.Conn.put_req_header(
            name,
            value
          ),
          "/api/v2/smart-contracts/#{address}/verification/via/sourcify",
          body
        )

      assert %{"message" => "Verification started"} = json_response(request, 200)

      assert_receive %Phoenix.Socket.Message{
                       payload: %{status: "success"},
                       event: "verification_result",
                       topic: ^topic
                     },
                     :timer.seconds(120)
    end
  end

  describe "/api/v2/smart-contracts/{address_hash}/verification/via/multi-part" do
    test "get 404", %{conn: conn} do
      contract = insert(:smart_contract)

      params = %{"compiler_version" => "", "files" => ""}
      request = post(conn, "/api/v2/smart-contracts/#{contract.address_hash}/verification/via/multi-part", params)

      assert %{"message" => "Not found"} = json_response(request, 404)
    end
  end

  describe "/api/v2/smart-contracts/{address_hash}/verification/via/vyper-code" do
    test "get 200 for verified contract", %{conn: conn} do
      contract = insert(:smart_contract)

      params = %{"compiler_version" => "", "source_code" => ""}
      request = post(conn, "/api/v2/smart-contracts/#{contract.address_hash}/verification/via/vyper-code", params)

      assert %{"message" => "Already verified"} = json_response(request, 200)
    end

    test "success verification", %{conn: conn} do
      before = Application.get_env(:explorer, :solc_bin_api_url)

      Application.put_env(:explorer, :solc_bin_api_url, "https://solc-bin.ethereum.org")

      path = File.cwd!() <> "/../explorer/test/support/fixture/smart_contract/vyper.vy"
      contract = File.read!(path)

      bytecode =
        "0x600436101561000d57610572565b600035601c52600051341561002157600080fd5b63a9059cbb8114156100785760043560a01c1561003d57600080fd5b3361014052600435610160526024356101805261018051610160516101405160065801610578565b6101e0526101e050600160005260206000f35b6323b872dd8114156101195760043560a01c1561009457600080fd5b60243560a01c156100a457600080fd5b60043561014052602435610160526044356101805261018051610160516101405160065801610578565b6101e0526101e050600460043560e05260c052604060c0203360e05260c052604060c02080546044358082101561010457600080fd5b80820390509050815550600160005260206000f35b63095ea7b381141561020a5760043560a01c1561013557600080fd5b600854602435111515156101ad576308c379a061014052602061016052603a610180527f43616e7420417070726f7665206d6f7265207468616e20312528313030204d696101a0527f6c6c696f6e2920546f6b656e7320666f72207472616e736665720000000000006101c05261018050608461015cfd5b60243560043360e05260c052604060c02060043560e05260c052604060c0205560243561014052600435337f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9256020610140a3600160005260206000f35b6340c10f198114156102c65760043560a01c1561022657600080fd5b600654331461023457600080fd5b60006004351861024357600080fd5b6005805460243581818301101561025957600080fd5b80820190509050815550600360043560e05260c052604060c020805460243581818301101561028757600080fd5b808201905090508155506024356101405260043560007fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef6020610140a3005b6342966c688114156102f45733610140526004356101605261016051610140516006580161074d565b600050005b6379cc679081141561036c5760043560a01c1561031057600080fd5b600460043560e05260c052604060c0203360e05260c052604060c02080546024358082101561033e57600080fd5b80820390509050815550600435610140526024356101605261016051610140516006580161074d565b600050005b6306fdde038114156104115760008060c052602060c020610180602082540161012060006003818352015b826101205160200211156103aa576103cc565b61012051850154610120516020028501525b8151600101808352811415610397575b50505050505061018051806101a001818260206001820306601f82010390500336823750506020610160526040610180510160206001820306601f8201039050610160f35b6395d89b418114156104b65760018060c052602060c020610180602082540161012060006002818352015b8261012051602002111561044f57610471565b61012051850154610120516020028501525b815160010180835281141561043c575b50505050505061018051806101a001818260206001820306601f82010390500336823750506020610160526040610180510160206001820306601f8201039050610160f35b63313ce5678114156104ce5760025460005260206000f35b6370a082318114156105045760043560a01c156104ea57600080fd5b600360043560e05260c052604060c0205460005260206000f35b63dd62ed3e8114156105585760043560a01c1561052057600080fd5b60243560a01c1561053057600080fd5b600460043560e05260c052604060c02060243560e05260c052604060c0205460005260206000f35b6318160ddd8114156105705760055460005260206000f35b505b60006000fd5b6101a0526101405261016052610180526008546101805111151515610601576308c379a06101c05260206101e0526028610200527f5472616e73666572206c696d6974206f6620312528313030204d696c6c696f6e610220527f2920546f6b656e73000000000000000000000000000000000000000000000000610240526102005060846101dcfd5b60036101605160e05260c052604060c020546101805181818301101561062657600080fd5b808201905090506101c0526008546101c051111515156106aa576308c379a06101e052602061020052603a610220527f53696e676c652077616c6c65742063616e6e6f7420686f6c64206d6f72652074610240527f68616e20312528313030204d696c6c696f6e2920546f6b656e73000000000000610260526102205060846101fcfd5b60036101405160e05260c052604060c020805461018051808210156106ce57600080fd5b8082039050905081555060036101605160e05260c052604060c0208054610180518181830110156106fe57600080fd5b80820190509050815550610180516101e05261016051610140517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60206101e0a360016000526000516101a051565b6101805261014052610160526000610140511861076957600080fd5b60058054610160518082101561077e57600080fd5b8082039050905081555060036101405160e05260c052604060c020805461016051808210156107ac57600080fd5b80820390509050815550610160516101a0526000610140517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60206101a0a36101805156"

      input =
        "0x6402540be4006007556305f5e10060085560126002556006610140527f4b6f6f6f706100000000000000000000000000000000000000000000000000006101605261014080600060c052602060c020602082510161012060006002818352015b8261012051602002111561007257610094565b61012051602002850151610120518501555b815160010180835281141561005f575b5050505050506003610140527f4b4f4f00000000000000000000000000000000000000000000000000000000006101605261014080600160c052602060c020602082510161012060006002818352015b826101205160200211156100f757610119565b61012051602002850151610120518501555b81516001018083528114156100e4575b505050505050600754604e6002541061013157600080fd5b600254600a0a808202821582848304141761014b57600080fd5b80905090509050610140526101405160033360e05260c052604060c02055610140516005553360065561014051610160523360007fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef6020610160a361099c56600436101561000d57610572565b600035601c52600051341561002157600080fd5b63a9059cbb8114156100785760043560a01c1561003d57600080fd5b3361014052600435610160526024356101805261018051610160516101405160065801610578565b6101e0526101e050600160005260206000f35b6323b872dd8114156101195760043560a01c1561009457600080fd5b60243560a01c156100a457600080fd5b60043561014052602435610160526044356101805261018051610160516101405160065801610578565b6101e0526101e050600460043560e05260c052604060c0203360e05260c052604060c02080546044358082101561010457600080fd5b80820390509050815550600160005260206000f35b63095ea7b381141561020a5760043560a01c1561013557600080fd5b600854602435111515156101ad576308c379a061014052602061016052603a610180527f43616e7420417070726f7665206d6f7265207468616e20312528313030204d696101a0527f6c6c696f6e2920546f6b656e7320666f72207472616e736665720000000000006101c05261018050608461015cfd5b60243560043360e05260c052604060c02060043560e05260c052604060c0205560243561014052600435337f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9256020610140a3600160005260206000f35b6340c10f198114156102c65760043560a01c1561022657600080fd5b600654331461023457600080fd5b60006004351861024357600080fd5b6005805460243581818301101561025957600080fd5b80820190509050815550600360043560e05260c052604060c020805460243581818301101561028757600080fd5b808201905090508155506024356101405260043560007fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef6020610140a3005b6342966c688114156102f45733610140526004356101605261016051610140516006580161074d565b600050005b6379cc679081141561036c5760043560a01c1561031057600080fd5b600460043560e05260c052604060c0203360e05260c052604060c02080546024358082101561033e57600080fd5b80820390509050815550600435610140526024356101605261016051610140516006580161074d565b600050005b6306fdde038114156104115760008060c052602060c020610180602082540161012060006003818352015b826101205160200211156103aa576103cc565b61012051850154610120516020028501525b8151600101808352811415610397575b50505050505061018051806101a001818260206001820306601f82010390500336823750506020610160526040610180510160206001820306601f8201039050610160f35b6395d89b418114156104b65760018060c052602060c020610180602082540161012060006002818352015b8261012051602002111561044f57610471565b61012051850154610120516020028501525b815160010180835281141561043c575b50505050505061018051806101a001818260206001820306601f82010390500336823750506020610160526040610180510160206001820306601f8201039050610160f35b63313ce5678114156104ce5760025460005260206000f35b6370a082318114156105045760043560a01c156104ea57600080fd5b600360043560e05260c052604060c0205460005260206000f35b63dd62ed3e8114156105585760043560a01c1561052057600080fd5b60243560a01c1561053057600080fd5b600460043560e05260c052604060c02060243560e05260c052604060c0205460005260206000f35b6318160ddd8114156105705760055460005260206000f35b505b60006000fd5b6101a0526101405261016052610180526008546101805111151515610601576308c379a06101c05260206101e0526028610200527f5472616e73666572206c696d6974206f6620312528313030204d696c6c696f6e610220527f2920546f6b656e73000000000000000000000000000000000000000000000000610240526102005060846101dcfd5b60036101605160e05260c052604060c020546101805181818301101561062657600080fd5b808201905090506101c0526008546101c051111515156106aa576308c379a06101e052602061020052603a610220527f53696e676c652077616c6c65742063616e6e6f7420686f6c64206d6f72652074610240527f68616e20312528313030204d696c6c696f6e2920546f6b656e73000000000000610260526102205060846101fcfd5b60036101405160e05260c052604060c020805461018051808210156106ce57600080fd5b8082039050905081555060036101605160e05260c052604060c0208054610180518181830110156106fe57600080fd5b80820190509050815550610180516101e05261016051610140517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60206101e0a360016000526000516101a051565b6101805261014052610160526000610140511861076957600080fd5b60058054610160518082101561077e57600080fd5b8082039050905081555060036101405160e05260c052604060c020805461016051808210156107ac57600080fd5b80820390509050815550610160516101a0526000610140517fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef60206101a0a361018051565b6101ab61099c036101ab6000396101ab61099c036000f3"

      contract_address = insert(:contract_address, contract_code: bytecode)

      :transaction
      |> insert(
        created_contract_address_hash: contract_address.hash,
        input: input
      )
      |> with_block(status: :ok)

      topic = "addresses:#{contract_address.hash}"

      {:ok, _reply, _socket} =
        BlockScoutWeb.UserSocketV2
        |> socket("no_id", %{})
        |> subscribe_and_join(topic)

      params = %{
        "source_code" => contract,
        "compiler_version" => "v0.2.12",
        "contract_name" => "abc"
      }

      request = post(conn, "/api/v2/smart-contracts/#{contract_address.hash}/verification/via/vyper-code", params)

      assert %{"message" => "Verification started"} = json_response(request, 200)

      assert_receive %Phoenix.Socket.Message{
                       payload: %{status: "success"},
                       event: "verification_result",
                       topic: ^topic
                     },
                     :timer.seconds(300)

      Application.put_env(:explorer, :solc_bin_api_url, before)
    end
  end

  describe "/api/v2/smart-contracts/{address_hash}/verification/via/vyper-multi-part" do
    test "get 404", %{conn: conn} do
      contract = insert(:smart_contract)

      params = %{"compiler_version" => "", "files" => ""}
      request = post(conn, "/api/v2/smart-contracts/#{contract.address_hash}/verification/via/vyper-multi-part", params)

      assert %{"message" => "Not found"} = json_response(request, 404)
    end
  end

  defp to_str(list) when is_list(list) do
    Enum.reduce(list, "", fn x, acc -> acc <> to_str(x) end)
  end

  defp to_str(str) when is_binary(str) do
    str
  end
end
