# Main entry script
using Pkg
Pkg.activate(dirname(@__DIR__)) # Activate apps/api
# Pkg.instantiate() # Uncomment if needed on first run

push!(LOAD_PATH, joinpath(@__DIR__, "src"))

using Server

# Start
# For Docker, we might run this script.
# "julia --project=. src/run.jl"

Server.run_server()
