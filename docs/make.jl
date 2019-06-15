using Documenter, WizardsChess

makedocs(;
    modules=[WizardsChess],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/djsegal/WizardsChess.jl/blob/{commit}{path}#L{line}",
    sitename="WizardsChess.jl",
    authors="djsegal <dansegal2@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/djsegal/WizardsChess.jl",
)
