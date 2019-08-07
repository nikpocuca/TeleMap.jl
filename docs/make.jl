using Documenter, TeleMap, Dates
push!(LOAD_PATH,"../src/")

makedocs(
    modules = [TeleMap],
    format = Documenter.HTML(),
    checkdocs = :exports,
    sitename = "TeleMap.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/nikpocuca/TeleMap.jl.git",
)
