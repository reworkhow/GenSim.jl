# XSim.jl

Documentation for XSim.jl

!!! tip "New Users"
    New users are strongly encouraged to read the page [Demo: Step by Step](@ref) first.

## Features

- Efficient CPOS algorithm
- Founders characterized by real genome sequence data
- Complicated pedigree structures among descendants
- Strong extensibilty
- Modularism design
- Straightforward interface

## Installation
```jldoctest
julia> using Pkg
julia> Pkg.add("XSim")
```
or the beta version
```jldoctest
julia> Pkg.add(PackageSpec(name="XSim", rev="master"))
```

## Outline
```@contents
Pages = [
    "demo.md",
    "core/build_genome.md",
    "core/build_phenome.md",
    "core/cohort.md,
    "core/mate.md,
    "core/select.md,
    "core/breed.md,
    "core/GE.md",
    "case/crossbreed.md",
    "case/NAM.md",
]
Depth = 2
```

## Library
```@index
Pages = ["lib.md"]
```

## Cite XSimV2
```BibTex
@article{cheng_xsim_2015,
	title = {XSim: Simulation of Descendants from Ancestors with Sequence Data},
	volume = {5},
	issn = {2160-1836},
	shorttitle = {XSim},
	url = {http://g3journal.org/lookup/doi/10.1534/g3.115.016683},
	doi = {10.1534/g3.115.016683},
	language = {en},
	number = {7},
	journal = {G3\&amp;\#58; Genes{\textbar}Genomes{\textbar}Genetics},
	author = {Cheng, Hao and Garrick, Dorian and Fernando, Rohan},
	month = jul,
	year = {2015},
	pages = {1415--1417},
}
```
