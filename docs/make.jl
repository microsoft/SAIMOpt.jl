# see documentation at https://juliadocs.github.io/Documenter.jl/stable/

using Documenter, SAIMOpt

makedocs(
    modules = [SAIMOpt],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Christos Gkantsidis (chrisgk), Pedro Maciel Xavier (t-pedroma)",
    sitename = "SAIMOpt.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

# Some setup is needed for documentation deployment, see “Hosting Documentation” and
# deploydocs() in the Documenter manual for more information.
# TODO: Check whether the following makes sense and can work.
deploydocs(
    repo = "msr-optics@dev.azure.com/msr-optics/OpticalCompute/_git/SAIMOpt.jl",
    push_preview = true
)
