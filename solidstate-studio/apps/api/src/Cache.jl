module Cache

export LRUCache, get!, put!

mutable struct LRUCache{K, V}
    capacity::Int
    store::Dict{K, V}
    history::Vector{K} # Front is old, Back is new
    lock::ReentrantLock
end

function LRUCache{K,V}(capacity::Int) where {K,V}
    return LRUCache{K,V}(capacity, Dict{K,V}(), Vector{K}(), ReentrantLock())
end

function Base.get(c::LRUCache{K,V}, key::K) where {K,V}
    lock(c.lock) do
        if haskey(c.store, key)
            # update history: move to back
            # O(N) but N is small (256)
            filter!(x -> x != key, c.history)
            push!(c.history, key)
            return c.store[key]
        else
            return nothing
        end
    end
end

function put!(c::LRUCache{K,V}, key::K, value::V) where {K,V}
    lock(c.lock) do
        if haskey(c.store, key)
            c.store[key] = value
            filter!(x -> x != key, c.history)
            push!(c.history, key)
        else
            if length(c.store) >= c.capacity
                # Evict LRU (front of history)
                if !isempty(c.history)
                    oldest = popfirst!(c.history)
                    delete!(c.store, oldest)
                end
            end
            c.store[key] = value
            push!(c.history, key)
        end
    end
end

end
