-module(node_sup).
-behaviour(supervisor).
-export([start_link/0, init/1]).
-compile(export_all).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->

    {ok, {{one_for_one, 5, 10}, []}}.

