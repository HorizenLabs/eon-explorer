defmodule BlockScoutWeb.AddressForwardTransferView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.AccessHelper
  alias Explorer.Chain.Address

  def format_current_filter(filter) do
    case filter do
      _ -> gettext("All")
    end
  end
end
