defmodule LibJudgeFilterTest do
  use ExUnit.Case, async: true
  use PropCheck
  import LibJudgeTest.Models.Rules
  alias LibJudge.Filter
  doctest LibJudge.Filter

  @runs_per_test 5_000

  # load rules from cache and tokenize before testing
  @raw_text LibJudge.get!("20210224", false)
  @tokens LibJudge.tokenize(@raw_text)

  describe "rule_is filter" do
    test "finds exactly 1 match when it succeeds" do
      filter = Filter.rule_is("100.1.")
      assert is_function(filter)
      assert :erlang.fun_info(filter)[:arity] == 1

      matches = Enum.filter(@tokens, filter)
      assert is_list(matches)
      assert length(matches) == 1

      match = hd(matches)
      assert match?({:rule, {:rule, %LibJudge.Rule{type: :rule}, _, _}}, match)
    end

    property "only ever finds 0 or 1 matches",
      detect_exceptions: true,
      numtests: @runs_per_test do
      forall {rule_str, type} <- any_rule_str() do
        filter = Filter.rule_is(rule_str)
        assert is_function(filter)
        assert :erlang.fun_info(filter)[:arity] == 1

        matches = Enum.filter(@tokens, filter)
        assert is_list(matches)
        assert Enum.empty?(matches) or length(matches) == 1

        if length(matches) == 1 do
          assert match?({:rule, {^type, %LibJudge.Rule{type: ^type}, _, _}}, hd(matches))
        else
          assert matches == []
        end
      end
    end

    property "handles bad data gracefully",
      detect_exceptions: true,
      numtests: @runs_per_test do
      trap_exit(
        forall [{rule_str, type}, bad_data] <- [
                 oneof([any_rule_str(), tuple([term(), exactly(:bad)])]),
                 list(term())
               ] do
          tokens = Enum.shuffle(@tokens ++ bad_data)

          filter = Filter.rule_is(rule_str)
          assert is_function(filter)
          assert :erlang.fun_info(filter)[:arity] == 1

          matches = Enum.filter(tokens, filter)
          assert is_list(matches)
          assert Enum.empty?(matches) or length(matches) == 1

          if length(matches) == 1 do
            assert match?({:rule, {^type, %LibJudge.Rule{type: ^type}, _, _}}, hd(matches))
          else
            assert matches == []
          end
        end
      )
    end
  end
end
