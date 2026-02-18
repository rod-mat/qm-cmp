# Main entry script
using Pkg
Pkg.activate(dirname(@__DIR__)) # Activate apps/api

# Include modules manually since they are not a package

module SolidStateStudioAPI

    # 1. Models (Base dependency)
    # Wrap in Models module because Schemas.jl defines 'module Schemas'
    # and other files expect 'Models.Schemas'.
    module Models
        include("Models/Schemas.jl")
    end

    # 2. Core (Cache)
    include("Cache.jl")

    # 3. Utils
    module Utils
        # Shim: Make Models available here so '..Models' works in submodules
        using ..Models
        # Cache usually not used by Utils, but if needed:
        using ..Cache

        include("Utils/CanonicalJSON.jl")
        include("Utils/Hashing.jl")
        include("Utils/Validation.jl")
    end

    # 4. Physics
    module Physics
        # Shim: Make Models available here
        using ..Models
        
        include("Physics/Crystal.jl")
        include("Physics/Diffraction.jl")
        include("Physics/TightBinding.jl")
    end

    # 5. App (Routes & Server)
    # These are top-level within SolidStateStudioAPI, so they can see
    # Models, Utils, Physics, Cache directly via '..' (which is SolidStateStudioAPI).
    include("Routes.jl")
    include("Server.jl")

end

# Start
# For Docker, we might run this script.
# "julia --project=. src/run.jl"

SolidStateStudioAPI.Server.run_server()
