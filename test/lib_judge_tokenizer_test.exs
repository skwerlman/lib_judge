defmodule LibJudgeTokenizerTest do
  use ExUnit.Case, async: true
  doctest LibJudge.Tokenizer

  describe "tokenizer" do
    @raw_text LibJudge.get!("20210224", false)
    @known_buggy_rules LibJudge.get!("20210712", false)
    @token_kinds [
      :title,
      :effective_date,
      :intro,
      :contents,
      :rule,
      :glossary
    ]

    test "returns a list of tokens" do
      tokens = LibJudge.tokenize(@raw_text)
      assert is_list(tokens)

      assert Enum.reduce(tokens, true, fn
               {kind, _token}, acc ->
                 acc and kind in @token_kinds

               _, _ ->
                 false
             end)
    end

    test "returns correct rule structs" do
      tokens = LibJudge.tokenize(@known_buggy_rules)
      rules = Enum.filter(tokens, LibJudge.Filter.token_type(:rule))

      Enum.each(rules, fn
        {:rule, {_, rule, _, _}} ->
          assert {:ok, _} = LibJudge.Rule.to_string(rule)
      end)
    end
  end
end
