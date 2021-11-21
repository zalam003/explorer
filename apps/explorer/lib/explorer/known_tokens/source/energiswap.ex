defmodule Explorer.KnownTokens.Source.EnergiSwap do
  @moduledoc """
  Adapter for fetching known tokens from EnergiSwap API
  """

  alias Explorer.KnownTokens.Source

  @behaviour Source

  @impl Source
  def source_url do
    Application.get_env(:explorer, :energiswap_api_url)
  end
end
