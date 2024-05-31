defmodule BlockScoutWeb.API.RPC.ContractControllerTest do
  use BlockScoutWeb.ConnCase
  alias Explorer.Chain.SmartContract
  alias Explorer.Chain
  # alias Explorer.{Chain, Factory}

  import Mox

  def prepare_contracts do
    insert(:contract_address)
    {:ok, dt_1, _} = DateTime.from_iso8601("2022-09-20 10:00:00Z")

    contract_1 =
      insert(:smart_contract,
        contract_code_md5: "123",
        name: "Test 1",
        optimization: "1",
        compiler_version: "v0.6.8+commit.0bbfe453",
        abi: [%{foo: "bar"}],
        inserted_at: dt_1
      )

    insert(:contract_address)
    {:ok, dt_2, _} = DateTime.from_iso8601("2022-09-22 10:00:00Z")

    contract_2 =
      insert(:smart_contract,
        contract_code_md5: "12345",
        name: "Test 2",
        optimization: "0",
        compiler_version: "v0.7.5+commit.eb77ed08",
        abi: [%{foo: "bar-2"}],
        inserted_at: dt_2
      )

    insert(:contract_address)
    {:ok, dt_3, _} = DateTime.from_iso8601("2022-09-24 10:00:00Z")

    contract_3 =
      insert(:smart_contract,
        contract_code_md5: "1234567",
        name: "Test 3",
        optimization: "1",
        compiler_version: "v0.4.26+commit.4563c3fc",
        abi: [%{foo: "bar-3"}],
        inserted_at: dt_3
      )

    [contract_1, contract_2, contract_3]
  end

  def result(contract) do
    %{
      "ABI" => Jason.encode!(contract.abi),
      "Address" => to_string(contract.address_hash),
      "CompilerVersion" => contract.compiler_version,
      "ContractName" => contract.name,
      "OptimizationUsed" => if(contract.optimization, do: "1", else: "0")
    }
  end

  defp result_not_verified(address_hash) do
    %{
      "ABI" => "Contract source code not verified",
      "Address" => to_string(address_hash)
    }
  end

  describe "listcontracts" do
    setup do
      %{params: %{"module" => "contract", "action" => "listcontracts"}}
    end

    test "with an invalid filter value", %{conn: conn, params: params} do
      response =
        conn
        |> get("/api", Map.put(params, "filter", "invalid"))
        |> json_response(400)

      assert response["message"] ==
               "invalid is not a valid value for `filter`. Please use one of: verified, decompiled, unverified, not_decompiled, 1, 2, 3, 4."

      assert response["status"] == "0"
      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "with only precompiled (native) contracts", %{conn: conn, params: params} do
      response =
        conn
        |> get("/api", params)
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"
      verify_native_contracts(response["result"])
      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "with a verified smart contract, all contract information is shown", %{conn: conn, params: params} do
      contract = insert(:smart_contract, contract_code_md5: "123")

      response =
        conn
        |> get("/api", params)
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response = find_element_by_address(response["result"], to_string(contract.address_hash))
      assert contract_from_response == result(contract)

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "with an unverified contract address, only basic information is shown", %{conn: conn, params: params} do
      address = insert(:contract_address)

      response =
        conn
        |> get("/api", params)
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response = find_element_by_address(response["result"], to_string(address.hash))
      assert contract_from_response == result_not_verified(address.hash)

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only unverified contracts shows only unverified contracts", %{params: params, conn: conn} do
      address = insert(:contract_address)
      insert(:smart_contract, contract_code_md5: "123")

      response =
        conn
        |> get("/api", Map.put(params, "filter", "unverified"))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response = find_element_by_address(response["result"], to_string(address.hash))
      assert contract_from_response == result_not_verified(address.hash)

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only unverified contracts does not show self destructed contracts", %{
      params: params,
      conn: conn
    } do
      address = insert(:contract_address)
      insert(:smart_contract, contract_code_md5: "123")
      insert(:contract_address, contract_code: "0x")

      response =
        conn
        |> get("/api", Map.put(params, "filter", "unverified"))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response = find_element_by_address(response["result"], to_string(address.hash))
      assert contract_from_response == result_not_verified(address.hash)

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only verified contracts shows only verified contracts", %{params: params, conn: conn} do
      insert(:contract_address)
      contract = insert(:smart_contract, contract_code_md5: "123")

      response =
        conn
        |> get("/api", Map.put(params, "filter", "verified"))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response = find_element_by_address(response["result"], to_string(contract.address_hash))
      assert contract_from_response == result(contract)

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only verified contracts in the date range shows only verified contracts in that range", %{
      params: params,
      conn: conn
    } do
      [_contract_1, contract_2, _contract_3] = prepare_contracts()

      filter_params =
        params
        |> Map.put("filter", "verified")
        |> Map.put("verified_at_start_timestamp", "1663749418")
        |> Map.put("verified_at_end_timestamp", "1663922218")

      response =
        conn
        |> get("/api", filter_params)
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      assert response["result"] == [result(contract_2)]

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only verified contracts with start created_at timestamp >= given timestamp shows only verified contracts in that range",
         %{
           params: params,
           conn: conn
         } do
      [_contract_1, contract_2, contract_3] = prepare_contracts()

      filter_params =
        params
        |> Map.put("filter", "verified")
        |> Map.put("verified_at_start_timestamp", "1663749418")

      response =
        conn
        |> get("/api", filter_params)
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response_2 = find_element_by_address(response["result"], to_string(contract_2.address_hash))
      contract_from_response_3 = find_element_by_address(response["result"], to_string(contract_3.address_hash))
      assert [contract_from_response_2, contract_from_response_3] == [result(contract_2), result(contract_3)]

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only verified contracts with end created_at timestamp < given timestamp shows only verified contracts in that range",
         %{
           params: params,
           conn: conn
         } do
      [contract_1, contract_2, _contract_3] = prepare_contracts()

      filter_params =
        params
        |> Map.put("filter", "verified")
        |> Map.put("verified_at_end_timestamp", "1663922218")

      response =
        conn
        |> get("/api", filter_params)
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      assert response["result"] == [result(contract_1), result(contract_2)]

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only decompiled contracts shows only decompiled contracts", %{params: params, conn: conn} do
      insert(:contract_address)
      decompiled_smart_contract = insert(:decompiled_smart_contract)

      response =
        conn
        |> get("/api", Map.put(params, "filter", "decompiled"))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      assert response["result"] == [result_not_verified(decompiled_smart_contract.address_hash)]

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only decompiled contracts, with a decompiled with version filter", %{params: params, conn: conn} do
      insert(:decompiled_smart_contract, decompiler_version: "foobar")
      smart_contract = insert(:decompiled_smart_contract, decompiler_version: "bizbuz")

      response =
        conn
        |> get("/api", Map.merge(params, %{"filter" => "decompiled", "not_decompiled_with_version" => "foobar"}))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      assert response["result"] == [result_not_verified(smart_contract.address_hash)]

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only decompiled contracts, with a decompiled with version filter, where another decompiled version exists",
         %{params: params, conn: conn} do
      non_match = insert(:decompiled_smart_contract, decompiler_version: "foobar")
      insert(:decompiled_smart_contract, decompiler_version: "bizbuz", address_hash: non_match.address_hash)
      smart_contract = insert(:decompiled_smart_contract, decompiler_version: "bizbuz")

      response =
        conn
        |> get("/api", Map.merge(params, %{"filter" => "decompiled", "not_decompiled_with_version" => "foobar"}))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      assert result_not_verified(smart_contract.address_hash) in response["result"]

      refute to_string(non_match.address_hash) in Enum.map(response["result"], &Map.get(&1, "Address"))
      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only not_decompiled (and by extension not verified contracts)", %{params: params, conn: conn} do
      insert(:decompiled_smart_contract)
      insert(:smart_contract, contract_code_md5: "123")
      contract_address = insert(:contract_address)

      response =
        conn
        |> get("/api", Map.put(params, "filter", "not_decompiled"))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response = find_element_by_address(response["result"], to_string(contract_address.hash))
      assert contract_from_response == result_not_verified(contract_address.hash)

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end

    test "filtering for only not_decompiled (and by extension not verified contracts) does not show empty contracts", %{
      params: params,
      conn: conn
    } do
      insert(:decompiled_smart_contract)
      insert(:smart_contract, contract_code_md5: "123")
      insert(:contract_address, contract_code: "0x")
      contract_address = insert(:contract_address)

      response =
        conn
        |> get("/api", Map.put(params, "filter", "not_decompiled"))
        |> json_response(200)

      assert response["message"] == "OK"
      assert response["status"] == "1"

      contract_from_response = find_element_by_address(response["result"], to_string(contract_address.hash))
      assert contract_from_response == result_not_verified(contract_address.hash)

      assert :ok = ExJsonSchema.Validator.validate(listcontracts_schema(), response)
    end
  end

  describe "getabi" do
    test "with missing address hash", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getabi"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "address is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getabi_schema(), response)
    end

    test "with an invalid address hash", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getabi",
        "address" => "badhash"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid address hash"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getabi_schema(), response)
    end

    test "with an address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getabi",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["result"] == nil
      assert response["status"] == "0"
      assert response["message"] == "Contract source code not verified"
      assert :ok = ExJsonSchema.Validator.validate(getabi_schema(), response)
    end

    test "with a verified contract address", %{conn: conn} do
      contract = insert(:smart_contract, contract_code_md5: "123")

      params = %{
        "module" => "contract",
        "action" => "getabi",
        "address" => to_string(contract.address_hash)
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["result"] == Jason.encode!(contract.abi)
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(getabi_schema(), response)
    end
  end

  describe "getsourcecode" do
    test "with missing address hash", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getsourcecode"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "address is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getsourcecode_schema(), response)
    end

    test "with an invalid address hash", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getsourcecode",
        "address" => "badhash"
      }

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid address hash"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getsourcecode_schema(), response)
    end

    test "with an address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getsourcecode",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      expected_result = [
        %{
          "Address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
        }
      ]

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(getsourcecode_schema(), response)
    end

    test "with a verified contract address", %{conn: conn} do
      contract =
        insert(:smart_contract,
          optimization: true,
          optimization_runs: 200,
          evm_version: "default",
          contract_code_md5: "123"
        )

      params = %{
        "module" => "contract",
        "action" => "getsourcecode",
        "address" => to_string(contract.address_hash)
      }

      expected_result = [
        %{
          "Address" => to_string(contract.address_hash),
          "SourceCode" => contract.contract_source_code,
          "ABI" => Jason.encode!(contract.abi),
          "ContractName" => contract.name,
          "CompilerVersion" => contract.compiler_version,
          # The contract's optimization value is true, so the expected value
          # for `OptimizationUsed` is "1". If it was false, the expected value
          # would be "0".
          "OptimizationUsed" => "true",
          "OptimizationRuns" => 200,
          "EVMVersion" => "default",
          "FileName" => "",
          "IsProxy" => "false"
        }
      ]

      get_implementation()

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(getsourcecode_schema(), response)
    end

    test "with constructor arguments", %{conn: conn} do
      contract =
        insert(:smart_contract,
          optimization: true,
          optimization_runs: 200,
          evm_version: "default",
          constructor_arguments:
            "00000000000000000000000008e7592ce0d7ebabf42844b62ee6a878d4e1913e000000000000000000000000e1b6037da5f1d756499e184ca15254a981c92546",
          contract_code_md5: "123"
        )

      params = %{
        "module" => "contract",
        "action" => "getsourcecode",
        "address" => to_string(contract.address_hash)
      }

      expected_result = [
        %{
          "Address" => to_string(contract.address_hash),
          "SourceCode" => contract.contract_source_code,
          "ABI" => Jason.encode!(contract.abi),
          "ContractName" => contract.name,
          "CompilerVersion" => contract.compiler_version,
          "OptimizationUsed" => "true",
          "OptimizationRuns" => 200,
          "EVMVersion" => "default",
          "ConstructorArguments" =>
            "00000000000000000000000008e7592ce0d7ebabf42844b62ee6a878d4e1913e000000000000000000000000e1b6037da5f1d756499e184ca15254a981c92546",
          "FileName" => "",
          "IsProxy" => "false"
        }
      ]

      get_implementation()

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(getsourcecode_schema(), response)
    end

    test "with external library", %{conn: conn} do
      smart_contract_bytecode =
        "0x608060405234801561001057600080fd5b5060df8061001f6000396000f3006080604052600436106049576000357c0100000000000000000000000000000000000000000000000000000000900463ffffffff16806360fe47b114604e5780636d4ce63c146078575b600080fd5b348015605957600080fd5b5060766004803603810190808035906020019092919050505060a0565b005b348015608357600080fd5b50608a60aa565b6040518082815260200191505060405180910390f35b8060008190555050565b600080549050905600a165627a7a7230582040d82a7379b1ee1632ad4d8a239954fd940277b25628ead95259a85c5eddb2120029"

      created_contract_address =
        insert(
          :address,
          hash: "0x0f95fa9bc0383e699325f2658d04e8d96d87b90c",
          contract_code: smart_contract_bytecode
        )

      transaction =
        :transaction
        |> insert()
        |> with_block()

      insert(
        :internal_transaction_create,
        transaction: transaction,
        index: 0,
        created_contract_address: created_contract_address,
        created_contract_code: smart_contract_bytecode,
        block_number: transaction.block_number,
        block_hash: transaction.block_hash,
        block_index: 0,
        transaction_index: transaction.index
      )

      valid_attrs = %{
        address_hash: "0x0f95fa9bc0383e699325f2658d04e8d96d87b90c",
        name: "Test",
        compiler_version: "0.4.23",
        contract_source_code:
          "pragma solidity ^0.4.23; contract SimpleStorage {uint storedData; function set(uint x) public {storedData = x; } function get() public constant returns (uint) {return storedData; } }",
        abi: [
          %{
            "constant" => false,
            "inputs" => [%{"name" => "x", "type" => "uint256"}],
            "name" => "set",
            "outputs" => [],
            "payable" => false,
            "stateMutability" => "nonpayable",
            "type" => "function"
          },
          %{
            "constant" => true,
            "inputs" => [],
            "name" => "get",
            "outputs" => [%{"name" => "", "type" => "uint256"}],
            "payable" => false,
            "stateMutability" => "view",
            "type" => "function"
          }
        ],
        optimization: true,
        optimization_runs: 200,
        evm_version: "default"
      }

      external_libraries = [
        %SmartContract.ExternalLibrary{:address_hash => "0xb18aed9518d735482badb4e8b7fd8d2ba425ce95", :name => "Test"},
        %SmartContract.ExternalLibrary{:address_hash => "0x283539e1b1daf24cdd58a3e934d55062ea663c3f", :name => "Test2"}
      ]

      {:ok, %SmartContract{} = contract} = Chain.create_smart_contract(valid_attrs, external_libraries)

      params = %{
        "module" => "contract",
        "action" => "getsourcecode",
        "address" => to_string(contract.address_hash)
      }

      expected_result = [
        %{
          "Address" => to_string(contract.address_hash),
          "SourceCode" => contract.contract_source_code,
          "ABI" => Jason.encode!(contract.abi),
          "ContractName" => contract.name,
          "CompilerVersion" => contract.compiler_version,
          "OptimizationUsed" => "true",
          "OptimizationRuns" => 200,
          "EVMVersion" => "default",
          "ExternalLibraries" => [
            %{"name" => "Test", "address_hash" => "0xb18aed9518d735482badb4e8b7fd8d2ba425ce95"},
            %{"name" => "Test2", "address_hash" => "0x283539e1b1daf24cdd58a3e934d55062ea663c3f"}
          ],
          "FileName" => "",
          "IsProxy" => "false"
        }
      ]

      get_implementation()

      assert response =
               conn
               |> get("/api", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(getsourcecode_schema(), response)
    end
  end

  defp listcontracts_schema do
    resolve_schema(%{
      "type" => ["array", "null"],
      "items" => %{
        "type" => "object",
        "properties" => %{
          "Address" => %{"type" => "string"},
          "ABI" => %{"type" => "string"},
          "ContractName" => %{"type" => "string"},
          "CompilerVersion" => %{"type" => "string"},
          "OptimizationUsed" => %{"type" => "string"}
        }
      }
    })
  end

  defp getabi_schema do
    resolve_schema(%{
      "type" => ["string", "null"]
    })
  end

  defp getsourcecode_schema do
    resolve_schema(%{
      "type" => ["array", "null"],
      "items" => %{
        "type" => "object",
        "properties" => %{
          "Address" => %{"type" => "string"},
          "SourceCode" => %{"type" => "string"},
          "ABI" => %{"type" => "string"},
          "ContractName" => %{"type" => "string"},
          "CompilerVersion" => %{"type" => "string"},
          "OptimizationUsed" => %{"type" => "string"},
          "DecompiledSourceCode" => %{"type" => "string"},
          "DecompilerVersion" => %{"type" => "string"}
        }
      }
    })
  end

  # defp verify_schema do
  #   resolve_schema(%{
  #     "type" => "object",
  #     "properties" => %{
  #       "Address" => %{"type" => "string"},
  #       "SourceCode" => %{"type" => "string"},
  #       "ABI" => %{"type" => "string"},
  #       "ContractName" => %{"type" => "string"},
  #       "CompilerVersion" => %{"type" => "string"},
  #       "DecompiledSourceCode" => %{"type" => "string"},
  #       "DecompilerVersion" => %{"type" => "string"},
  #       "OptimizationUsed" => %{"type" => "string"}
  #     }
  #   })
  # end

  defp resolve_schema(result) do
    %{
      "type" => "object",
      "properties" => %{
        "message" => %{"type" => "string"},
        "status" => %{"type" => "string"}
      }
    }
    |> put_in(["properties", "result"], result)
    |> ExJsonSchema.Schema.resolve()
  end

  def get_implementation do
    EthereumJSONRPC.Mox
    |> expect(:json_rpc, fn %{
                              id: 0,
                              method: "eth_getStorageAt",
                              params: [
                                _,
                                "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc",
                                "latest"
                              ]
                            },
                            _options ->
      {:ok, "0x0000000000000000000000000000000000000000000000000000000000000000"}
    end)
    |> expect(:json_rpc, fn %{
                              id: 0,
                              method: "eth_getStorageAt",
                              params: [
                                _,
                                "0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50",
                                "latest"
                              ]
                            },
                            _options ->
      {:ok, "0x0000000000000000000000000000000000000000000000000000000000000000"}
    end)
    |> expect(:json_rpc, fn %{
                              id: 0,
                              method: "eth_getStorageAt",
                              params: [
                                _,
                                "0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3",
                                "latest"
                              ]
                            },
                            _options ->
      {:ok, "0x0000000000000000000000000000000000000000000000000000000000000000"}
    end)
  end

  def find_element_by_address(contract_list, address) do
    Enum.find(contract_list, fn map -> map["Address"] == address end)
  end

  defp verify_native_contracts(native_contract_list) do

    withdrawal_request_contract = %{
      "Address" => "0x0000000000000000000011111111111111111111",
      "CompilerVersion" => "-",
      "ContractName" => "Withdrawal Request",
      "OptimizationUsed" => "0",
      "ABI" => "[{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"bytes20\",\"name\":\"mcDest\",\"type\":\"bytes20\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint32\",\"name\":\"epochNumber\",\"type\":\"uint32\"}],\"name\":\"AddWithdrawalRequest\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"PubKeyHash\",\"name\":\"pubKeyHash\",\"type\":\"bytes20\"}],\"name\":\"backwardTransfer\",\"outputs\":[{\"components\":[{\"internalType\":\"PubKeyHash\",\"name\":\"pubKeyHash\",\"type\":\"bytes20\"},{\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"internalType\":\"struct WithdrawalRequests.WithdrawalRequest\",\"name\":\"\",\"type\":\"tuple\"}],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint32\",\"name\":\"withdrawalEpoch\",\"type\":\"uint32\"}],\"name\":\"getBackwardTransfers\",\"outputs\":[{\"components\":[{\"internalType\":\"PubKeyHash\",\"name\":\"pubKeyHash\",\"type\":\"bytes20\"},{\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"internalType\":\"struct WithdrawalRequests.WithdrawalRequest[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]",
    }

    forger_stake_contract = %{
      "Address" => "0x0000000000000000000022222222222222222222",
      "CompilerVersion" => "-",
      "ContractName" => "Forger Stake",
      "OptimizationUsed" => "0",
      "ABI" => "[{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes32\",\"name\":\"stakeId\",\"type\":\"bytes32\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\"}],\"name\":\"DelegateForgerStake\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"uint32\",\"name\":\"forgerIndex\",\"type\":\"uint32\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"sender\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes32\",\"name\":\"blockSignProposition\",\"type\":\"bytes32\"}],\"name\":\"OpenForgerList\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint32\",\"name\":\"oldVersion\",\"type\":\"uint32\"},{\"indexed\":false,\"internalType\":\"uint32\",\"name\":\"newVersion\",\"type\":\"uint32\"}],\"name\":\"StakeUpgrade\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes32\",\"name\":\"stakeId\",\"type\":\"bytes32\"}],\"name\":\"WithdrawForgerStake\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"publicKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"delegate\",\"outputs\":[{\"internalType\":\"StakeID\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getAllForgersStakes\",\"outputs\":[{\"components\":[{\"internalType\":\"StakeID\",\"name\":\"stakeId\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"stakedAmount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"publicKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"}],\"internalType\":\"struct ForgerStakes.StakeInfo[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"int32\",\"name\":\"startIndex\",\"type\":\"int32\"},{\"internalType\":\"int32\",\"name\":\"pageSize\",\"type\":\"int32\"}],\"name\":\"getPagedForgersStakes\",\"outputs\":[{\"internalType\":\"int32\",\"name\":\"\",\"type\":\"int32\"},{\"components\":[{\"internalType\":\"StakeID\",\"name\":\"stakeId\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"stakedAmount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"publicKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"}],\"internalType\":\"struct ForgerStakes.StakeInfo[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"int32\",\"name\":\"startIndex\",\"type\":\"int32\"},{\"internalType\":\"int32\",\"name\":\"pageSize\",\"type\":\"int32\"}],\"name\":\"getPagedForgersStakesByUser\",\"outputs\":[{\"internalType\":\"int32\",\"name\":\"\",\"type\":\"int32\"},{\"components\":[{\"internalType\":\"StakeID\",\"name\":\"stakeId\",\"type\":\"bytes32\"},{\"internalType\":\"uint256\",\"name\":\"stakedAmount\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"},{\"internalType\":\"bytes32\",\"name\":\"publicKey\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"vrf1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"vrf2\",\"type\":\"bytes1\"}],\"internalType\":\"struct ForgerStakes.StakeInfo[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint32\",\"name\":\"forgerIndex\",\"type\":\"uint32\"},{\"internalType\":\"bytes32\",\"name\":\"signature1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signature2\",\"type\":\"bytes32\"}],\"name\":\"openStakeForgerList\",\"outputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\"}],\"name\":\"stakeOf\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"upgrade\",\"outputs\":[{\"internalType\":\"uint32\",\"name\":\"\",\"type\":\"uint32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"StakeID\",\"name\":\"stakeId\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"signatureV\",\"type\":\"bytes1\"},{\"internalType\":\"bytes32\",\"name\":\"signatureR\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signatureS\",\"type\":\"bytes32\"}],\"name\":\"withdraw\",\"outputs\":[{\"internalType\":\"StakeID\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]"
    }

    certificate_key_rotation_contract = %{
      "Address" => "0x0000000000000000000044444444444444444444",
      "CompilerVersion" => "-",
      "ContractName" => "Certificate Key Rotation",
      "OptimizationUsed" => "0",
      "ABI" => "[{\"inputs\":[{\"internalType\":\"uint32\",\"name\":\"key_type\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"index\",\"type\":\"uint32\"},{\"internalType\":\"bytes32\",\"name\":\"newKey_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"newKey_2\",\"type\":\"bytes1\"},{\"internalType\":\"bytes32\",\"name\":\"signKeySig_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signKeySig_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"masterKeySig_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"masterKeySig_2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"newKeySig_1\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"newKeySig_2\",\"type\":\"bytes32\"}],\"name\":\"submitKeyRotation\",\"outputs\":[{\"internalType\":\"uint32\",\"name\":\"\",\"type\":\"uint32\"},{\"internalType\":\"uint32\",\"name\":\"\",\"type\":\"uint32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes1\",\"name\":\"\",\"type\":\"bytes1\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]"
    }

    mainchain_address_ownership_contract = %{
      "Address" => "0x0000000000000000000088888888888888888888",
      "CompilerVersion" => "-",
      "ContractName" => "Mainchain Address Ownership",
      "OptimizationUsed" => "0",
      "ABI" => "[{\"inputs\":[],\"name\":\"getAllKeyOwnerships\",\"outputs\":[{\"components\":[{\"internalType\":\"address\",\"name\":\"scAddress\",\"type\":\"address\"},{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"}],\"internalType\":\"struct McAddrOwnership.McAddrOwnershipData[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"getKeyOwnerScAddresses\",\"outputs\":[{\"internalType\":\"address[]\",\"name\":\"\",\"type\":\"address[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"scAddress\",\"type\":\"address\"}],\"name\":\"getKeyOwnerships\",\"outputs\":[{\"components\":[{\"internalType\":\"address\",\"name\":\"scAddress\",\"type\":\"address\"},{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"}],\"internalType\":\"struct McAddrOwnership.McAddrOwnershipData[]\",\"name\":\"\",\"type\":\"tuple[]\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"}],\"name\":\"removeKeysOwnership\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"bytes3\",\"name\":\"mcAddrBytes1\",\"type\":\"bytes3\"},{\"internalType\":\"bytes32\",\"name\":\"mcAddrBytes2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes24\",\"name\":\"signature1\",\"type\":\"bytes24\"},{\"internalType\":\"bytes32\",\"name\":\"signature2\",\"type\":\"bytes32\"},{\"internalType\":\"bytes32\",\"name\":\"signature3\",\"type\":\"bytes32\"}],\"name\":\"sendKeysOwnership\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"mcMultisigAddress\",\"type\":\"string\"},{\"internalType\":\"string\",\"name\":\"redeemScript\",\"type\":\"string\"},{\"internalType\":\"string[]\",\"name\":\"mcSignatures\",\"type\":\"string[]\"}],\"name\":\"sendMultisigKeysOwnership\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]"
    }

    [withdrawal_request_from_db, forger_stake_from_db, certificate_key_rotation_from_db, mainchain_address_ownership_from_db] = native_contract_list

    assert withdrawal_request_from_db == withdrawal_request_contract
    assert forger_stake_from_db == forger_stake_contract
    assert certificate_key_rotation_from_db == certificate_key_rotation_contract
    assert mainchain_address_ownership_from_db == mainchain_address_ownership_contract
  end

end
