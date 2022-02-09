mutable struct GB
    # Length = number of loci
    chromosome::Array{Int64,1}
    bp::Array{Int64,1}
    cM::Array{Float64,1}
    maf::Array{Float64,1}
    effects::SparseMatrixCSC  # loci by traits
    effects_QTLs::SparseMatrixCSC  # qtls by traits
    is_QTLs::BitArray{1}

    # Length = number of chromosome
    n_loci_chr::Array{Int64,1}
    length_chr::Array{Float64,1} # Unit is Morgan (100 cM)
    idx_chr::Array{Int64,2} # chr by [start, end]

    # Scaler
    n_loci::Int64
    n_chr::Int64
    n_traits::Int64
    rate_mutation::Float64
    rate_error::Float64 # Genotyping error
    Vg::Array{Float64,2}
    Ve::Array{Float64,2}
    h2::Array{Float64,1}

    # Counter
    animals::Array{Animal,1}
    founders::Array{Animal,1}
    count_hap::Int64
    count_id::Int64

    # Others
    silent::Bool

    # Constructor
    GB() = new(Array{Int64}(undef, 0),
        Array{Int64}(undef, 0),
        Array{Float64}(undef, 0),
        Array{Float64}(undef, 0),
        spzeros(0),
        spzeros(0),
        Array{BitArray}(undef, 0),
        Array{Int64}(undef, 0),
        Array{Float64}(undef, 0),
        Array{Int64}(undef, 0, 0),
        0, 0, 0,
        0.0, 0.0,
        Array{Float64}(undef, 0, 0),
        Array{Float64}(undef, 0, 0),
        Array{Float64}(undef, 0),
        Array{Animal}(undef, 0),
        Array{Animal}(undef, 0),
        1, 1, false)
end

Base.show(io::IO, gb::GB) = ""


function CLEAR()
    global gb = GB()
    # LOG("XSim has been reset")
end

function SET(key::Any,
    value::Any)

    setfield!(gb, Symbol(key), value)

    if key == "chromosome"
        SET("n_loci_chr", [count(==(c), value) for c in unique(value)])
        SET("n_loci", length(value))
        SET("n_chr", length(unique(value)))
        # Index chromosome position
        idx_each_chr = [value .== c for c in 1:GLOBAL("n_chr")]
        SET("idx_chr", hcat(findfirst.(idx_each_chr), findlast.(idx_each_chr)))

    elseif key == "cM"
        chrs = GLOBAL("chromosome")
        SET("length_chr", [round(max(value[chrs.==c]...) / 100, digits = 3) for c in unique(chrs)])

    elseif key == "effects"
        SET("is_QTLs", sum(GLOBAL("effects"), dims = 2)[:, 1] .!= 0)
        SET("effects_QTLs", GLOBAL("effects")[GLOBAL("is_QTLs"), :])
    end
end

function GLOBAL(option::String = "";
    chromosome::Int64 = -1,
    locus::Int64 = -1)

    if option == "n_loci" && chromosome != -1
        return getfield(gb, Symbol("n_loci_chr"))[chromosome]

    elseif option == "length_chr" && chromosome != -1
        return getfield(gb, Symbol("length_chr"))[chromosome]

    elseif chromosome != -1 && locus != -1
        return get_loci(chromosome, locus, option)

    elseif chromosome != -1
        return get_loci(chromosome, option)

    elseif option == "effects_QTLs"
        return Array(getfield(gb, Symbol(option)))

    elseif option == ""
        LOG("Available options are: ['chromosome', 'bp', 'cM', 'maf',
                               'effects', 'effects_QTLs', 'is_QTLs', 'animals',
                               'n_loci_chr', 'length_chr', 'idx_chr', 'n_loci',
                               'n_chr', 'n_traits', 'rate_mutation', 'rate_error',
                               'Vg', 'Ve', 'h2', 'error']", "error")

    else
        return getfield(gb, Symbol(option))
    end
