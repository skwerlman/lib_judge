defmodule LibJudge.Versions do
  @moduledoc """
  TODO
  """

  @spec get(version :: String.t()) :: String.t()
  def get("20200122") do
    File.read!("priv/data/MagicCompRules 20200122.txt")
  end
end
