defmodule LibJudge.Tokenizer.Guards do
  @moduledoc false
  @legal_rules_1 Enum.map(1..9, &to_string/1)
  @legal_rules_2 Enum.map(10..99, &to_string/1)
  @legal_rules_3 Enum.map(100..999, &to_string/1)

  defguard is_rule_1(bin) when bin in @legal_rules_1
  defguard is_rule_2(bin) when bin in @legal_rules_2
  defguard is_rule_3(bin) when bin in @legal_rules_3
end
