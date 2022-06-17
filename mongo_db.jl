using Mongoc

client = Mongoc.Client("localhost", 27017)

Mongoc.ping(client)

thumbs_collection = client["album-db"]["album-followers"]

domain = "barbes"
album_title = "the-roots-of-chicha"
album_id, thumbs_list = handle_album(domain, album_title)

doc = Mongoc.BSON(
    "domain" => domain,
    "album_title" => album_title,
    "album_id" => album_id,
    "thumbs_list" => thumbs_list
)
push!(thumbs_collection, doc)

document = Mongoc.find_one(thumbs_collection, Mongoc.BSON("""{ "domain" : "barbes" }"""))

mapise(document) = Dict(x["fan_id"] => (pop!(x, "fan_id"); x) for x in document["thumbs_list"])
purchase_date(x) = Date(only(eachmatch(r"^\d{2}\s\w{3}\s\d{4}\b", x["mod_date"])).match, dateformat"d u y")

