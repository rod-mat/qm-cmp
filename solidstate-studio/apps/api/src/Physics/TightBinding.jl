module TightBinding

using StaticArrays
using LinearAlgebra
using ..Models.Schemas

export calculate_bands

function calculate_bands(req::TBRequest)::TBResponse
    model_name = req.model.lattice
    params = req.model.params
    
    # 1. K-Path Construction
    # Input points: P1 -> P2 -> P3
    # Generate points along segments
    raw_k_linear = Float64[] # Distance along path for plotting 
    k_vecs = Vector{Vector3}()
    labels = Vector{LabelData}()
    
    kp_config = req.kpath
    n_seg = kp_config.nPerSegment
    points = kp_config.points
    
    current_dist = 0.0
    
    for i in 1:(length(points)-1)
        p_start = points[i]
        p_end = points[i+1]
        
        # Add label for start point
        if i == 1
            push!(labels, LabelData(0, p_start.label))
        else
             # Avoid duplicating label exactly? 
             # usually visualizer handles it.
             # We store index 0-based? or 1-based?
             # Let's use 0-based index of the array 'k_vecs'
             push!(labels, LabelData(length(k_vecs), p_start.label))
        end
        
        k1 = p_start.k
        k2 = p_end.k
        dist = norm(k2 - k1)
        
        # Steps
        # generate n_seg points. 
        # Endpoint included? usually yes for path continuity.
        # But if we include endpoint, next segment starts with same point.
        # Standard: include start, exclude end? Or include both and have duplicate?
        # Better: P1...P2 (inclusive). Next segment P2...P3. P2 is duplicated?
        # Usually fine for plotting lines.
        # Let's generate inclusive start, exclusive end, unless last segment.
        
        step_vec = (k2 - k1) / n_seg
        step_dist = dist / n_seg
        
        for j in 0:(n_seg-1)
            k_curr = k1 + j * step_vec
            push!(k_vecs, k_curr)
            push!(raw_k_linear, current_dist + j*step_dist)
        end
        
        current_dist += dist
    end
    
    # Add final point
    last_pt = points[end]
    push!(k_vecs, last_pt.k)
    push!(raw_k_linear, current_dist)
    push!(labels, LabelData(length(k_vecs)-1, last_pt.label))
    
    # 2. Band Calculation
    # Determine number of bands
    # 1d_chain: 1 band
    # 2d_square: 1 band
    # 2d_honeycomb: 2 bands
    
    n_k = length(k_vecs)
    
    bands = Vector{Vector{Float64}}()
    
    # Pre-allocate band arrays
    # if honeycomb, we need bands[1] and bands[2]
    # Each is size n_k
    
    # Helper to get params
    getp(k, def) = get(params, k, def)
    
    if model_name == "1d_chain"
        # 1 band
        b1 = zeros(n_k)
        t = getp("t", -1.0)
        eps = getp("eps", 0.0)
        
        for i in 1:n_k
            kx = k_vecs[i][1]
            # E = eps + 2t cos(kx) assuming a=1
            b1[i] = eps + 2*t*cos(kx)
        end
        push!(bands, b1)
        
    elseif model_name == "2d_square"
        # 1 band
        b1 = zeros(n_k)
        t = getp("t", -1.0)
        tp = getp("tp", 0.0)
        eps = getp("eps", 0.0)
        
        for i in 1:n_k
            kx = k_vecs[i][1]
            ky = k_vecs[i][2]
            # E = eps + 2t(cx + cy) + 4tp cx cy
            cx = cos(kx)
            cy = cos(ky)
            b1[i] = eps + 2*t*(cx + cy) + 4*tp*cx*cy
        end
        push!(bands, b1)
        
    elseif model_name == "2d_honeycomb"
        # 2 bands
        b1 = zeros(n_k)
        b2 = zeros(n_k)
        t = getp("t", -2.7) # eV usually
        epsA = getp("epsA", 0.0)
        epsB = getp("epsB", 0.0)
        
        # Nearest neighbors for honeycomb (a=1)
        # delta1 = (0, 1/sqrt(3)) ? No, that's not general.
        # Standard graphene setup a=1 (interatomic distance vs lattice const?)
        # Lattice vectors a1 = (3/2, sqrt(3)/2), a2 = (3/2, -sqrt(3)/2) (if a_cc = 1)
        # But usually in TB we just sum phases over neighbors.
        # neighbors:
        # d1 = (0, 1) * a_cc? 
        # Let's assume standard form:
        # f(k) = t * (1 + exp(-i k.a1) + exp(-i k.a2)) ?
        # For Wallace (PR 1947):
        # f(k) = 1 + exp(i k.a1) + exp(i k.a2) (if hopping is to neighbors in unit cell?)
        # Let's use the explicit form for ideal honeycomb.
        # a1 = (3/2, sqrt(3)/2), a2 = (3/2, -sqrt(3)/2). a=1 (lattice const implies a_cc = 1/sqrt(3)).
        # Let's assume lattice parameter a=1. 
        # Then K points provided in input are in units of 1/a? or just raw?
        # The frontend provides standard high symmetry points for hexagonal?
        # Let's assume input kx, ky are k*a.
        # Formula: E = +/- t * sqrt(3 + 2cos(k.a1) + 2cos(k.a2) + 2cos(k.(a1-a2)))
        # This is for p-z orbitals.
        # Let's use simple tight binding:
        # H = [epsA  f; conj(f) epsB]
        # f = t * (1 + exp(-i k.a1) + exp(-i k.a2)) ?
        # This corresponds to neighbors at 0, -a1, -a2?
        # Let's assume standard Graphene-like structure.
        
        # Using a1 = (3/2, sqrt(3)/2), a2 = (3/2, -sqrt(3)/2) * a_lat
        # Note: if a=1 in lattice param, then a1, a2 are as above.
        
        rt3 = sqrt(3.0)
        
        for i in 1:n_k
            kx = k_vecs[i][1]
            ky = k_vecs[i][2]
            
            # Dot products
            # k.a1 = kx * 1.5 + ky * rt3/2 ? (scaled by some factor?)
            # Let's assume k is dimensionless (k*a).
            # Standard Graphene: a1=(1/2, rt3/2), a2=(-1/2, rt3/2)? No that's Triangular/Hex lattice basis.
            # Honeycomb has 2 atoms basis.
            # Off-diagonal term f(k) = -t * (1 + e^{i k.a1} + e^{i k.a2})
            # where a1, a2 are primitive vectors.
            
            # Let's try:
            # k.a1 = kx * 0.5 + ky * rt3 * 0.5
            # k.a2 = kx * (-0.5) + ky * rt3 * 0.5
            # (Rotate 30 deg?)
            # Or simpler: 1d models are usually kx. 2d square kx, ky.
            # 2d honeycomb usually kx, ky relative to a=1.
            
            # Let's use the expression:
            # |f|^2 = 1 + 4 cos(1.5 kx) cos(sqrt(3)/2 ky) + 4 cos^2(sqrt(3)/2 ky) ?
            # This is common formula for graphene with a=1 (nearest neighbor dist).
            # Wait, a=1 is NN distance? Or Lattice Constant?
            # Standard is Lattice constant a_lat = sqrt(3) a_cc.
            # If input K is k * a_lat.
            # f = t ( 1 + exp(-i k.a1) + exp(-i k.a2) )
            # Just implement H diagonalization.
            
            # Assume lattice vectors:
            v1_x, v1_y = 0.5, rt3/2.0
            v2_x, v2_y = -0.5, rt3/2.0
            # k dot v
            k_dot_1 = kx * v1_x + ky * v1_y
            k_dot_2 = kx * v2_x + ky * v2_y
            
            # Just try f = t * (1 + exp(i*k_dot_1*2*pi?) + ...)
            # Usually K is in reciprocal units?
            # Prompt says: "Reciprocal: 1/Angstrom".
            # Equation uses k.R. So if R in A, k in 1/A.
            # Let's assume geometry matches a=1.
            
            # Just calculate f
            # Using 3 nearest neighbors vectors d1, d2, d3.
            # d1 = (0, 1/sqrt(3))?
            # Just use the function modulus directly.
            
            # Graphene approx from solid state texts:
            # E(k) = +/- t sqrt(1 + 4 cos(sqrt(3)/2 kx a) cos(ky a / 2) + 4 cos^2(ky a / 2) ) ??
            # This depends on orientation.
            
            # Let's use the simplest H matrix form with general complex calc.
            # f = t * (1 + exp(im * (kx * 0.5 + ky * rt3/2)) + exp(im * (kx * -0.5 + ky * rt3/2)))
            # Assuming params are effectively k.a
            
            arg1 = kx * 0.5 + ky * rt3 * 0.5
            arg2 = kx * (-0.5) + ky * rt3 * 0.5
            
            f = t * (1.0 + exp(im * arg1) + exp(im * arg2))
            
            # H = [epsA  f;  conj(f) epsB]
            # Eigenvalues:
            # (epsA - E)(epsB - E) - |f|^2 = 0
            # E^2 - (epsA+epsB)E + epsA*epsB - |f|^2 = 0
            # Quadratic formula
            mid = (epsA + epsB) / 2.0
            diff = (epsA - epsB) / 2.0
            disc = sqrt(diff^2 + abs2(f))
            
            b1[i] = mid - disc
            b2[i] = mid + disc
        end
        push!(bands, b1)
        push!(bands, b2)
        
    else
        # Default empty
    end
    
    # 3. DOS
    dos_res = nothing
    if req.dos.enabled && !isempty(bands)
        # Random sampling or Grid sampling over BZ
        # BZ range?
        # 1D: -pi to pi
        # 2D Square: -pi to pi
        # Honeycomb: -4pi/3 to 4pi/3 approx? Or just large rectangle.
        
        # Grid parameters
        nk_dos = 50 # 50x50 = 2500 samples
        nE = req.dos.nE
        eta = req.dos.eta
        
        min_e_val = minimum(minimum.(bands))
        max_e_val = maximum(maximum.(bands))
        
        # User override
        min_e = req.dos.eMin === nothing ? min_e_val - 1.0 : req.dos.eMin
        max_e = req.dos.eMax === nothing ? max_e_val + 1.0 : req.dos.eMax
        
        E_grid = range(min_e, max_e, length=nE)
        DOS_vals = zeros(nE)
        
        # Sample BZ
        # We need a function to compute E(k) efficiently without allocation
        # Reuse logic?
        # For MVP, just copy paste loops inside a "sample" function or just loop here.
        
        samples = Float64[]
        
        if model_name == "1d_chain"
            t = getp("t", -1.0)
            eps = getp("eps", 0.0)
            for kx in range(-π, π, length=400)
                push!(samples, eps + 2*t*cos(kx))
            end
        elseif model_name == "2d_square"
            t = getp("t", -1.0)
            tp = getp("tp", 0.0)
            eps = getp("eps", 0.0)
            rg = range(-π, π, length=nk_dos)
            for kx in rg, ky in rg
                cx = cos(kx); cy = cos(ky)
                push!(samples, eps + 2*t*(cx+cy) + 4*tp*cx*cy)
            end
        elseif model_name == "2d_honeycomb"
             t = getp("t", -2.7)
             epsA = getp("epsA", 0.0)
             epsB = getp("epsB", 0.0)
             rt3 = sqrt(3.0)
             # Hex BZ is inside rectangle [-4pi/3, 4pi/3] x [-2pi/sqrt(3), ...]
             # Just sample a rectangle [-π, π]x[-π, π] * 2?
             # Let's sample [-2π, 2π] just to be safe coverage?
             # Or just [-π, π] x [-π, π] in appropriate basis.
             rg = range(-2π, 2π, length=nk_dos)
             for kx in rg, ky in rg
                 arg1 = kx * 0.5 + ky * rt3 * 0.5
                 arg2 = kx * (-0.5) + ky * rt3 * 0.5
                 f = t * (1.0 + exp(im * arg1) + exp(im * arg2))
                 mid = (epsA + epsB) / 2.0
                 diff = (epsA - epsB) / 2.0
                 disc = sqrt(diff^2 + abs2(f))
                 push!(samples, mid - disc)
                 push!(samples, mid + disc)
             end
        end
        
        # Accumulate DOS (Lorentzian)
        # DOS(E) = sum 1/pi * eta / ((E - Ei)^2 + eta^2)
        # Optimization: Precompute factor? Or just loop. 
        # For 2500 samples * 1200 E points = 3M ops. Fast in Julia.
        
        for e_sample in samples
            for (ei, E_val) in enumerate(E_grid)
                denom = (E_val - e_sample)^2 + eta^2
                DOS_vals[ei] += (eta / π) / denom
            end
        end
        
        # Normalize?
        # DOS usually per unit cell.
        # Divider = number of k-points sampled.
        scale = 1.0 / length(samples)
        DOS_vals .*= scale
        
        dos_res = DOSResult(collect(E_grid), DOS_vals)
    end
    
    meta = TBMeta("hash-placeholder")
    
    return TBResponse(
        raw_k_linear,
        labels,
        bands,
        dos_res,
        meta
    )
end

end
