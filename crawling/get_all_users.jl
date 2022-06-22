using Serialization, SQLiteGraph, ProgressBars

include("handle_album.jl")

my_albums = deserialize("my_albums.jls")
my_albums = filter(isalbum, my_albums)

# _, results = handle_album(my_albums[1]["item_url"])

db = DB("db.db")
fan_ids = Set{Int}()

for album in tqdm(my_albums)
    results = handle_album(album["item_url"])
    for result in results
        fan_id = result["fan_id"]
        if fan_id ∉ fan_ids
            insert!(db, Node(2fan_id, "Fan"; username=result["username"], url=result["url"], fan_id=fan_id))
            push!(fan_ids, fan_id)
        end
    end
end

