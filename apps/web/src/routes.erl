-module (routes).
-author('Maxim Sokhatsky').
-behaviour (route_handler).
-include_lib("n2o/include/wf.hrl").
-export([init/2, finish/2]).

finish(State, Ctx) -> {ok, State, Ctx}.
init(State, Ctx) -> 
    Path = wf:path(Ctx#context.req),
    %error_logger:info_msg("Routes path: ~p", [Path]),
    {Module, PathInfo} = route(Path),
    {ok, State, Ctx#context{path=PathInfo,module=Module}}.

route(<<"/">>) -> {containers, []};
route(<<"/login">>) -> {login, []};
route(<<"/account">>) -> {account, []};
route(<<"/dashboard">>) -> {dashboard, []};
route(<<"/containers">>) -> {containers, []};
route(<<"/ws/">>) -> {login, []};
route(<<"/ws/login">>) -> {login, []};
route(<<"/ws/dashboard">>) -> {dashboard, []};
route(<<"/ws/account">>) -> {account, []};
route(<<"/ws/containers">>) -> {containers, []};
route(<<"/favicon.ico">>) -> {static_file, []};
route(_) -> {index, []}.

