using SQLiteGraph, EasyConfig

include("handle_album.jl")
albumid, all_results = handle_album("dirtyartclub", "basement-seance")

db = DB()

insert!(db, Node(parse(Int, albumid), "Album"; x=3))

parse_mod_date(x) = Date(only(eachmatch(r"^\d{2}\s\w{3}\s\d{4}\b", x)).match, dateformat"d u y")

begin result = all_results[1];
#for result in all_results
    result = copy(result)
    fan_id = pop!(result, "fan_id")
    date = parse_mod_date(pop!(result, "mod_date"))
    insert!(db, Node(fan_id, "Fan"; username=result["username"], url=result["url"]))
end