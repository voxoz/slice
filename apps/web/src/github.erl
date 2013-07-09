-module(github).
-include_lib("n2o/include/wf.hrl").
-compile(export_all).

-define(CLIENT_ID, case application:get_env(web, github_client_id) of {ok, K} -> K;_-> "" end).
-define(CLIENT_SECRET, case application:get_env(web, github_client_secret) of {ok, S} -> S; _-> "" end).
-define(OAUTH_URI, "https://github.com/login/oauth").
-define(AUTHORIZE_URI, ?OAUTH_URI ++ "/authorize").
-define(ACCESS_TOKEN_URI, ?OAUTH_URI ++ "/access_token").
-define(API_URI, "https://api.github.com").
-define(REQ_HEADER, [{"User-Agent", "Erlang Paas"}]).

user(Props) -> api_call("/user", Props).

authorize_url() -> oauth:uri(?AUTHORIZE_URI, [{"client_id", ?CLIENT_ID}, {"state", "state"}]).

get_access_token(Code) ->
  ReqParams = [{"client_id", ?CLIENT_ID}, {"client_secret", ?CLIENT_SECRET}, {"code", binary_to_list(Code)}],
  HttpOptions = [{autoredirect, false}],

  case httpc:request(post, {oauth:uri(?ACCESS_TOKEN_URI, ReqParams), [], "", []}, HttpOptions, []) of
    {error, _} -> not_authorized;
    {ok, R = {{"HTTP/1.1",200,"OK"}, _, _}} ->
      Params = oauth:params_decode(R),
      case proplists:get_value("error", Params, undefined) of undefined -> Params; _E -> not_authorized end;
    {ok, _} -> not_authorized
  end.

api_call(Name, Props) ->
  Token = [{"access_token", proplists:get_value("access_token", Props)}],
  case httpc:request(get, {oauth:uri(?API_URI++Name, Token), ?REQ_HEADER}, [], []) of
    {error, reason} -> api_error;
    {ok, {HttpResponse, _, Body}} -> case HttpResponse of {"HTTP/1.1", 200, "OK"} -> mochijson2:decode(Body); _ -> error end;
    {ok, _} -> api_error
  end.
