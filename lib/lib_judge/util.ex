defmodule LibJudge.Util do
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
