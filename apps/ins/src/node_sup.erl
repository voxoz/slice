-module(node_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).
-compile(export_all).
-include_lib("ins/include/node_server.hrl").
-include_lib("kvs/include/users.hrl").

start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->

    Users = [ #user{username="maxim",password="password"},
              #user{username="doxtop",password="password"} ],

    Regions = [ #region{name="do",provider="Digital Ocean"},
                #region{name="hz",provider="Hetzner"},
                #region{name="am",provider="Amazon"} ],

    Instances = [ #instance{name="do1",region="do"},
                  #instance{name="do2",region="do"}],

    kvs:put(Users ++ Regions ++ Instances),

    ets:new(accounts,[set,named_table,public]),

    {ok, {{one_for_one, 5, 10}, []}}.

