defmodule LibJudgeFilterTest do
  use ExUnit.Case, async: true
  use PropCheck
  alias LibJudge.Filter
  doctest LibJudge.Filter

  @runs_per_test 5_000

  # load rules from cache and tokenize before testing
  @raw_text LibJudge.get!("20210224", false)
  @tokens LibJudge.tokenize(@raw_text)

  defp subrule_letter do
    let char <- choose(0x61, 0x7A) do
      to_string([char])
    end
  end

  defp cat_str do
    let cat <- integer(1, 9) do
      {to_string(cat) <> ".", :category}
    end
  end

  defp subcat_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      ending <- oneof(["", "."])
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         ending, :subcategory}
    end
  end

  defp rule_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      rule <- integer(1, 999),
      ending <- oneof(["", "."])
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         "." <>
         to_string(rule) <>
         ending, :rule}
    end
  end

  defp subrule_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      rule <- integer(1, 999),
      subrule <- subrule_letter()
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         "." <>
         to_string(rule) <>
         subrule, :subrule}
    end
  end

  defp any_rule_str do
    oneof([
      cat_str(),
      subcat_str(),
      rule_str(),
      subrule_str()
    ])
  end

  describe "filter" do
    test "rule_is finds exactly 1 match when it succeeds" do
      filter = Filter.rule_is("100.1.")
      assert is_function(filter)
      assert :erlang.fun_info(filter)[:arity] == 1
      matches = Enum.filter(@tokens, filter)
      assert is_list(matches)
      assert length(matches) == 1
      assert match?({:rule, {:rule, %LibJudge.Rule{type: :rule}, _, _}}, hd(matches))
    end

    property "rule_is only ever finds 0 or 1 matches",
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

    property "rule_is handles bad data gracefully",
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
