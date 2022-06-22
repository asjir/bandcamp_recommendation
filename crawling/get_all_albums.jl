using SQLiteGraph, ProgressBars, Logging, EasyConfig

include("handle_user.jl")
include("handle_album.jl")


Base.global_logger(Base.SimpleLogger(open("get_all_albums.log", "w+")))

db = DB("db.db")

node_ids = Set{Int64}(Iterators.map(x->x.id,
    Iterators.filter(x->(x.labels==["Album"]) ,db[:])))
    
cookie = extract_cookie(requests.get("https://bandcamp.com/asjir")) 

function process_item(item::Dict)
    propise(keys...) = Config(k=>item[k] for k in keys)
    id = item["tralbum_id"]
    album_props = propise("album_id", "item_url", "num_streamable_tracks", "also_collected_count", "band_url", "genre_id", "tralbum_type", "label")
    purchase_props = propise("price", "currency", "why", "purchased", "updated")
    Node(2id+1, ["Album"], album_props), Edge(2item["fan_id"], 2id+1, "Purchase", purchase_props)
end

for user in tqdm(collect(Iterators.filter(x->(x.labels==["Fan"]) ,db[:])))  # TODO: this should query by user tags
    @info "processing $(user.props.fan_id) at $(user.props.url)"
    items = timelimit_function(handle_user, 5)(user.props.url, user.props.fan_id, cookie)

    if items == :timeout 
        global cookie
        cookie = timelimit_function(extract_cookie∘(requests.get), 5)(user.props.url)
        cookie == :timeout && continue
        items = timelimit_function(handle_user, 5)(user.props.url, user.props.fan_id, cookie)
        items == :timeout && (@warn "processing $(user.props.fan_id) at $(user.props.url) failed"; continue)
    end

    for item in items
        node, edge = process_item(item)
        if node.id ∉ node_ids
            insert!(db, node)
            push!(node_ids, node.id)
        end
        replace!(db, edge)
    end
end



