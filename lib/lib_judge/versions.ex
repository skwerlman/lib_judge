defmodule LibJudge.Versions do
  def get("20200122") do
    File.read!("priv/data/MagicCompRules 20200122.txt")
  end
end
