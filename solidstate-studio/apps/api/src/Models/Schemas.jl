module Schemas

using StaticArrays
using StructTypes

# --- Basic Types ---
const Vector3 = SVector{3, Float64}
const Matrix3 = SMatrix{3, 3, Float64, 9}

export Vector3, Matrix3
export LatticeParams, BasisAtom, ReciprocalParams, PlaneParams, CrystalBuildRequest
export RealCell, RecipCell, AtomsData, MeshData, PlaneData, MetaData, CrystalBuildResponse
export CrystalInput, BeamInput, DetectorInput, IntensityInput, EwaldRequest, SpotData, EwaldMeta, EwaldResponse
export TBModelParams, KPoint, KPathParams, DOSParams, TBRequest, LabelData, DOSResult, TBMeta, TBResponse

# --- Crystal Builder ---

struct LatticeParams
    kind::String
    a::Float64
    b::Union{Float64, Nothing}
    c::Union{Float64, Nothing}
    alpha::Union{Float64, Nothing}
    beta::Union{Float64, Nothing}
    gamma::Union{Float64, Nothing}
    A::Union{Matrix3, Nothing}
end
StructTypes.StructType(::Type{LatticeParams}) = StructTypes.Struct()

struct BasisAtom
    element::String
    frac::Vector3
    magmom::Union{Float64, Nothing}
end
StructTypes.StructType(::Type{BasisAtom}) = StructTypes.Struct()

struct ReciprocalParams
    gMax::Float64
end
StructTypes.StructType(::Type{ReciprocalParams}) = StructTypes.Struct()

struct PlaneParams
    h::Int
    k::Int
    l::Int
    offset::Union{Float64, Nothing}
    size::Union{Float64, Nothing}
end
StructTypes.StructType(::Type{PlaneParams}) = StructTypes.Struct()

struct CrystalBuildRequest
    lattice::LatticeParams
    basis::Vector{BasisAtom}
    supercell::SVector{3, Int}
    reciprocal::Union{ReciprocalParams, Nothing}
    planes::Union{Vector{PlaneParams}, Nothing}
end
StructTypes.StructType(::Type{CrystalBuildRequest}) = StructTypes.Struct()

# Responses
struct RealCell
    A::Matrix3
    origin::Vector3
end
StructTypes.StructType(::Type{RealCell}) = StructTypes.Struct()

struct RecipCell
    B::Matrix3
    gPoints::Vector{Vector3}
    gHKL::Vector{SVector{3, Int}}
end
StructTypes.StructType(::Type{RecipCell}) = StructTypes.Struct()

struct AtomsData
    positions::Vector{Vector3}
    elements::Vector{String}
    frac::Vector{Vector3}
end
StructTypes.StructType(::Type{AtomsData}) = StructTypes.Struct()

struct MeshData
    vertices::Vector{Vector3}
    faces::Vector{SVector{3, Int}}
end
StructTypes.StructType(::Type{MeshData}) = StructTypes.Struct()

struct PlaneData
    hkl::SVector{3, Int}
    normal::Vector3
    mesh::MeshData
end
StructTypes.StructType(::Type{PlaneData}) = StructTypes.Struct()

struct MetaData
    requestHash::String
    warnings::Vector{String}
end
StructTypes.StructType(::Type{MetaData}) = StructTypes.Struct()

struct CrystalBuildResponse
    real::RealCell
    recip::RecipCell
    atoms::AtomsData
    planes::Union{Vector{PlaneData}, Nothing}
    meta::MetaData
end
StructTypes.StructType(::Type{CrystalBuildResponse}) = StructTypes.Struct()


# --- Ewald ---

struct CrystalInput
    B::Matrix3
    gPoints::Vector{Vector3}
    gHKL::Vector{SVector{3, Int}}
end
StructTypes.StructType(::Type{CrystalInput}) = StructTypes.Struct()

struct BeamInput
    lambda::Float64
    kInDir::Vector3
    orientation::Union{Matrix3, Nothing}
end
StructTypes.StructType(::Type{BeamInput}) = StructTypes.Struct()

struct DetectorInput
    distance::Float64
    normal::Vector3
    up::Vector3
    width::Float64
    height::Float64
end
StructTypes.StructType(::Type{DetectorInput}) = StructTypes.Struct()

struct IntensityInput
    model::String
    sigma::Union{Float64, Nothing}
end
StructTypes.StructType(::Type{IntensityInput}) = StructTypes.Struct()

struct EwaldRequest
    crystal::CrystalInput
    beam::BeamInput
    detector::DetectorInput
    intensity::IntensityInput
end
StructTypes.StructType(::Type{EwaldRequest}) = StructTypes.Struct()

struct SpotData
    hkl::SVector{3, Int}
    Q::Vector3
    kOutDir::Vector3
    uv::SVector{2, Float64}
    intensity::Float64
end
StructTypes.StructType(::Type{SpotData}) = StructTypes.Struct()

struct EwaldMeta
    requestHash::String
    nTested::Int
end
StructTypes.StructType(::Type{EwaldMeta}) = StructTypes.Struct()

struct EwaldResponse
    spots::Vector{SpotData}
    meta::EwaldMeta
end
StructTypes.StructType(::Type{EwaldResponse}) = StructTypes.Struct()


# --- Tight Binding ---

struct TBModelParams
    lattice::String
    params::Dict{String, Float64}
end
StructTypes.StructType(::Type{TBModelParams}) = StructTypes.Struct()

struct KPoint
    label::String
    k::Vector3
end
StructTypes.StructType(::Type{KPoint}) = StructTypes.Struct()

struct KPathParams
    points::Vector{KPoint}
    nPerSegment::Int
end
StructTypes.StructType(::Type{KPathParams}) = StructTypes.Struct()

struct DOSParams
    enabled::Bool
    nE::Int
    eta::Float64
    eMin::Union{Float64, Nothing}
    eMax::Union{Float64, Nothing}
end
StructTypes.StructType(::Type{DOSParams}) = StructTypes.Struct()

struct TBRequest
    model::TBModelParams
    kpath::KPathParams
    dos::DOSParams
end
StructTypes.StructType(::Type{TBRequest}) = StructTypes.Struct()

struct LabelData
    atIndex::Int
    label::String
end
StructTypes.StructType(::Type{LabelData}) = StructTypes.Struct()

struct DOSResult
    E::Vector{Float64}
    g::Vector{Float64}
end
StructTypes.StructType(::Type{DOSResult}) = StructTypes.Struct()

struct TBMeta
    requestHash::String
end
StructTypes.StructType(::Type{TBMeta}) = StructTypes.Struct()

struct TBResponse
    k::Vector{Float64}
    labels::Vector{LabelData}
    bands::Vector{Vector{Float64}}
    dos::Union{DOSResult, Nothing}
    meta::TBMeta
end
StructTypes.StructType(::Type{TBResponse}) = StructTypes.Struct()

end # module
