defmodule BlockScoutWeb.FeePaymentView do
  use BlockScoutWeb, :view

  alias Explorer.Chain.FeePayment
  alias BlockScoutWeb.{BlockView}

  @dialyzer :no_match

  @doc """
  Converts a transaction's Wei value to Ether and returns a formatted display value.

  ## Options

  * `:include_label` - Boolean. Defaults to true. Flag for displaying unit with value.
  """
  def value(%{value: value}, opts \\ []) do
    include_label? = Keyword.get(opts, :include_label, true)
    format_wei_value(value, :ether, include_unit_label: include_label?)
  end

  def block_number(%FeePayment{block: block}), do: [view_module: BlockView, partial: "_link.html", block: block]

  def format_wei_value(value) do
    format_wei_value(value, :ether, include_unit_label: false)
  end

  def identifier(%FeePayment{block_number: block_number, index: index}) do
    "#{block_number}#{index}"
  end
end
