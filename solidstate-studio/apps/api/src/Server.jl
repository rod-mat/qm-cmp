module Server

using HTTP
using ..Routes

export run_server

function run_server(; host="0.0.0.0", port=8080)
    println("Starting SolidState Studio API on $host:$port...")
    # HTTP.serve is blocking.
    HTTP.serve(Routes.handle_request, host, port)
end

end
