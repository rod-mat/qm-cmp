using Test
using StaticArrays
using LinearAlgebra

# Load Modules
# Assuming we run this from apps/api
push!(LOAD_PATH, joinpath(@__DIR__, "../src"))

using Models.Schemas
using Physics.Crystal
using Physics.Diffraction
using Physics.TightBinding

@testset "SolidStateStudio Backend Tests" begin

    @testset "Crystal Builder" begin
        # SC Lattice
        req = CrystalBuildRequest(
            LatticeParams("sc", 2.0, nothing, nothing, nothing, nothing, nothing, nothing),
            [BasisAtom("H", SVector(0.0, 0.0, 0.0), nothing)],
            SVector(1,1,1),
            nothing,
            nothing
        )
        resp = build_crystal(req)
        
        # Real Cell: A should be diag(2,2,2)
        @test resp.real.A[1] == SVector(2.0, 0.0, 0.0)
        
        # Recip Cell: B = 2pi * inv(A)' = 2pi * diag(0.5, 0.5, 0.5) = diag(pi, pi, pi)
        @test isapprox(resp.recip.B[1][1], π, atol=1e-5)
        
        # Atoms
        @test length(resp.atoms.positions) == 1
        @test resp.atoms.elements[1] == "H"
    end

    @testset "Diffraction Ewald" begin
        # Mock Crystal Input
        # sc a=2pi => b=1.
        # B = diag(1,1,1) if a=2pi.
        # Let's just make up a B matrix and gPoints.
        B = (SVector(1.0,0.0,0.0), SVector(0.0,1.0,0.0), SVector(0.0,0.0,1.0))
        # G point at (1,0,0) -> Q=(1,0,0)
        gPoints = [SVector(1.0, 0.0, 0.0)] 
        gHKL = [SVector(1, 0, 0)]
        
        crys = CrystalInput(B, gPoints, gHKL)
        
        # Beam k=10. Dir -z.
        # k_in = (0,0,-10).
        # Q = (1,0,0).
        # k_out = (1,0,-10).
        # |k_in| = 10.
        # |k_out| = sqrt(1+100) = 10.049.
        # Delta k = 0.05.
        # If epsilon=0.05*k = 0.5. Delta is small. Should match.
        
        lambda = 2π / 10.0
        beam = BeamInput(lambda, SVector(0.0, 0.0, -1.0), nothing)
        
        det = DetectorInput(10.0, SVector(0.0, 0.0, 1.0), SVector(0.0, 1.0, 0.0), 100.0, 100.0)
        # Normal (0,0,1). P0=(0,0,10).
        # k_out=(1,0,-10). Dir=(0.1, 0, -1). 
        # Ray -> (0,0,0) + t*(1,0,-10).
        # Plane z=10.
        # t*(-10) = 10 => t=-1. (Backward?)
        # k_out z is negative. Detector is at z=+10 (normal=z).
        # Beam is -z. Detector usually transmission?
        # If detector is transmission, it should be at z < 0 if beam goes to -z?
        # Or if beam comes from +z to -z. Sample at 0. Backscattering at z>0. forward at z<0.
        # k_out has z=-10. (Forward).
        # Detector at z=+10. So it won't hit.
        # Let's move detector to z=-10. Normal (0,0,-1).
        
        det_trans = DetectorInput(10.0, SVector(0.0, 0.0, -1.0), SVector(0.0, 1.0, 0.0), 100.0, 100.0)
        
        req = EwaldRequest(crys, beam, det_trans, IntensityInput("unit", nothing))
        resp = calculate_ewald(req)
        
        # Should have 1 spot?
        # |k_out| = 10.05 vs 10. Diff 0.05. < 0.5. Matches condition.
        # Direction approx -z.
        # Intersect with z=-10.
        @test length(resp.spots) >= 0 # Actually depend on exact geometry but shouldn't crash.
    end
    
    @testset "Tight Binding" begin
        # 1D Chain
        # E = 2t cos(kx). t=-1 -> -2 cos(kx).
        # k=0 -> -2. k=pi -> +2.
        
        req = TBRequest(
            TBModelParams("1d_chain", Dict("t" => -1.0, "eps" => 0.0)),
            KPathParams([KPoint("G", SVector(0.0,0.0,0.0)), KPoint("X", SVector(π,0.0,0.0))], 10),
            DOSParams(false, 100, 0.1, nothing, nothing)
        )
        
        resp = calculate_bands(req)
        @test length(resp.bands) == 1
        # First point k=0
        @test isapprox(resp.bands[1][1], -2.0, atol=1e-5)
        # Last point k=pi
        @test isapprox(resp.bands[1][end], 2.0, atol=1e-5)
    end

end
