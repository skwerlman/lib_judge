defmodule LibJudge.Rule do
  @moduledoc """
  Defines the `Rule` structure and provides methods for generating
  and working with them
  """
  @type rule_type :: :category | :subcategory | :rule | :subrule
  @type t :: %__MODULE__{
          category: String.t(),
          subcategory: String.t(),
          rule: String.t(),
          subrule: String.t(),
          type: rule_type()
        }
  defstruct [:category, :subcategory, :rule, :subrule, :type]

  @rule_regex ~r/\b[1-9](?:\d{2}(?:\.\d{1,3}(?:\-\d{1,3}|[a-z](?:\-[b-z])?)?\b|\.)?|\.)/

  @doc """
  Creates a `Rule` struct from a string

  ## Examples

      iex> LibJudge.Rule.from_string("702.21j")
      %LibJudge.Rule{type: :subrule, category: "7", subcategory: "02", rule: "21", subrule: "j"}
  """
  @spec from_string(String.t()) :: t | {:error, String.t()}
  def from_string(str) do
    opts = split(str)

    case opts do
      {:error, reason} -> {:error, reason}
      _ -> struct(__MODULE__, opts)
    end
  end

  @doc """
  Creates a list of `Rule`s referenced in a string

  ## Examples

      iex> LibJudge.Rule.all_from_string("See rules 702.21j and 702.108.")
      [
        %LibJudge.Rule{type: :subrule, category: "7", subcategory: "02", rule: "21", subrule: "j"},
        %LibJudge.Rule{type: :rule, category: "7", subcategory: "02", rule: "108", subrule: nil}
      ]
  """
  @spec all_from_string(String.t()) :: [t] | {:error, String.t()}
  def all_from_string(str) when is_binary(str) do
    # what the fuck wizards
    clean_str = String.replace(str, "–", "-")

    @rule_regex
    |> Regex.scan(clean_str)
    |> List.flatten()
    |> Enum.map(&from_string/1)
  end

  def all_from_string(_not_a_str) do
    {:error, "input is not a string"}
  end

  @doc """
  Turns a `Rule` back into a string

  ## Examples

      iex> LibJudge.Rule.to_string!(%LibJudge.Rule{type: :subrule, category: "7", subcategory: "02", rule: "21", subrule: "j"})
      "702.21j"
  """
  @spec to_string!(t()) :: String.t() | no_return
  def to_string!(rule) do
    case rule do
      %__MODULE__{
        type: :subrule,
        category: cat,
        subcategory: subcat,
        rule: rule,
        subrule: subrule
      } ->
        cat <> subcat <> "." <> rule <> subrule

      %__MODULE__{type: :rule, category: cat, subcategory: subcat, rule: rule} ->
        cat <> subcat <> "." <> rule <> "."

      %__MODULE__{type: :subcategory, category: cat, subcategory: subcat} ->
        cat <> subcat <> "."

      %__MODULE__{type: :category, category: cat} ->
        cat <> "."
    end
  end

  @doc """
  Turns a `Rule` back into a string

  Non-bang variant

  ## Examples

      iex> LibJudge.Rule.to_string(%LibJudge.Rule{type: :category, category: "1"})
      {:ok, "1."}
  """
  @spec to_string(t()) :: {:ok, String.t()} | {:error, reason :: any}
  def to_string(rule) do
    {:ok, to_string!(rule)}
  rescue
    ArgumentError -> {:error, {:invalid_rule, "missing properties for type"}}
    err -> {:error, err}
  end

  defp split(rule = <<cat::utf8, subcat_1::utf8, subcat_2::utf8>>)
       when cat in 48..57 and subcat_1 in 48..57 and subcat_2 in 48..57,
       do: split(rule <> ".")

  defp split(<<cat::utf8, ".">>) when cat in 48..57, do: [category: <<cat>>, type: :category]

  defp split(<<cat::utf8, subcat::binary-size(2), ".">>) when cat in 48..57,
    do: [category: <<cat>>, subcategory: <<subcat::binary>>, type: :subcategory]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1), ".">>)
       when cat in 48..57,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         type: :rule
       ]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2), ".">>)
       when cat in 48..57,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         type: :rule
       ]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3), ".">>)
       when cat in 48..57,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         type: :rule
       ]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1), subrule::utf8>>)
       when cat in 48..57 and subrule in 97..122,
       do: [
         category: <<cat>>,
         subcategory: subcat,
         rule: <<rule::binary>>,
         subrule: <<subrule>>,
         type: :subrule
       ]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2), subrule::utf8>>)
       when cat in 48..57 and subrule in 97..122,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         subrule: <<subrule>>,
         type: :subrule
       ]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3), subrule::utf8>>)
       when cat in 48..57 and subrule in 97..122,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         subrule: <<subrule>>,
         type: :subrule
       ]

  # these are a hack to make not-strictly-correct rule ids like
  # '205.1' (should be '205.1.') work to make this more friendly
  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(1)>>)
       when cat in 48..57,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         type: :rule
       ]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(2)>>)
       when cat in 48..57,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         type: :rule
       ]

  defp split(<<cat::utf8, subcat::binary-size(2), ".", rule::binary-size(3)>>)
       when cat in 48..57,
       do: [
         category: <<cat>>,
         subcategory: <<subcat::binary>>,
         rule: <<rule::binary>>,
         type: :rule
       ]

  defp split(str) do
    {:error, "invalid rule: #{inspect(str)}"}
  end
end
