module Diffraction

using StaticArrays
using LinearAlgebra
using ..Models.Schemas

export calculate_ewald

function calculate_ewald(req::EwaldRequest)::EwaldResponse
    # 1. Setup Beam
    lambda = req.beam.lambda
    k_mag = 2π / lambda
    k_in_dir = normalize(req.beam.kInDir)
    k_in = k_mag * k_in_dir
    
    # Orientation Matrix R
    # If orientation is provided, Q_lab = R * Q_crystal
    # Usually orientation rotates the CRYSTAL.
    # So G vectors (attached to crystal) are rotated.
    # G_lab = R * G_hkl.
    R = if req.beam.orientation === nothing
        I
    else
        matrix3_to_matrix(req.beam.orientation)
    end
    
    # Detector Plane
    # Center P0 = distance * normal
    # Normal n = normalize(req.detector.normal)
    d_dist = req.detector.distance
    n_det_raw = req.detector.normal
    n_det = normalize(n_det_raw)
    P0 = d_dist * n_det
    
    up_raw = req.detector.up
    up = normalize(up_raw)
    
    # Right vector u?
    # Assume P0, up, right form a frame.
    # right = cross(n_det, up)? Or cross(up, n_det)?
    # Usually View Matrix: Eye->Target is -Z. Up is Y. Right is X.
    # If n_det points TO detector from sample.
    # Let's assume standard camera frame:
    # forward = n_det. up = up. right = cross(forward, up).
    right = cross(n_det, up)
    
    w = req.detector.width
    h = req.detector.height
    
    spots = Vector{SpotData}()
    
    # Ewald Tolerance
    # "Elastic" condition is strict delta function.
    # In practice, Ewald sphere has thickness ~ 1/size_of_crystal.
    # Or beam has bandwidth.
    # Let's use a tolerance epsilon.
    # If sigma is provided, use it? sigma in intensity might be different.
    # Let's use internal tolerance related to K.
    epsilon = 0.05 * k_mag # 5% tolerance
    
    # Iterate G vectors
    # req.crystal.gPoints and gHKL should be aligned
    n_points = length(req.crystal.gPoints)
    n_tested = 0
    
    for i in 1:n_points
        g_vec = req.crystal.gPoints[i] # This is Vector3 (SVector)
        hkl = req.crystal.gHKL[i]
        
        # Don't scatter from 000 direct beam here? or yes?
        if norm(g_vec) < 1e-6
            continue
        end
        
        # Rotate G to lab frame
        Q = R * g_vec
        
        # Scattering condition
        # k_out = k_in + Q
        k_out = k_in + Q
        
        # Check integerality / resonance
        # |k_out| should be approx |k_in| = k_mag
        # Deviation
        delta_k = abs(norm(k_out) - k_mag)
        
        if delta_k < epsilon
            n_tested += 1
            # Intensity
            meas_intensity = 1.0
            
            # Simple form factor decay if model is structureFactorLite
            # Since we don't have atoms, just approximate with 1/|Q|^2
            if req.intensity.model == "structureFactorLite"
                q_len = norm(Q)
                if q_len > 1e-3
                    meas_intensity = 1.0 / (q_len^2)
                end
            end
            
            # Additional Gaussian profile based on delta_k
            # I ~ exp( - delta_k^2 / 2sigma^2 )
            sigma = req.intensity.sigma === nothing ? (0.01 * k_mag) : req.intensity.sigma
            meas_intensity *= exp( - (delta_k^2) / (2*sigma^2) )
            
            # Threshold
            if meas_intensity < 1e-4
                continue
            end
            
            # Intersect with Detector
            # Ray: origin -> k_out
            # Plane: (r - P0) . n_det = 0
            # (t * k_out_dir - P0) . n_det = 0
            # t ( k_out . n_det ) = P0 . n_det
            # P0 = d * n_det
            # P0 . n_det = d
            # t = d / ( k_out . n_det )
            # CAUTION: k_out is wavevector. Direction is normalized.
            # Let's use direction.
            dir = normalize(k_out)
            denom = dot(dir, n_det)
            
            if denom > 1e-3 # Moving towards detector
                t = d_dist / denom
                
                # Intersection point
                I_point = t * dir
                
                # Project to UV
                diff = I_point - P0
                # u coordinate
                u_val = dot(diff, right)
                # v coordinate
                v_val = dot(diff, up)
                
                # Check bounds
                if abs(u_val) <= w/2 && abs(v_val) <= h/2
                    push!(spots, SpotData(
                        hkl,
                        Q,
                        dir,     # kOutDir
                        SVector(u_val, v_val),
                        meas_intensity
                    ))
                end
            end
        end
    end
    
    meta = EwaldMeta("hash-placeholder", n_tested)
    return EwaldResponse(spots, meta)
end

# Helpers for matrix conv (duplicated from Crystal.jl, should refactor if used often, 
# but for MVP putting it here is fine or could use Utils)
function matrix3_to_matrix(m::Matrix3)::SMatrix{3,3,Float64,9}
    return SMatrix{3,3}(
        m[1][1], m[2][1], m[3][1],
        m[1][2], m[2][2], m[3][2],
        m[1][3], m[2][3], m[3][3]
    )
end

end
