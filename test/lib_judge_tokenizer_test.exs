defmodule LibJudgeTokenizerTest do
  use ExUnit.Case, async: true
  doctest LibJudge.Tokenizer

  describe "tokenizer" do
    @raw_text LibJudge.get!("20210224", false)

    test "can read rules from a string" do
      assert is_list(LibJudge.tokenize(@raw_text))
    end
  end
end
