defmodule LibJudge.Versions do
  @moduledoc """
  TODO
  """

  @spec get(version :: String.t()) :: String.t()
  def get(ver) do
    File.read!("priv/data/MagicCompRules " <> ver <> ".txt")
  end
end
