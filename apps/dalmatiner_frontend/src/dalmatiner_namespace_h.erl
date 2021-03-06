-module(dalmatiner_namespace_h).
-behaviour(cowboy_http_handler).

-export([init/3, handle/2, terminate/3]).

-ignore_xref([init/3, handle/2, terminate/3]).

init(_Transport, Req, []) ->
    {ok, Req, undefined}.


-dialyzer({no_opaque, handle/2}).
handle(Req, State) ->
    Req0 = cowboy_req:set_resp_header(
             <<"access-control-allow-origin">>, <<"*">>, Req),

    {ContentType, Req1} = dalmatiner_idx_handler:content_type(Req0),
    case ContentType of
        html ->
            F = fun (Socket, Transport) ->
                        File = code:priv_dir(dalmatiner_frontend) ++
                            "/static/namespace.html",
                        Transport:sendfile(Socket, File)
                end,
            Req2 = cowboy_req:set_resp_body_fun(F, Req1),
            {ok, Req3} = cowboy_req:reply(200, Req2),
            {ok, Req3, State};
        _ ->
            {Collection, Req2} = cowboy_req:binding(collection, Req1),
            {Metric64, Req3} = cowboy_req:binding(metric, Req2),
            {ok, Ns} = namespaces(Collection, Metric64),
            dalmatiner_idx_handler:send(ContentType, Ns, Req3, State)
    end.

terminate(_Reason, _Req, _State) ->
    ok.

namespaces(Collection, undefined) ->
    dqe_idx:namespaces(Collection);
namespaces(Collection, Metric64) ->
    Metric = base64:decode(Metric64),
    dqe_idx:namespaces(Collection, Metric).
