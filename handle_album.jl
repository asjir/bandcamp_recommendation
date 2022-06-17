using HTTP, Gumbo, Cascadia, JSON, YAML, PyCall  #, Serialization
requests = pyimport("requests")
include("util.jl")
# yo(s, r) = eachmatch(s, parsehtml(r.body).root)

# r = requests.get("https://barbes.bandcamp.com/album/the-roots-of-chicha")
# r = deserialize("r.jls")
# payload = ("""{"tralbum_type":"a","tralbum_id":426884333,"token":null,"count":80}""")
# # r2 = requests.post("https://barbes.bandcamp.com/api/tralbumcollectors/2/thumbs", headers=YAML.load_file("config.yaml")["Headers"]++pls(r), data=payload,)
# r2 = deserialize("r2.jls")
# r2.json()

function handle_album(url; config=YAML.load_file("config.yaml"))    
    domain = first(split(url, "/album/"))
    r = requests.get(url)

    # tags = text.(eachmatch(sel"div>a.tag", parsehtml(r.text).root))

    headers = config["Headers"]++extract_cookie(r)++Dict(
        "Referer"=>url, "Origin"=>domain
    )
    getid(text) = filter(isnumeric, rsplit(text, "<!--", limit=2)[2])
    albumid = getid(r.text)
    payload = Dict("tralbum_type"=>"a", "tralbum_id"=>albumid, "count"=>100, "token"=>nothing)
    more_available = true
    all_results = Dict{Any,Any}[]
    while more_available
        r = requests.post(domain * "/api/tralbumcollectors/2/thumbs", headers=headers, data=JSON.json(payload))
        append!(all_results, r.json()["results"])
        more_available = r.json()["more_available"]
        more_available && (payload["token"] = last(all_results)["token"])
        print(payload["token"])
        sleep(.1)
    end
    all_results  # , tags
end

band, name = "dirtyartclub", "basement-seance"

isalbum(item) = split(item["item_url"], "/")[end-1] == "album"

# url = "https://$band.bandcamp.com/album/$name"
#     domain = first(split(url, "/album/"))
#     r = requests.get(url)#     eachmatch(sel"div>a.tag", parsehtml(r.text).root)

function process_item(item::Dict)
    propise(keys...) = Config(k=>item[k] for k in keys)
    id = item["tralbum_id"]
    album_props = propise("album_id", "item_url", "num_streamable_tracks", "also_collected_count")
    purchase_props = propise("price", "currency", "why", "purchased", "updated")
    Node(2id+1, ["Album"], album_props), Edge(2item["fan_id"], 2id+1, "Purchase", purchase_props)
end