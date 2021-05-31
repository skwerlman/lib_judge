defmodule LibJudgeRuleTest do
  use ExUnit.Case, async: true
  use PropCheck
  doctest LibJudge.Rule

  @runs_per_test 5_000

  defp rule_type do
    let type <- oneof([:category, :subcategory, :rule, :subrule]) do
      type
    end
  end

  defp subrule_letter do
    let char <- choose(0x61, 0x7A) do
      to_string([char])
    end
  end

  defp long_subrule_letter do
    let [
      letter <- subrule_letter(),
      letter2 <- subrule_letter()
    ] do
      letter <> letter2
    end
  end

  defp rule do
    let [
      cat <- integer(1, 9),
      subcat <- integer(0, 99),
      rule <- integer(1, 999),
      subrule <- subrule_letter(),
      type <- rule_type()
    ] do
      case type do
        :category ->
          %LibJudge.Rule{
            type: :category,
            category: to_string(cat),
            subcategory: nil,
            rule: nil,
            subrule: nil
          }

        :subcategory ->
          %LibJudge.Rule{
            type: :subcategory,
            category: to_string(cat),
            subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
            rule: nil,
            subrule: nil
          }

        :rule ->
          %LibJudge.Rule{
            type: :rule,
            category: to_string(cat),
            subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
            rule: to_string(rule),
            subrule: nil
          }

        :subrule ->
          %LibJudge.Rule{
            type: :subrule,
            category: to_string(cat),
            subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
            rule: to_string(rule),
            subrule: subrule
          }
      end
    end
  end

  defp long_subrule do
    let [
      cat <- integer(1, 9),
      subcat <- integer(0, 99),
      rule <- integer(1, 999),
      subrule <- long_subrule_letter()
    ] do
      %LibJudge.Rule{
        type: :subrule,
        category: to_string(cat),
        subcategory: subcat |> to_string() |> String.pad_leading(2, "0"),
        rule: to_string(rule),
        subrule: subrule
      }
    end
  end

  defp maybe_bad_rule do
    let [
      cat <- oneof([integer(1, 9), exactly(nil)]),
      subcat <- oneof([integer(0, 99), exactly(nil)]),
      rule <- oneof([integer(1, 999), exactly(nil)]),
      subrule <- oneof([subrule_letter(), long_subrule_letter(), exactly(nil)]),
      type <- oneof([rule_type(), exactly(nil)])
    ] do
      pcat =
        if cat do
          to_string(cat)
        end

      psubcat =
        if subcat do
          subcat
          |> to_string()
          |> String.pad_leading(2, "0")
        end

      prule =
        if rule do
          to_string(rule)
        end

      %LibJudge.Rule{
        type: type,
        category: pcat,
        subcategory: psubcat,
        rule: prule,
        subrule: subrule
      }
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

  defp long_subrule_str do
    let [
      cat <- integer(1, 9),
      sc1 <- integer(0, 9),
      sc2 <- integer(0, 9),
      rule <- integer(1, 999),
      subrule <- subrule_letter(),
      subrule2 <- subrule_letter()
    ] do
      {to_string(cat) <>
         to_string(sc1) <>
         to_string(sc2) <>
         "." <>
         to_string(rule) <>
         subrule <>
         subrule2, :subrule}
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

  defp many_rules do
    let l <- list(any_rule_str()) do
      {rules, types} = Enum.unzip(l)
      {Enum.join(rules, " "), types}
    end
  end

  describe "rule parser" do
    property "produces the same output as input",
      detect_exceptions: true,
      numtests: @runs_per_test do
      forall rule_struct <- rule() do
        str = LibJudge.Rule.to_string!(rule_struct)
        struct = LibJudge.Rule.from_string(str)
        equals(rule_struct, struct)
      end
    end

    property "rejects invalid subrules in rule structs",
      detect_exceptions: true,
      numtests: @runs_per_test do
      trap_exit(
        forall rule_struct <- long_subrule() do
          assert match?({:error, _}, LibJudge.Rule.to_string(rule_struct))
          {:error, error} = LibJudge.Rule.to_string(rule_struct)
          assert match?(%LibJudge.Rule.InvalidPartError{}, error)
        end
      )
    end

    property "rejects invalid subrules in rule strings",
      detect_exceptions: true,
      numtests: @runs_per_test do
      trap_exit(
        forall {rule_string, _type} <- long_subrule_str() do
          assert match?({:error, _}, LibJudge.Rule.from_string(rule_string))
          {:error, error} = LibJudge.Rule.from_string(rule_string)

          case error do
            err when is_binary(err) ->
              assert String.contains?(err, rule_string)

            err = %LibJudge.Rule.InvalidPartError{} ->
              assert err.part in [:rule, :subrule]
              assert String.contains?(rule_string, err.value)
          end
        end
      )
    end
  end

  describe "function" do
    property "from_string never explodes", detect_exceptions: true, numtests: @runs_per_test do
      trap_exit(
        forall input <- term() do
          case LibJudge.Rule.from_string(input) do
            %LibJudge.Rule{} -> true
            {:error, _reason} -> true
            _ -> false
          end
        end
      )
    end

    property "all_from_string never explodes", detect_exceptions: true, numtests: @runs_per_test do
      trap_exit(
        forall input <- term() do
          case LibJudge.Rule.all_from_string(input) do
            l when is_list(l) ->
              Enum.reduce(l, true, fn x, acc ->
                case x do
                  %LibJudge.Rule{} -> true
                  _ -> false
                end && acc
              end)

            {:error, _reason} ->
              true

            _ ->
              false
          end
        end
      )
    end

    property "to_string never explodes", detect_exceptions: true, numtests: @runs_per_test do
      trap_exit(
        forall input <- term() do
          case LibJudge.Rule.to_string(input) do
            {:ok, str} when is_binary(str) -> true
            {:error, _reason} -> true
            _ -> false
          end
        end
      )
    end

    property "to_string handles malformed %Rule{}s",
      detect_exceptions: true,
      numtests: @runs_per_test do
      trap_exit(
        forall input <- maybe_bad_rule() do
          case LibJudge.Rule.to_string(input) do
            {:ok, str} when is_binary(str) -> true
            {:error, _reason} -> true
            _ -> false
          end
        end
      )
    end

    property "from_string identifies rules correctly",
      detect_exceptions: true,
      numtests: @runs_per_test do
      forall {input, type} <- any_rule_str() do
        struct = LibJudge.Rule.from_string(input)

        case struct do
          %LibJudge.Rule{type: t} ->
            t == type

          _ ->
            false
        end
      end
    end

    property "all_from_string handles many rules",
      detect_exceptions: true,
      numtests: @runs_per_test do
      forall {rules_str, types} <- many_rules() do
        out = LibJudge.Rule.all_from_string(rules_str)
        assert length(out) == length(types)
        zipped = Enum.zip(out, types)

        Enum.reduce(zipped, true, fn {rule, type}, acc ->
          case rule do
            %LibJudge.Rule{type: t} ->
              t == type

            _ ->
              false
          end && acc
        end)
      end
    end
  end
end
