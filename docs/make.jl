using Documenter, TeleMap

makedocs(
    modules = [TeleMap],
    format = :html,
    checkdocs = :exports,
    sitename = "TeleMap.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/nikpocuca/TeleMap.jl.git",
)
