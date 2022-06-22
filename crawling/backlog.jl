# count_outgoing(edges::V1Edges, srcid::Int; maxsize=Inf) = counter(x.target for x in edges[srcid, :]; maxsize=maxsize)
# todo: custom counter that'd skip singleton counts after some time, i.e. max_buffer_size
# actually I can implement a new counter method

function DataStructures.counter(seq; maxsize=Inf)
    ct = counter(eltype_for_accumulator(seq))
    for x in seq
        if (length(ct) < maxsize) || (x in keys(ct))
            inc!(ct, x)
        end
    end
    return ct
end

eltype_for_accumulator(seq::T) where T = eltype(T)
function eltype_for_accumulator(seq::Base.Generator)
    Base.@default_eltype(seq)
end

function to_matrix(db)
    album_nids = [x.id for x in db[:] if x.labels == ["Album"]]
    album_nids = Dict(nid => idx for (idx, nid) in enumerate(album_nids))
    fan_nids = [x.id for x in db[:] if x.labels == ["Fan"]]
    fan_nids = Dict(nid => idx for (idx, nid) in enumerate(fan_nids))
    M = spzeros(Bool, length(fan_nids), length(album_nids), )
    for edge :: Edge in tqdm(db[:,:,"Purchase"])
        M[fan_nids[edge.source], album_nids[edge.target]] = true
    end
    M
end