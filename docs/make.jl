using Documenter, Checkmate

makedocs(;
    modules=[Checkmate],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/djsegal/Checkmate.jl/blob/{commit}{path}#L{line}",
    sitename="Checkmate.jl",
    authors="djsegal <dansegal2@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/djsegal/Checkmate.jl",
)
