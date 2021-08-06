System.cmd(
  "wget",
  [
    "-t",
    "10",
    "-nc",
    "-O",
    "priv/data/MagicCompRules 20210224.txt",
    "https://media.wizards.com/2021/downloads/MagicCompRules%2020210224.txt"
  ],
  env: %{}
)

System.cmd(
  "wget",
  [
    "-t",
    "10",
    "-nc",
    "-O",
    "priv/data/MagicCompRules 20210712.txt",
    "https://media.wizards.com/2021/downloads/MagicCompRules%2020210712.txt"
  ],
  env: %{}
)

ExUnit.start(capture_log: true)
