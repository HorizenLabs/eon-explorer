defmodule RPCTranslatorForwarder do
  @moduledoc """
  Phoenix router limits forwarding,
  so this module is to forward old paths for backward compatibility
  """
  alias BlockScoutWeb.API.RPC.RPCTranslator
  defdelegate init(opts), to: RPCTranslator
  defdelegate call(conn, opts), to: RPCTranslator
end

defmodule BlockScoutWeb.ApiRouter do
  @moduledoc """
  Router for API
  """
  use BlockScoutWeb, :router
  alias BlockScoutWeb.{APIKeyV2Router, SmartContractsApiV2Router}
  alias BlockScoutWeb.Plug.{CheckAccountAPI, CheckApiV2, RateLimit}

  forward("/v2/smart-contracts", SmartContractsApiV2Router)
  forward("/v2/key", APIKeyV2Router)

  pipeline :api do
    plug(BlockScoutWeb.Plug.Logger, application: :api)
    plug(:accepts, ["json"])
  end

  pipeline :account_api do
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(CheckAccountAPI)
  end

  pipeline :api_v2 do
    plug(BlockScoutWeb.Plug.Logger, application: :api_v2)
    plug(:accepts, ["json"])
    plug(CheckApiV2)
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(RateLimit)
  end

  pipeline :api_v2_no_session do
    plug(BlockScoutWeb.Plug.Logger, application: :api_v2)
    plug(:accepts, ["json"])
    plug(CheckApiV2)
    plug(RateLimit)
  end

  alias BlockScoutWeb.Account.Api.V1.{AuthenticateController, EmailController, TagsController, UserController}
  alias BlockScoutWeb.API.V2
  alias API.MetricsController

  scope "/metrics", BlockScoutWeb do
    pipe_through(:api)

    get("/avg-block-time", MetricsController, :average_block_time)
    get("/total-accounts", MetricsController, :total_accounts)
    get("/total-blocks", MetricsController, :total_blocks)
    get("/total-smart-contracts", MetricsController, :total_smart_contracts)
    get("/total-transactions", MetricsController, :total_transactions)
    get("/total-value-locked", MetricsController, :total_value_locked)
    get("/total/:table_name", MetricsController, :total)

    scope "/last-thirty" do
      get("/active-accounts", MetricsController, :thirty_day_active_account_count_list)
      get("/active-devs", MetricsController, :thirty_day_active_dev_count_list)
      get("/avg-tx-fee", MetricsController, :thirty_day_avg_tx_fee_list)
      get("/gas-used", MetricsController, :thirty_day_gas_used_list)
      get("/contracts", MetricsController, :thirty_day_contract_count_list)
      get("/transactions", MetricsController, :thirty_day_tx_count_list)
    end
  end

  scope "/account/v1", as: :account_v1 do
    pipe_through(:api)
    pipe_through(:account_api)

    get("/authenticate", AuthenticateController, :authenticate_get)
    post("/authenticate", AuthenticateController, :authenticate_post)

    get("/get_csrf", UserController, :get_csrf)

    scope "/email" do
      get("/resend", EmailController, :resend_email)
    end

    scope "/user" do
      get("/info", UserController, :info)

      get("/watchlist", UserController, :watchlist)
      delete("/watchlist/:id", UserController, :delete_watchlist)
      post("/watchlist", UserController, :create_watchlist)
      put("/watchlist/:id", UserController, :update_watchlist)

      get("/api_keys", UserController, :api_keys)
      delete("/api_keys/:api_key", UserController, :delete_api_key)
      post("/api_keys", UserController, :create_api_key)
      put("/api_keys/:api_key", UserController, :update_api_key)

      get("/custom_abis", UserController, :custom_abis)
      delete("/custom_abis/:id", UserController, :delete_custom_abi)
      post("/custom_abis", UserController, :create_custom_abi)
      put("/custom_abis/:id", UserController, :update_custom_abi)

      get("/public_tags", UserController, :public_tags_requests)
      delete("/public_tags/:id", UserController, :delete_public_tags_request)
      post("/public_tags", UserController, :create_public_tags_request)
      put("/public_tags/:id", UserController, :update_public_tags_request)

      scope "/tags" do
        get("/address/", UserController, :tags_address)
        get("/address/:id", UserController, :tags_address)
        delete("/address/:id", UserController, :delete_tag_address)
        post("/address/", UserController, :create_tag_address)
        put("/address/:id", UserController, :update_tag_address)

        get("/transaction/", UserController, :tags_transaction)
        get("/transaction/:id", UserController, :tags_transaction)
        delete("/transaction/:id", UserController, :delete_tag_transaction)
        post("/transaction/", UserController, :create_tag_transaction)
        put("/transaction/:id", UserController, :update_tag_transaction)
      end
    end
  end

  scope "/account/v1" do
    pipe_through(:api)
    pipe_through(:account_api)

    scope "/tags" do
      get("/address/:address_hash", TagsController, :tags_address)

      get("/transaction/:transaction_hash", TagsController, :tags_transaction)
    end
  end

  scope "/v2/import" do
    pipe_through(:api_v2_no_session)

    post("/token-info", V2.ImportController, :import_token_info)
  end

  scope "/v2", as: :api_v2 do
    pipe_through(:api_v2)

    scope "/search" do
      get("/", V2.SearchController, :search)
      get("/check-redirect", V2.SearchController, :check_redirect)
      get("/quick", V2.SearchController, :quick_search)
    end

    scope "/config" do
      get("/json-rpc-url", V2.ConfigController, :json_rpc_url)
      get("/backend-version", V2.ConfigController, :backend_version)
    end

    scope "/transactions" do
      get("/", V2.TransactionController, :transactions)
      get("/watchlist", V2.TransactionController, :watchlist_transactions)
      get("/:transaction_hash", V2.TransactionController, :transaction)
      get("/:transaction_hash/token-transfers", V2.TransactionController, :token_transfers)
      get("/:transaction_hash/internal-transactions", V2.TransactionController, :internal_transactions)
      get("/:transaction_hash/logs", V2.TransactionController, :logs)
      get("/:transaction_hash/raw-trace", V2.TransactionController, :raw_trace)
      get("/:transaction_hash/state-changes", V2.TransactionController, :state_changes)
    end

    scope "/blocks" do
      get("/", V2.BlockController, :blocks)
      get("/:block_hash_or_number", V2.BlockController, :block)
      get("/:block_hash_or_number/transactions", V2.BlockController, :transactions)
      get("/:block_hash_or_number/withdrawals", V2.BlockController, :withdrawals)
      get("/:block_hash_or_number/forward-transfers", V2.BlockController, :forward_transfers)
      get("/:block_hash_or_number/fee-payments", V2.BlockController, :fee_payments)
    end

    scope "/addresses" do
      get("/", V2.AddressController, :addresses_list)
      get("/:address_hash", V2.AddressController, :address)
      get("/:address_hash/counters", V2.AddressController, :counters)
      get("/:address_hash/token-balances", V2.AddressController, :token_balances)
      get("/:address_hash/tokens", V2.AddressController, :tokens)
      get("/:address_hash/transactions", V2.AddressController, :transactions)
      get("/:address_hash/token-transfers", V2.AddressController, :token_transfers)
      get("/:address_hash/internal-transactions", V2.AddressController, :internal_transactions)
      get("/:address_hash/logs", V2.AddressController, :logs)
      get("/:address_hash/blocks-validated", V2.AddressController, :blocks_validated)
      get("/:address_hash/coin-balance-history", V2.AddressController, :coin_balance_history)
      get("/:address_hash/coin-balance-history-by-day", V2.AddressController, :coin_balance_history_by_day)
      get("/:address_hash/withdrawals", V2.AddressController, :withdrawals)
      get("/:address_hash/forward-transfers", V2.AddressController, :forward_transfers)
      get("/:address_hash/fee-payments", V2.AddressController, :fee_payments)
    end

    scope "/forward-transfers" do
      get("/", V2.ForwardTransferController, :forward_transfers)
    end

    scope "/fee-payments" do
      get("/", V2.FeePaymentsController, :fee_payments)
    end

    scope "/tokens" do
      get("/", V2.TokenController, :tokens_list)
      get("/:address_hash", V2.TokenController, :token)
      get("/:address_hash/counters", V2.TokenController, :counters)
      get("/:address_hash/transfers", V2.TokenController, :transfers)
      get("/:address_hash/holders", V2.TokenController, :holders)
      get("/:address_hash/instances", V2.TokenController, :instances)
      get("/:address_hash/instances/:token_id", V2.TokenController, :instance)
      get("/:address_hash/instances/:token_id/transfers", V2.TokenController, :transfers_by_instance)
      get("/:address_hash/instances/:token_id/holders", V2.TokenController, :holders_by_instance)
      get("/:address_hash/instances/:token_id/transfers-count", V2.TokenController, :transfers_count_by_instance)
    end

    scope "/main-page" do
      get("/blocks", V2.MainPageController, :blocks)
      get("/transactions", V2.MainPageController, :transactions)
      get("/transactions/watchlist", V2.MainPageController, :watchlist_transactions)
      get("/indexing-status", V2.MainPageController, :indexing_status)
    end

    scope "/stats" do
      get("/", V2.StatsController, :stats)

      scope "/charts" do
        get("/transactions", V2.StatsController, :transactions_chart)
        get("/market", V2.StatsController, :market_chart)
      end
    end

    scope "/withdrawals" do
      get("/", V2.WithdrawalController, :withdrawals_list)
      get("/counters", V2.WithdrawalController, :withdrawals_counters)
    end
  end

  scope "/v1", as: :api_v1 do
    pipe_through(:api)
    alias BlockScoutWeb.API.{EthRPC, RPC, V1}
    alias BlockScoutWeb.API.V1.{GasPriceOracleController, HealthController}
    alias BlockScoutWeb.API.V2.SearchController

    # leave the same endpoint in v1 in order to keep backward compatibility
    get("/search", SearchController, :search)

    scope "/health" do
      get("/", HealthController, :health)
      get("/liveness", HealthController, :liveness)
      get("/readiness", HealthController, :readiness)
    end

    get("/gas-price-oracle", GasPriceOracleController, :gas_price_oracle)

    if Application.compile_env(:block_scout_web, __MODULE__)[:reading_enabled] do
      get("/supply", V1.SupplyController, :supply)
      post("/eth-rpc", EthRPC.EthController, :eth_request)
    end

    if Application.compile_env(:block_scout_web, __MODULE__)[:writing_enabled] do
      post("/decompiled_smart_contract", V1.DecompiledSmartContractController, :create)
      post("/verified_smart_contracts", V1.VerifiedSmartContractController, :create)
    end

    if Application.compile_env(:block_scout_web, __MODULE__)[:reading_enabled] do
      forward("/", RPC.RPCTranslator, %{
        "block" => {RPC.BlockController, []},
        "account" => {RPC.AddressController, []},
        "logs" => {RPC.LogsController, []},
        "token" => {RPC.TokenController, []},
        "stats" => {RPC.StatsController, []},
        "contract" => {RPC.ContractController, [:verify]},
        "transaction" => {RPC.TransactionController, []}
      })
    end
  end

  # For backward compatibility. Should be removed
  scope "/" do
    pipe_through(:api)
    alias BlockScoutWeb.API.{EthRPC, RPC}

    if Application.compile_env(:block_scout_web, __MODULE__)[:reading_enabled] do
      post("/eth-rpc", EthRPC.EthController, :eth_request)

      forward("/", RPCTranslatorForwarder, %{
        "block" => {RPC.BlockController, []},
        "account" => {RPC.AddressController, []},
        "logs" => {RPC.LogsController, []},
        "token" => {RPC.TokenController, []},
        "stats" => {RPC.StatsController, []},
        "contract" => {RPC.ContractController, [:verify]},
        "transaction" => {RPC.TransactionController, []}
      })
    end
  end
end
