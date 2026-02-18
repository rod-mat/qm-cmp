module Server

using HTTP
using JSON3
using ..Routes

export run_server

function cors_middleware(handler)
    return function(req::HTTP.Request)
        # CORS Headers
        headers = [
            "Access-Control-Allow-Origin" => "*",
            "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
            "Access-Control-Allow-Headers" => "Content-Type",
            "Content-Type" => "application/json"
        ]

        # Handle Preflight
        if req.method == "OPTIONS"
            return HTTP.Response(200, headers, "")
        end

        try
            # Process Request
            resp = handler(req)
            # Add CORS headers to response
            for (k, v) in headers
                HTTP.setheader(resp, k => v)
            end
            return resp
        catch e
            # Fallback Error Handling with CORS
            println("Server Error: ", e)
            return HTTP.Response(500, headers, JSON3.write(Dict("error" => "Internal Server Error")))
        end
    end
end

function run_server(; host="0.0.0.0", port=8080)
    println("Starting SolidState Studio API on $host:$port...")
    # Wrap router with CORS middleware
    handler = cors_middleware(Routes.handle_request)
    HTTP.serve(handler, host, port)
end

end
