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

  @rule_regex ~r/\b\d{3}(?:\.\d{1,3}(?:\-\d{1,3}|[a-z](?:\-[b-z])?)?)?\b/

  @doc """
  Creates a `Rule` struct from a string
  """
  @spec from_string(String.t()) :: t
  def from_string(str) do
    opts = split(str)

    struct(__MODULE__, opts)
  end

  @doc """
  Creates a list of `Rule`s referenced in a string
  """
  @spec all_from_string(String.t()) :: [t]
  def all_from_string(str) do
    # what the fuck wizards
    clean_str = String.replace(str, "–", "-")

    @rule_regex
    |> Regex.scan(clean_str)
    |> List.flatten()
    |> Enum.map(&from_string/1)
  end

  @doc """
  Turns a `Rule` back into a string
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
      }
      when cat != nil and subcat != nil and rule != nil and subrule != nil ->
        cat <> subcat <> "." <> rule <> subrule

      %__MODULE__{type: :rule, category: cat, subcategory: subcat, rule: rule}
      when cat != nil and subcat != nil and rule != nil ->
        cat <> subcat <> "." <> rule <> "."

      %__MODULE__{type: :subcategory, category: cat, subcategory: subcat}
      when cat != nil and subcat != nil ->
        cat <> subcat <> "."

      %__MODULE__{type: :category, category: cat}
      when cat != nil ->
        cat <> "."
    end
  end

  @doc """
  Turns a `Rule` back into a string

  Non-bang variant
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
end
