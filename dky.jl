using SQLiteGraph, Serialization, DataStructures, SparseArrays, ProgressBars


db = DB("db.db")

example_purchase = db[:,:, "Purchase"] |> first


struct V1Edges
    db::DB
end

function Base.getindex(edges::V1Edges, albumfrom::Int, albumto::Int)
    # source and target are albums
    @assert albumfrom %2 == albumto % 2 == 1  # at least for now
    userset(edges) = Set(edge.source for edge in edges)
    toalbum1 = edges.db[:, albumfrom, "Purchase"]
    toalbum2 = edges.db[:, albumto, "Purchase"]
    connections = intersect(userset(toalbum1), userset(toalbum2))
end

function Base.getindex(edges::V1Edges, albumfrom::Int, ::Colon)
    @assert albumfrom % 2 == 1  # at least for now
    toalbum1 = edges.db[:, albumfrom, "Purchase"]
    Iterators.flatten(
        edges.db[x.source, :, "Purchase"] for x in toalbum1
    )
end

"""srcid -> [targetid => #edgesbetween]"""  # in backlog counter that accepts max size as kw arg
count_outgoing(edges::V1Edges, srcid::Int) = counter(x.target for x in edges[srcid, :])

begin
    my_albums = deserialize("my_albums.jls")
    roc_nid = 2my_albums[2]["tralbum_id"]+1
    db[roc_nid]
    for purchase in db[:, roc_nid, "Purchase"]
        purchase.source
    end
    v1edges = V1Edges(db)
    cntr = count_outgoing(v1edges, roc_nid)
    cntr = filter(>(1)∘last, cntr)
    counts = sort(collect(cntr), by=last, rev=true)
end
