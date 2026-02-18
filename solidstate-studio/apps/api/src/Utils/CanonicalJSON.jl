module CanonicalJSON

using JSON3
using Printf

export canonical_json

function canonical_json(obj)
    io = IOBuffer()
    _write_canonical(io, obj)
    return String(take!(io))
end

function _write_canonical(io::IO, x::Real)
    # Round floats to 8 decimals to avoid numerical noise in hash
    # Use standard formatting
    @printf(io, "%.8g", x)
end

function _write_canonical(io::IO, x::Integer)
    print(io, x)
end

function _write_canonical(io::IO, x::String)
    JSON3.write(io, x)
end

function _write_canonical(io::IO, x::Symbol)
    JSON3.write(io, String(x))
end

function _write_canonical(io::IO, x::AbstractVector)
    print(io, "[")
    for (i, v) in enumerate(x)
        if i > 1
            print(io, ",")
        end
        _write_canonical(io, v)
    end
    print(io, "]")
end

function _write_canonical(io::IO, x::AbstractDict)
    # Sort keys
    ks = sort(collect(keys(x)))
    print(io, "{")
    for (i, k) in enumerate(ks)
        if i > 1
            print(io, ",")
        end
        JSON3.write(io, String(k))
        print(io, ":")
        _write_canonical(io, x[k])
    end
    print(io, "}")
end

function _write_canonical(io::IO, x::Nothing)
    print(io, "null")
end

# Fallback for structs: convert to Dict or iterate fields
function _write_canonical(io::IO, x)
    # If it's a struct, we can rely on JSON3 to structure it, but we need sorting.
    # Easiest is to convert to standard Dict first if possible, or use struct fields.
    # For this MVP, we are mostly hashing standard dicts coming from JSON3.read, 
    # but let's handle the case where we might pass a struct.
    # However, standard pattern: request -> JSON3.read (creates Dict/Vector/Primitives) -> canonical_json -> hash
    # So we likely won't see raw structs here often.
    # But if we do, we assume it behaves like a Dict-compatible object.
    
    # Simple fallback: use JSON3 write but that doesn't guarantee order.
    # Better: reflection.
    T = typeof(x)
    if isstructtype(T)
        names = fieldnames(T)
        print(io, "{")
        # We need to sort field names if we want canonical
        # But for structs, field order is fixed. However, to match a Dict that might have arbitrary order,
        # we should probably sort them too if we want "structural" equality?
        # Actually, for the API contract, the incoming JSON is a Dict (parsed). 
        # So we probably only need to handle Dict.
        # But let's be safe.
        sorted_names = sort(collect(names))
        for (i, name) in enumerate(sorted_names)
            if i > 1
                print(io, ",")
            end
            JSON3.write(io, String(name))
            print(io, ":")
            val = getfield(x, name)
            _write_canonical(io, val)
        end
        print(io, "}")
    else
        JSON3.write(io, x)
    end
end

end
