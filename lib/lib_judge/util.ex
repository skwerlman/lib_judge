defmodule LibJudge.Util do
  @moduledoc """
  A collection of utilities used inside lib_judge.
  """

  @doc """
  Maps a month or number string into a number.

  This only converts months when they form the full length of the string,
  because it assumes you have split on whitespace before calling.

  Non-month strings are converted using `Integer.parse/1`

  ## Examples

      iex> LibJudge.Util.date_map("December")
      12
      iex> LibJudge.Util.date_map("37")
      37
      iex> LibJudge.Util.date_map("15 December")
      15
  """
  @spec date_map(binary) :: integer
  def date_map("January"), do: 1
  def date_map("February"), do: 2
  def date_map("March"), do: 3
  def date_map("April"), do: 4
  def date_map("May"), do: 5
  def date_map("June"), do: 6
  def date_map("July"), do: 7
  def date_map("August"), do: 8
  def date_map("September"), do: 9
  def date_map("October"), do: 10
  def date_map("November"), do: 11
  def date_map("December"), do: 12

  def date_map(str) do
    {num, _} = Integer.parse(str)
    num
  end
end
