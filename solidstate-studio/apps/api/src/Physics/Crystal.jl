module Crystal

using StaticArrays
using LinearAlgebra
using ..Models.Schemas

export build_crystal

function build_crystal(req::CrystalBuildRequest)::CrystalBuildResponse
    # 1. Construct Real Lattice Matrix A (columns are vectors)
    # But prompt says A rows are a1, a2, a3. 
    # Let's stick to prompt convention: A is Matrix3 where rows are a1, a2, a3.
    # Standard physics convention: R = n1 a1 + n2 a2 + n3 a3
    # If A has rows a1,a2,a3. Then R_cart = N_frac * A ? No.
    # If v = (x,y,z) is frac. r = x a1 + y a2 + z a3.
    # In matrix form with A rows: r = A^T * v.
    # Let's verify prompt: "A = Matrix3 ... filas a1, a2, a3".
    # Ok.
    
    A = get_lattice_matrix(req.lattice)
    
    # 2. Reciprocal Lattice B
    # B = 2π * (A^{-1})^T
    # If A has rows a_i, then A_inv has cols ... 
    # Let's use standard formula:
    # a1 = A[1,:], a2 = A[2,:], a3 = A[3,:]
    # V = dot(a1, cross(a2, a3))
    # b1 = 2pi * cross(a2, a3) / V
    # ...
    # Prompt says: "B = 2π * (A^{-1})^T (filas b1,b2,b3)"
    # A_inv = inv(A)
    # B = 2π * transpose(A_inv)
    # Yes, this matches.
    
    A_mat = matrix3_to_matrix(A) # SMatrix
    B_mat = 2π * transpose(inv(A_mat))
    B = matrix_to_matrix3(B_mat)
    
    # 3. Supercell Atoms
    # Generate all atoms in supercell
    # req.supercell = [n1, n2, n3]
    nx, ny, nz = req.supercell
    
    positions = Vector{Vector3}()
    elements = Vector{String}()
    fracs = Vector{Vector3}()
    
    for i in 0:nx-1, j in 0:ny-1, k in 0:nz-1
        offset = SVector(i, j, k)
        for atom in req.basis
            # Atom frac in unit cell
            f = atom.frac
            # Atom frac in supercell?
            # Usually we visualize the supercell as the new "unit".
            # But the prompt asks for "atoms" which likely means all atoms in the volume.
            
            # Position = (f + offset) * A (if A rows are basis vectors)
            # r = (f1+i)*a1 + (f2+j)*a2 + (f3+k)*a3
            # r = (f + offset) dot A (row-wise) ? 
            # r = sum (f_m + off_m) * a_m
            
            f_total = f + offset
            # r = f_total[1]*a1 + f_total[2]*a2 + f_total[3]*a3
            # In matrix mult: r = A^T * f_total
            
            r = transpose(A_mat) * f_total
            
            push!(positions, r)
            push!(elements, atom.element)
            push!(fracs, f_total) # keeping "fractional" relative to unit cell basis (can be > 1)
        end
    end
    
    atoms_data = AtomsData(positions, elements, fracs)
    
    # 4. Supercell Real Cell for visualization
    # The "Real Cell" matrix for the result should probably be the supercell matrix?
    # Or just the primitive?
    # The prompt CrystalBuildResponse has "real: {A, origin}". 
    # Usually we want to show the bounding box of the generated atoms.
    # So let's scale A by supercell dims.
    # A_super row 1 = n1 * a1
    A_super_mat = SMatrix{3,3}(
        A_mat[1,:] * nx,
        A_mat[2,:] * ny,
        A_mat[3,:] * nz
    )
    # Wait, A_mat cols are not a1,a2,a3. A_mat rows are.
    # SMatrix constructor is column-major flat, or tuple of cols?
    # It's better to construct explicitly.
    
    a1 = A_mat[1,:]
    a2 = A_mat[2,:]
    a3 = A_mat[3,:]
    
    A_super_rows = (
        a1 * nx,
        a2 * ny,
        a3 * nz
    )
    # Reassemble into SMatrix (rows)
    # SMatrix{3,3} takes input as (1,1), (2,1), (3,1), (1,2)... (column major)
    # We want rows to be A_super_rows.
    # Col 1: [Rx, Ry, Rz] of row 1? No.
    # A is 3x3.
    # A[1,:] = a1'
    # We want New A.
    
    A_res = Matrix3([
        tuple(A_super_rows[1]...),
        tuple(A_super_rows[2]...),
        tuple(A_super_rows[3]...)
    ])
    
    real_data = RealCell(A_res, Vector3(0,0,0))
    
    # 5. Reciprocal Points
    # Generate G points up to gMax.
    # G = h b1 + k b2 + l b3.
    # |G| < gMax.
    
    gMax = req.reciprocal === nothing ? 8.0 : req.reciprocal.gMax
    gPoints = Vector{Vector3}()
    gHKL = Vector{SVector{3,Int}}()
    
    # Estimate max indices
    # |h b1| approx gMax => h_max approx gMax / |b1|
    b1 = B_mat[1,:]
    b2 = B_mat[2,:]
    b3 = B_mat[3,:]
    
    n_h = ceil(Int, gMax / norm(b1)) + 1
    n_k = ceil(Int, gMax / norm(b2)) + 1
    n_l = ceil(Int, gMax / norm(b3)) + 1
    
    # To be safe, search a bit wider or check metric tensor.
    # Simple loop.
    for h in -n_h:n_h, k in -n_k:n_k, l in -n_l:n_l
        if h==0 && k==0 && l==0; continue; end
        G = h*b1 + k*b2 + l*b3
        if norm(G) <= gMax
            push!(gPoints, Vector3(G))
            push!(gHKL, SVector(h,k,l))
        end
    end
    
    recip_data = RecipCell(B, gPoints, gHKL)
    
    # 6. Planes
    planes_data = []
    if req.planes !== nothing
        for p in req.planes
            h, k, l = p.h, p.k, p.l
            offset = p.offset === nothing ? 0.0 : p.offset
            size = p.size === nothing ? 10.0 : p.size # default size if not specified
            
            # Normal vector G_hkl
            G = h*b1 + k*b2 + l*b3
            if norm(G) < 1e-6
                continue # 000 plane?
            end
            n = normalize(G)
            
            # Center point
            # Plane eq: r . G = 2pi * N ? Or just r.n = dist?
            # Crystallographic plane (hkl) closest to origin is at distance d = 2pi/|G|.
            # Actually, usually G connects origin to (hkl) plane in recip space... 
            # In real space, planes (hkl) are perpendicular to G.
            # Intercepts at a1/h, a2/k, a3/l.
            # Distance from origin = 2pi / |G| (if using physics convention) or 1/|G|?
            # Definition: exp(i G . r) = 1.
            # G . r = 2 pi integer.
            # So planes are at distances d_n = 2pi n / |G|.
            
            # "offset" in request might simply mean shift along normal?
            # Let's assume offset=0 means passing through origin.
            
            # Generate a quad perpendicular to n, centered at origin + offset*n ?
            # Or assume offset is in units of d_hkl? 
            # Let's define center C = offset * n (Cartesian shift).
            
            C = offset * n 
            
            # Basis vectors for the plane
            # We need two vectors u, v perp to n.
            # arbitrary perp vector:
            if abs(n[1]) < 0.8
                u = normalize(cross(n, SVector(1.0, 0.0, 0.0)))
            else
                u = normalize(cross(n, SVector(0.0, 1.0, 0.0)))
            end
            v = normalize(cross(n, u))
            
            s2 = size / 2.0
            
            # vertices: C + s*u + s*v etc
            p1 = C - s2*u - s2*v
            p2 = C + s2*u - s2*v
            p3 = C + s2*u + s2*v
            p4 = C - s2*u + s2*v
            
            vv = [p1, p2, p3, p4]
            ff = [SVector(1,2,3), SVector(1,3,4)] # 1-based indexing for mesh faces (Julia/OBJ style? Or 0 based?)
            # Prompt returns schema: SVector{3, Int}. Usually in API response, 0-based is safer for JS?
            # But let's assume 0-based for JS consumption.
            # Wait, schema is defined as Int. 
            # Let's provide 0-based indices for the frontend (0,1,2), (0,2,3).
            ff_0 = [SVector(0,1,2), SVector(0,2,3)]
            
            push!(planes_data, PlaneData(
                SVector(h,k,l),
                n,
                MeshData(vv, ff_0)
            ))
        end
    end
    
    # 7. Warnings / Meta
    meta = MetaData("hash-placeholder", String[])
    
    return CrystalBuildResponse(
        real_data,
        recip_data,
        atoms_data,
        convert(Vector{PlaneData}, planes_data),
        meta
    )
