module Crystal

using StaticArrays
using LinearAlgebra
using ..Models.Schemas

export build_crystal

function build_crystal(req::CrystalBuildRequest)::CrystalBuildResponse
    A = get_lattice_matrix(req.lattice)
    
    # 2. Reciprocal Lattice B
    # B = 2π * (A^{-1})^T
    
    # Since Matrix3 is already SMatrix{3,3,Float64,9}, we can use it directly
    A_mat = A 
    B_mat = 2π * transpose(inv(A_mat))
    B = B_mat
    
    # 3. Supercell Atoms
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
    a1 = A_mat[1,:]
    a2 = A_mat[2,:]
    a3 = A_mat[3,:]
    
    A_super_rows = (
        a1 * nx,
        a2 * ny,
        a3 * nz
    )
    
    # To construct SMatrix{3,3} that has rows (n1*a1, n2*a2, n3*a3)
    # We must provide elements in column-major order:
    # Col 1: A_super_rows[1][1], A_super_rows[2][1], A_super_rows[3][1]
    # Col 2: A_super_rows[1][2], A_super_rows[2][2], A_super_rows[3][2]
    # Col 3: A_super_rows[1][3], A_super_rows[2][3], A_super_rows[3][3]
    
    A_res = Matrix3(
        A_super_rows[1][1], A_super_rows[2][1], A_super_rows[3][1],
        A_super_rows[1][2], A_super_rows[2][2], A_super_rows[3][2],
        A_super_rows[1][3], A_super_rows[2][3], A_super_rows[3][3]
    )
    
    real_data = RealCell(A_res, Vector3(0,0,0))
    
    # 5. Reciprocal Points
    
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
            
            C = offset * n 
            
            # Basis vectors for the plane
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
            # 0-based indexing for mesh faces for JS
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
    
    # SMatrix{3,3} expects 9 elements in column-major order.
    # Input rows are v_a, v_b, v_c.
    # Col 1: [v_ax, v_bx, v_cx]
    # Col 2: [v_ay, v_by, v_cy]
    # Col 3: [v_az, v_bz, v_cz]
    
    return Matrix3(
        v_a[1], v_b[1], v_c[1],
        v_a[2], v_b[2], v_c[2],
        v_a[3], v_b[3], v_c[3]
    )
end

function matrix3_to_matrix(m::Matrix3)::SMatrix{3,3,Float64,9}
    return m
end

function matrix_to_matrix3(m::SMatrix{3,3,Float64,9})::Matrix3
    return m
end

end
