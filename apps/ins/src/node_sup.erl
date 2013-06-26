-module(node_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).
-compile(export_all).
-include_lib("kvs/include/users.hrl").

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->

    Users = [ #user{username="maxim",password="password"},
              #user{username="doxtop",password="password"} ],

    kvs:put(Users),

    ets:new(accounts,[set,named_table,public]),

    {ok, {{one_for_one, 5, 10}, []}}.