end


function LOG(msg::String = "",
    option::String = "info";
    silent::Bool = GLOBAL("silent"))

    if !silent
        signiture = ""
        if option == "info"
            # @info "$signiture$msg"
            println("$signiture$msg")

        elseif option == "warn"
            @warn "$signiture$msg"

        elseif option == "error"
            error("$signiture$msg")

        end
    end
end

function SILENT(is_on::Bool = false)
    SET("silent", is_on)
    status = is_on ? "ON" : "OFF"
    # @info "The silent mode is $status"
end


```Return info of specific loci```
function get_loci(chromosome::Int64, loci::Int64, option::String = "bp")
    return get_loci(chromosome, option)[loci]
end

```Return info of all loci on the chromosome```
function get_loci(chromosome::Int64, option::String = "bp")
    idx_starts = GLOBAL("idx_chr")[chromosome, 1]
    idx_ends = GLOBAL("idx_chr")[chromosome, 2]
    return GLOBAL(option)[idx_starts:idx_ends]
end

function add_count_ID!(; by::Int64 = 1)
    gb.count_id += by
end

function add_count_haplotype!(; by::Int64 = 1)
    gb.count_hap += by
end

function add_animal!(animal::Animal)
    push!(gb.animals, animal)
end

function add_founders!(animal::Animal)
    push!(gb.founders, animal)
end

function GET_LINES(ids::Array)
    try
        ids = parse.(Int, ids)
    catch
        # Will be failed if ids are integers already
        nothing
    end
    ANIMALS = GLOBAL("animals")
    return Cohort([animal for animal in ANIMALS if animal.ID in ids])
end

function IS_EXIST(id::Int)
    return length(GET_LINES([id])) != 0
end

```Turn 1-D n-size vector, or a scaler to 2-D vector with dimension of n by 1```
function matrix(inputs::Any; is_sparse = false)
    mat = hcat(Diagonal([inputs])...)
    if is_sparse
        return sparse(mat)
    else
        return mat
    end
end

function handle_diagonal(inputs::Union{Array,Float64,Int64},
    n_traits::Int64)

    # Cast variants of variances to a 2-D array
    # Case 1 When variances is a scaler, assign it as the diagonal of variances
    # if !isa(inputs, Array)
    if length(inputs) == 1
        inputs = diagm(fill(inputs[1], n_traits)) # [1] handle length 1 vector
    else
        inputs = matrix(inputs)
        # Case 2 When variances is a vector, assign it as the diagonal of variances
        if size(inputs)[2] == 1
            inputs = diagm(inputs[:, 1])
        end
    end

    if size(inputs)[2] != n_traits
        LOG("Dimensions don't match between n_traits and variances/h2", "error")
    end

    return inputs
end

function get_Vg(QTL_effects::Union{Array{Float64,2},SparseMatrixCSC},
    QTL_freq::Array{Float64,1})

    # 2pq
    D = diagm(2 * QTL_freq .* (1 .- QTL_freq))

    # 2pq*alpha^2
    Vg = QTL_effects'D * QTL_effects

    return Vg
end


function get_Ve(n_traits::Int64,
    Vg::Union{Array{Float64},Float64},
    h2::Union{Array{Float64},Float64} = 0.5)

    h2 = handle_h2(h2, n_traits)
    Vg = handle_diagonal(Vg, n_traits)

    Ve = ((ones(n_traits) .- h2) .* diag(Vg)) ./ h2 # diagm can't handle 2x2 matrix
    Ve = n_traits == 1 ? Ve[1] : Ve

    return handle_diagonal(Ve, n_traits)
end

