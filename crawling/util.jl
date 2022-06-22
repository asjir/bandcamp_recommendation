matches(rexp, str) = !isnothing(match(rexp, str))
++(v1::Vector,v2::Vector) = [v1;v2]
++(d1::Dict, d2::Dict) = merge(d1,d2)
++(d1::Dict, d2::Dict, dicts...) = ++((d1++d2), dicts...)
function extract_cookie(response)
    f(x) = matches(r"client_id=.+;", x) | matches(r"session=.{27}.+;", x) | matches(r"BACKENDID=.+;",x) 
    headers = collect(py"dict"(response.headers))
    cookie = unique(strip.(split(join(last.(filter(==("set-cookie")∘first, headers)), " "), " ")))
    Dict(["cookie" => join(filter(f,cookie), " ")])
end

function timelimit_function(f, max_time)
    (xs...) -> begin
        cond = Condition()
        Timer(x->notify(cond), max_time)
        t = @async begin
            res = f(xs...)
            notify(cond)
            res
        end
        wait(cond)
        t.state == :done ? fetch(t) : :timeout
    end
end