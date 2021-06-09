defmodule LibJudgeRuleTest do
  use ExUnit.Case, async: true
  use PropCheck
  import LibJudgeTest.Models.Rules
  doctest LibJudge.Rule

  @runs_per_test 5_000

  describe "rule parser" do
    property "produces the same output as input",
      detect_exceptions: true,
      numtests: @runs_per_test do
      forall rule_struct <- rule() do
        str = LibJudge.Rule.to_string!(rule_struct)
        {:ok, struct} = LibJudge.Rule.from_string(str)
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
            {:ok, %LibJudge.Rule{}} -> true
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
            {:ok, l} when is_list(l) ->
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
        {:ok, struct} = LibJudge.Rule.from_string(input)

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
        {:ok, out} = LibJudge.Rule.all_from_string(rules_str)
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
