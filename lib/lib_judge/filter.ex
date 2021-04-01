defmodule LibJudge.Filter do
  @moduledoc """
  A collection of filters to do common searches on rules.

  Each filter returns a single-argument function designed to be
  used with `Enum.filter/2`
  """
  alias LibJudge.Rule
  alias LibJudge.Tokenizer
  require Logger

  @spec rule_starts_with(binary) :: (Tokenizer.rule() -> boolean)
  def rule_starts_with(prefix) do
    fn
      {:rule, {_, rule, _, _}} ->
        rule
        |> Rule.to_string()
        |> case do
          {:ok, string} -> String.starts_with?(string, prefix)
          _ -> false
        end

      _ ->
        false
    end
  end

  @spec rule_type(Rule.rule_type()) :: (Tokenizer.rule() -> boolean)
  def rule_type(type) do
    fn
      {:rule, {^type, %Rule{type: ^type}, _, _}} -> true
      _ -> false
    end
  end

  @spec has_examples() :: (Tokenizer.rule() -> boolean)
  def has_examples do
    fn
      {:rule, {_, _, _, [_]}} -> true
      _ -> false
    end
  end

  @spec body_matches(Regex.t()) :: (Tokenizer.rule() -> boolean)
  def body_matches(regex) do
    fn
      {_, {_, _, body, _}} -> Regex.match?(regex, body)
      _ -> false
    end
  end

  @spec rule_matches(Regex.t()) :: (Tokenizer.rule() -> boolean)
  def rule_matches(regex) do
    fn
      {_, {_, rule, _, _}} -> Regex.match?(regex, rule)
      _ -> false
    end
  end

  @spec example_matches(Regex.t()) :: (Tokenizer.rule() -> boolean)
  def example_matches(regex) do
    fn
      {_, {_, _, _, examples}} ->
        Enum.reduce(examples, false, fn x, acc -> Regex.match?(regex, x) || acc end)

      _ ->
        false
    end
  end
end
