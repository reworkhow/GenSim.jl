module XSim
    using Base: String
    using CSV: schematype
    using Distributions
    using DataFrames
    using CSV
    using Random
    using JWAS
    using Printf
    using LinearAlgebra
    using SparseArrays
    using StatsBase

    import Base.length
    import Base.getindex
    import Base.print
    import StatsBase.sample
    import StatsBase.mean
    import StatsBase.var

    tempPos = Array{Float64}(undef, 100000)
    tempOri = Array{Int64}(undef, 100000)
    tempMut = Array{Float64}(undef, 100000)

    const AlleleIndexType = Int64

    # Objects
    include("objects/chromosome.jl")
    include("objects/animal.jl")
    include("objects/cohort.jl")
    include("objects/global.jl")
    # Core functions
    include("core/build.jl")
    include("core/build_genome.jl")
    include("core/build_phenome.jl")
    include("core/genome.jl")
    include("core/mate.jl")
    include("core/select.jl")
    include("core/genetic_evaluation.jl")
    # Interface
    include("interface/interface.jl")

    # Initialize global
    gb = GB()
    # CLEAR()

    export Chromosome, Animal, Cohort, Founders
    # Getters
    export get_BVs, get_phenotypes, get_genotypes,
           get_QTLs,
           get_IDs, get_pedigree, get_DH
    export get_Vg, get_MAF, scale_effects
    export genetic_evaluation, GBLUP
    # Global
    export CLEAR, SET, GLOBAL, LOG, SILENT, DATA, PATH, GLobal, gb
    # Build
    export build, build_genome, build_phenome, build_demo, build_demo_small
    # Summary
    export summary, summary_genome, summary_phenome
    # Core
    export mate, select
    # Interface
    export breed, sample_select, sample_random,
           random_mate, self_mate, all_mate, embryo_transfer
    XSim.LOG("--- --- --- XSim v2.0.0002 --- --- --- ")
    XSim.LOG("Last update: Aug 15, 2021")
    XSim.LOG("User manual: https://reworkhow.github.io/XSim.jl")

end

    # Chromosome code. PLINK 1.9 also permits contig names here, but most older programs do not.
# Variant identifier
# Position in morgans or centimorgans (optional; also safe to use dummy value of '0')
# Base-pair coordinate