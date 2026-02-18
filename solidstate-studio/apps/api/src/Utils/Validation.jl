module Validation

using ..Models.Schemas

export validate_crystal, validate_ewald, validate_tb

function validate_crystal(req::CrystalBuildRequest)
    # Check lattice params
    if req.lattice.a <= 0
        return false, "Lattice parameter 'a' must be positive"
    end
    # Add more specific checks if needed
    return true, ""
end

function validate_ewald(req::EwaldRequest)
    if req.beam.lambda <= 0
        return false, "Wavelength lambda must be positive"
    end
    return true, ""
end

function validate_tb(req::TBRequest)
    if req.kpath.nPerSegment < 2
        return false, "nPerSegment must be at least 2"
    end
    return true, ""
end

end
