%% @author Northscale <info@northscale.com>
%% @copyright 2010 NorthScale, Inc.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%      http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% @doc Manage mnesia
%%
-module(ns_mnesia).

-include("ns_common.hrl").

-export([add_node/1, delete_node/1, delete_schema/0, delete_schema_and_stop/0,
         start/0]).


%%
%% API
%%

%% @doc Add an mnesia node. The other node had better have called
%% delete_schema().
add_node(Node) ->
    {ok, [Node]} = mnesia:change_config(extra_db_nodes, [Node]),
    {atomic, ok} = mnesia:change_table_copy_type(schema, Node, disc_copies),
    ?log_info("Added node ~p to cluster.~nCurrent config: ~p",
              [Node, mnesia:system_info(all)]).


%% @doc Remove an mnesia node.
delete_node(Node) ->
    ok = mnesia:del_table_copy(schema, Node),
    ?log_info("Removed node ~p from cluster.~nCurrent config: ~p",
              [Node, mnesia:system_info(all)]).


%% @doc Delete the current mnesia schema for joining/renaming purposes.
delete_schema() ->
    stopped = mnesia:stop(),
    ok = mnesia:delete_schema([node()]),
    ok = mnesia:start(),
    ?log_info("Deleted schema.~nCurrent config: ~p",
              [mnesia:system_info(all)]).


%% @doc Delete the schema, but stay stopped.
delete_schema_and_stop() ->
    ?log_info("Deleting schema and stopping Mnesia.", []),
    stopped = mnesia:stop(),
    ok = mnesia:delete_schema([node()]).


%% @doc Start Mnesia, creating a new schema if we don't already have one.
start() ->
    %% Create a new on-disk schema if one doesn't already exist
    case mnesia:create_schema([node()]) of
        ok ->
            ?log_info("Creating new disk schema.", []);
        {error, {_, {already_exists, _}}} ->
            ?log_info("Using existing disk schema.", [])
    end,
    ok = mnesia:start(),
    ?log_info("Current config: ~p", [mnesia:system_info(all)]).