end

# Helpers

function get_lattice_matrix(p::LatticeParams)
    if p.kind == "custom"
        if p.A === nothing; error("Missing A for custom lattice"); end
        return p.A
    end
    
    a = p.a
    b = p.b === nothing ? a : p.b
    c = p.c === nothing ? a : p.c
    
    # Angles in degrees
    alp = p.alpha === nothing ? 90.0 : p.alpha
    bet = p.beta  === nothing ? 90.0 : p.beta
    gam = p.gamma === nothing ? 90.0 : p.gamma
    
    to_rad = π / 180.0
    alpha = alp * to_rad
    beta  = bet * to_rad
    gamma = gam * to_rad
    
    # Standard construction: a aligned with x. b in xy plane.
    # a1 = (a, 0, 0)
    # a2 = (b cos(gamma), b sin(gamma), 0)
    # a3 = (c cos(beta), c (cos(alpha) - cos(beta)cos(gamma))/sin(gamma), c sqrt(...))
    
    # Formula for general triclinic
    v_a = SVector(a, 0.0, 0.0)
    v_b = SVector(b * cos(gamma), b * sin(gamma), 0.0)
    
    cx = c * cos(beta)
    cy = c * (cos(alpha) - cos(beta)*cos(gamma)) / sin(gamma)
    cz = sqrt(c^2 - cx^2 - cy^2)
    v_c = SVector(cx, cy, cz)
    
    # Rows are a1, a2, a3
    return Matrix3(
        (v_a[1], v_a[2], v_a[3]),
        (v_b[1], v_b[2], v_b[3]),
        (v_c[1], v_c[2], v_c[3])
    )
end

function matrix3_to_matrix(m::Matrix3)::SMatrix{3,3,Float64,9}
    # m is tuple of tuples (rows).
    # SMatrix constructor takes column-major elements or a function.
    # rows: r1, r2, r3.
    # Matrix = [r1x r1y r1z; r2x... ...]
    # we can construct via hcat of row vectors? No.
    # Just explicit.
    return SMatrix{3,3}(
        m[1][1], m[2][1], m[3][1], # Col 1
        m[1][2], m[2][2], m[3][2], # Col 2
        m[1][3], m[2][3], m[3][3]  # Col 3
    )
end

function matrix_to_matrix3(m::SMatrix{3,3,Float64,9})::Matrix3
    return (
        SVector(m[1,1], m[1,2], m[1,3]),
        SVector(m[2,1], m[2,2], m[2,3]),
        SVector(m[3,1], m[3,2], m[3,3])
    )
end

end
