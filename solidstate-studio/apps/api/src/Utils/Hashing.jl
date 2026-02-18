module Hashing

using SHA
using ..CanonicalJSON

export hash_request

function hash_request(obj)::String
    canon = canonical_json(obj)
    return bytes2hex(sha256(canon))
end

end
