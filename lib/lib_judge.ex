defmodule LibJudge do
  @moduledoc """
  Documentation for `LibJudge`.
  """
  use Application

  defdelegate get(version), to: LibJudge.Versions

  defdelegate tokenize(text), to: LibJudge.Tokenizer

  @spec start(any, any) :: {:error, any} | {:ok, pid}
  def start(_type, _args) do
    opts = [
      strategy: :one_for_one
    ]

    children = []
    Supervisor.start_link(children, opts)
  end
end
