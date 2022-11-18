defmodule LibJudgeTokenizerTest do
  use ExUnit.Case, async: true
  doctest LibJudge.Tokenizer

  @token_kinds [
    :title,
    :effective_date,
    :intro,
    :contents,
    :rule,
    :glossary
  ]

  describe "tokenizer" do
    for txt_version <- ["20210224", "20210712", "20221118"] do
      @raw_text LibJudge.get!(txt_version, false)

      test "returns a list of tokens, version: #{txt_version}" do
        tokens = LibJudge.tokenize(@raw_text)
        assert is_list(tokens)
        assert tokens != []

        assert Enum.reduce(tokens, true, fn
                 {kind, _token}, acc ->
                   acc and kind in @token_kinds

                 _, _ ->
                   false
               end)
      end

      test "returns correct rule structs, version: #{txt_version}" do
        tokens = LibJudge.tokenize(@raw_text)
        rules = Enum.filter(tokens, LibJudge.Filter.token_type(:rule))

        Enum.each(rules, fn
          {:rule, {_, rule, _, _}} ->
            assert {:ok, _} = LibJudge.Rule.to_string(rule)
        end)
      end
    end
  end
end
