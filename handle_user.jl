using HTTP, Gumbo, Cascadia, JSON, YAML, PyCall, Serialization
using AbstractTrees

include("util.jl")

requests = pyimport("requests")

domain = "https://bandcamp.com"

function handle_user(url, fanid, cookie; config=YAML.load_file("config.yaml"), first_token = "1653291463:4043186328:a::")

    cookie["cookie"] *= " fan_visits=$fanid;"

    headers = config["Headers"]++cookie++Dict(
        "Referer"=>url, "Host"=>"bandcamp.com",
    )

    payload = Dict("fan_id"=>fanid, "count"=>500, "older_than_token"=>first_token)
    more_available = true
    all_items = Dict{String,Any}[]
    r = requests.post("https://bandcamp.com/api/fancollection/1/collection_items", headers=headers, data=JSON.json(payload))
    append!(all_items, r.json()["items"])
    more_available = r.json()["more_available"]
    more_available && (payload["older_than_token"] = last(all_items)["token"])
    print(payload["older_than_token"])
    sleep(.1)
    all_items
end

function handle_user(subdomain)
    url = "https://bandcamp.com/$subdomain"
    r = requests.get(url)
    cookie = extract_cookie(r)
    doc = parsehtml(r.text)
    fanid = filter(isnumeric, attrs(only(eachmatch(sel"button.follow-unfollow", doc.root)))["id"])
    first_token = attrs(first(eachmatch(sel"ol>li.collection-item-container.track_play_hilite", doc.root)))["data-token"]
    handle_user(url, fanid, cookie, first_token=first_token)
end

# my_items = handle_user("asjir")
# df = vcat(DataFrame.(my_items)...)
# free = filter(x->x["price"]==0, my_items)
# my_items = filter(x->x["price"]>0, my_items)
# serialize("my_albums.jls", filter_price(my_items))

