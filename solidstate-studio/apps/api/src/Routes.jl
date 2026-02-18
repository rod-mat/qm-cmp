module Routes

using HTTP
using JSON3
using StructTypes
using Dates
using ..Models.Schemas
using ..Physics.Crystal
using ..Physics.Diffraction
using ..Physics.TightBinding
using ..Utils.Validation
using ..Utils.Hashing
using ..Utils.CanonicalJSON
using ..Cache

export handle_request

# Initialize Cache
const RES_CACHE = LRUCache{String, String}(256)

function handle_request(req::HTTP.Request)
    # CORS
    headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type",
        "Content-Type" => "application/json"
    ]
    
    if req.method == "OPTIONS"
        return HTTP.Response(200, headers, "")
    end

    path = req.target
    
    try
        if path == "/api/health"
            return HTTP.Response(200, headers, JSON3.write(Dict("ok" => true)))
        elseif path == "/api/crystal/build"
            return handle_endpoint(req, headers, CrystalBuildRequest, validate_crystal, build_crystal)
        elseif path == "/api/diffraction/ewald"
            return handle_endpoint(req, headers, EwaldRequest, validate_ewald, calculate_ewald)
        elseif path == "/api/tb/bands"
            return handle_endpoint(req, headers, TBRequest, validate_tb, calculate_bands)
        else
            return HTTP.Response(404, headers, JSON3.write(Dict("error" => "Not found")))
        end
    catch e
        # Log error
        println("Server Error: ", e)
        # return trace?
        buf = IOBuffer()
        showerror(buf, e, catch_backtrace())
        err_msg = String(take!(buf))
        return HTTP.Response(500, headers, JSON3.write(Dict("error" => "Internal Server Error", "details" => err_msg)))
    end
end

function handle_endpoint(req::HTTP.Request, headers, T_Request, validator, processor)
    if req.method != "POST"
        return HTTP.Response(405, headers, JSON3.write(Dict("error" => "Method not allowed")))
    end
    
    # 1. Parse
    body_bytes = req.body
    json_body = try
        JSON3.read(body_bytes, T_Request)
    catch e
        return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Invalid JSON", "details" => string(e))))
    end
    
    # 2. Validate
    is_valid, err_msg = validator(json_body)
    if !is_valid
        return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Validation Error", "details" => err_msg)))
    end
    
    # 3. Hash (Canonical)
    # Re-serialize to canonical string for hashing
    # Or strict struct?
    # Our Hashing module takes "obj". `canonical_json` implementation might fall back to struct fields?
    # `json_body` is a Struct.
    # We should convert it to Dict for canonicalization if we want it primarily based on JSON structure.
    # However, since we defined StructTypes, JSON3.read gives us a Struct.
    # `CanonicalJSON` needs to handle Structs. My implementation did handle it via fields.
    req_hash = hash_request(json_body)
    
    # 4. Cache Check
    cached_resp = Cache.get(RES_CACHE, req_hash)
    if cached_resp !== nothing
        # Hit
        return HTTP.Response(200, headers, cached_resp)
    end
    
    # 5. Process
    result = processor(json_body)
    
    # 6. Inject Hash into Meta?
    # The result struct matches response schema, which has `meta`.
    # result is a struct. Immutable?
    # Most physics funcs return a new struct.
    # But strings inside might be mutable? Structs are usually immutable.
    # We constructed it with "hash-placeholder".
    # We need to construct a new Response object with the correct hash.
    # This requires reconstructing the struct. 
    # Or assume physics module returns `meta` with placeholder and we ignore it or 
    # better: pass the hash TO the processor? No, strict signature.
    # Let's reconstruct.
    # Reflection to copy and replace meta?
    
    final_result = update_meta_hash(result, req_hash)
    
    # 7. Serialize & Cache
    resp_json = JSON3.write(final_result)
    Cache.put!(RES_CACHE, req_hash, resp_json)
    
    return HTTP.Response(200, headers, resp_json)
end

function update_meta_hash(obj, h::String)
    # All response structs have `meta` field.
    # We returned a concrete type.
    # Construct new one.
    
    # Generic approach using Accessors or just manual overload?
    # Manual overload is safer for typed structs.
    
    T = typeof(obj)
    # We can reconstruct using fields, replacing meta.
    
    # Get current meta
    current_meta = obj.meta
    # Create new Meta
    # Meta type depends on response type.
    # CrystalBuildResponse -> MetaData
    # EwaldResponse -> EwaldMeta
    # TBResponse -> TBMeta
    
    new_meta = update_meta_struct(current_meta, h)
    
    # Generic reconstruct
    # Assumes meta is last field? Or lookup?
    # "meta" is a field name.
    
    # Construction: T(field1, field2, ..., new_meta)
    
    vals = [getfield(obj, f) for f in fieldnames(T)]
    # Find index of meta
    idx = findfirst(==(:meta), fieldnames(T))
    if idx !== nothing
        vals[idx] = new_meta
    end
    
    return T(vals...)
end

function update_meta_struct(m::Schemas.MetaData, h)
    return Schemas.MetaData(h, m.warnings)
end

function update_meta_struct(m::Schemas.EwaldMeta, h)
    return Schemas.EwaldMeta(h, m.nTested)
end

function update_meta_struct(m::Schemas.TBMeta, h)
    return Schemas.TBMeta(h)
end

end
