defmodule LibJudgeTokenizerTest do
  use ExUnit.Case, async: true
  doctest LibJudge.Tokenizer

  describe "tokenizer" do
    @raw_text LibJudge.get!("20210224", false)
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
                 kind in @token_kinds and acc

               _, _ ->
                 false
             end)
    end
  end
end
