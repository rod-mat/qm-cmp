# Main entry script
using Pkg
Pkg.activate(dirname(@__DIR__)) # Activate apps/api

# Include modules manually since they are not a package

module SolidStateStudioAPI

    # Utils
    include("Utils/CanonicalJSON.jl")
    include("Utils/Hashing.jl")
    include("Utils/Validation.jl")
    
    # Models
    include("Models/Schemas.jl")
    
    # Core
    include("Cache.jl")

    # Physics
    include("Physics/Crystal.jl")
    include("Physics/Diffraction.jl")
    include("Physics/TightBinding.jl")

    # App
    include("Routes.jl")
    include("Server.jl")

end

# Start
# For Docker, we might run this script.
# "julia --project=. src/run.jl"

SolidStateStudioAPI.Server.run_server()