function infer_variances(v_src,
    n_traits::Int64;
    h2,
    term_src::String,
    term_out::String = "optional")

    h2 = handle_h2(h2, n_traits)
    v_src = handle_diagonal(v_src, n_traits)

    if term_src == "vg"
        # out must be ve
        # g->e: e = (1 - h2) g / h2
        v_out = ((ones(n_traits) .- h2) .* diag(v_src)) ./ h2

    elseif term_src == "ve"
        # out must be vg
        # e->g: g = e * h2 / (1 - h2)
        v_out = (diag(v_src) .* h2) ./ (ones(n_traits) .- h2)

    elseif term_src == "vp"
        # out must be vg
        # p->g: g = p * h2
        v_out = diag(v_src) .* h2
    end

    v_out = n_traits == 1 ? v_out[1] : v_out

    return handle_diagonal(v_out, n_traits)
end

function handle_h2(h2, n_traits)
    # turn scaler h2 to a vector if multi-trait
    if n_traits > 1 && !isa(h2, Array)
        h2 = fill(h2, n_traits)
    end
    # avoid inf variance when h2 = 0
    is_zeros = h2 .== 0
    if n_traits > 1
        h2[is_zeros] .= 1e-5
    elseif is_zeros == true # single trait and vg == 0
        h2[is_zeros] = 1e-5
    end
    # return
    return h2
end


function scale_effects(QTL_effects::Union{Array{Float64,2},SparseMatrixCSC},
    QTL_freq::Array{Float64,1},
    Vg_goal::Array;
    is_sparse::Bool = false)

    # Compute Vg for input QTL_effects
    Vg_ori = get_Vg(QTL_effects, QTL_freq)

    # Decompose original variance
    Vg_ori_U = cholesky(Vg_ori).U'
    Vg_ori_Ui = inv(Vg_ori_U)

    # Decompose goal variance
    Vg_goal_U = cholesky(Vg_goal).U

    # m by t = m by t * t by t
    QTL_effects_scaled = QTL_effects * Vg_ori_Ui'Vg_goal_U

    return is_sparse ? sparse(QTL_effects_scaled) : QTL_effects_scaled
end

function get_MAF(array::Array)
    freq = sum(array, dims = 1) / (2 * size(array, 1))
    maf = min.(freq, 1 .- freq)
    return round.(vcat(maf...), digits = 3)
end

function uni_01(arr::Array)
    num = arr .- min(arr...)
    det = max(arr...) - min(arr...)
    return num / det
end


# --- --- --- PRELOADED DATA --- --- ---
function DATA(filename::String = ""; header::Bool = true)
    if filename in ["genotypes", "haplotypes", "pedigree", "maize_snp"]
        header = false
    end

    try
        return CSV.read(PATH(filename), DataFrame, header = header)

    catch e
        # hint users for available options
        PATH()
    end

end

function PATH(filename::String = "")
    root = dirname(dirname(pathof(XSim)))

    if filename == "genotypes"
        return joinpath(root, "data", "demo_genotypes.csv")
    
    elseif filename == "haplotypes"
        return joinpath(root, "data", "demo_haplotypes.csv")
    
    elseif filename == "map"
        return joinpath(root, "data", "demo_map.csv")
    
    elseif filename == "pedigree"
        return joinpath(root, "data", "demo_pedigree.csv")
    
        # maize data
    elseif filename == "maize_snp"
        return joinpath(root, "data", "demo_maize_snp.csv")
    
    elseif filename == "maize_map"
        return joinpath(root, "data", "demo_maize_map.csv")
    
    else
        LOG("The available options are: ['genotypes', 'haplotypes', 'map', 'pedigree', 'maize_snp', 'maize_map']", "error")
        return nothing
    end
end
# --- --- --- --- --- --- --- --- ---


# function subset_dict(dict::Dict, subsets::Array)
#     k = collect(keys(dict))
#     v = collect(values(dict))

#     idx_subset = findall(in(subsets), k)
#     return Dict(k[i] => v[i] for i in idx_subset)
# end

# function make_silent(obj::Any)
#     args = convert(Dict, obj)
#     args["silent"] = true
#     return args
# end

