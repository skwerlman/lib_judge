System.cmd("wget", [
  "-t",
  "10",
  "-nc",
  "-O",
  "priv/data/MagicCompRules 20210224.txt",
  "https://media.wizards.com/2021/downloads/MagicCompRules%2020210224.txt"
])

ExUnit.start()
