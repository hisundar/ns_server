%%%============================================================================
%%% Copyright 2013 Maxim Vladimirsky
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%% http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%============================================================================

-module(meck_history_tests).

-include_lib("eunit/include/eunit.hrl").

num_calls_with_arity_test() ->
    %% Given
    meck:new(test, [non_strict]),
    meck:expect(test, foo, 2, ok),
    meck:expect(test, foo, 3, ok),
    %% When
    test:foo(1, 2, 3),
    test:foo(1, 2),
    test:foo(1, 2, 3),
    test:foo(1, 2, 3),
    test:foo(1, 2),
    %% Then
    ?assertMatch(2, meck:num_calls(test, foo, 2)),
    ?assertMatch(3, meck:num_calls(test, foo, 3)),
    ?assertMatch(0, meck:num_calls(test, foo, 4)),
    %% Clean
    meck:unload().

capture_different_positions_test() ->
    %% Given
    meck:new(test, [non_strict]),
    meck:expect(test, foo, 3, ok),
    meck:expect(test, foo, 4, ok),
    meck:expect(test, bar, 3, ok),
    test:foo(1001, 2001, 3001, 4001),
    test:bar(1002, 2002, 3002),
    test:foo(1003, 2003, 3003),
    test:bar(1004, 2004, 3004),
    test:foo(1005, 2005, 3005),
    test:foo(1006, 2006, 3006),
    test:bar(1007, 2007, 3007),
    test:foo(1008, 2008, 3008),
    %% When/Then
    ?assertMatch(2003, meck:capture(first, test, foo, ['_', '_', '_'], 2)),
    ?assertMatch(2008, meck:capture(last, test, foo, ['_', '_', '_'], 2)),
    ?assertMatch(2006, meck:capture(3, test, foo, ['_', '_', '_'], 2)),
    ?assertError(not_found, meck:capture(5, test, foo, ['_', '_', '_'], 2)),
    %% Clean
    meck:unload().

capture_different_args_specs_test() ->
    %% Given
    meck:new(test, [non_strict]),
    meck:expect(test, foo, 2, ok),
    meck:expect(test, foo, 3, ok),
    meck:expect(test, foo, 4, ok),
    meck:expect(test, bar, 3, ok),
    test:foo(1001, 2001, 3001, 4001),
    test:bar(1002, 2002, 3002),
    test:foo(1003, 2003, 3003),
    test:bar(1004, 2004, 3004),
    test:foo(1005, 2005),
    test:foo(1006, 2006, 3006),
    test:bar(1007, 2007, 3007),
    test:foo(1008, 2008, 3008),
    %% When/Then
    ?assertMatch(2001, meck:capture(first, test, foo, '_', 2)),
    ?assertMatch(2003, meck:capture(first, test, foo, 3, 2)),
    ?assertMatch(2005, meck:capture(first, test, foo, ['_', '_'], 2)),
    ?assertMatch(2006, meck:capture(first, test, foo, [1006, '_', '_'], 2)),
    ?assertMatch(2008, meck:capture(first, test, foo, ['_', '_', meck:is(hamcrest_matchers:greater_than(3006))], 2)),
    %% Clean
    meck:unload().

result_different_positions_test() ->
    %% Given
    meck:new(test, [non_strict]),
    meck:expect(test, foo, fun(_, A, _) -> A end),
    meck:expect(test, foo, 4, ok),
    meck:expect(test, bar, 3, ok),
    %% When
    test:foo(1001, 2001, 3001, 4001),
    test:bar(1002, 2002, 3002),
    test:foo(1003, 2003, 3003),
    test:bar(1004, 2004, 3004),
    test:foo(1005, 2005, 3005),
    test:foo(1006, 2006, 3006),
    test:bar(1007, 2007, 3007),
    test:foo(1008, 2008, 3008),
    %% Then
    ?assertMatch(2003, meck_history:result(first, '_', test, foo, ['_', '_', '_'])),
    ?assertMatch(2008, meck_history:result(last, '_', test, foo, ['_', '_', '_'])),
    ?assertMatch(2006, meck_history:result(3, '_', test, foo, ['_', '_', '_'])),
    ?assertError(not_found, meck_history:result(5, '_', test, foo, ['_', '_', '_'])),
    %% Clean
    meck:unload().

result_different_args_specs_test() ->
    %% Given
    meck:new(test, [non_strict]),
    meck:expect(test, foo, fun(_, A) -> A end),
    meck:expect(test, foo, fun(_, A, _) -> A end),
    meck:expect(test, foo, fun(_, A, _, _) -> A end),
    meck:expect(test, bar, 3, ok),
    %% When
    test:foo(1001, 2001, 3001, 4001),
    test:bar(1002, 2002, 3002),
    test:foo(1003, 2003, 3003),
    test:bar(1004, 2004, 3004),
    test:foo(1005, 2005),
    test:foo(1006, 2006, 3006),
    test:bar(1007, 2007, 3007),
    test:foo(1008, 2008, 3008),
    %% Then
    ?assertMatch(2001, meck_history:result(first, '_', test, foo, '_')),
    ?assertMatch(2003, meck_history:result(first, '_', test, foo, 3)),
    ?assertMatch(2005, meck_history:result(first, '_', test, foo, ['_', '_'])),
    ?assertMatch(2006, meck_history:result(first, '_', test, foo, [1006, '_', '_'])),
    Matcher = meck:is(hamcrest_matchers:greater_than(3006)),
    ?assertMatch(2008, meck_history:result(first, '_', test, foo, ['_', '_', Matcher])),
    %% Clean
    meck:unload().

result_exception_test() ->
    %% Given
    meck:new(test, [non_strict]),
    meck:expect(test, error, fun(R) -> erlang:error(R) end),
    meck:expect(test, throw, fun(R) -> throw(R) end),
    meck:expect(test, exit, fun(R) -> exit(R) end),
    %% When
    catch test:error(foo),
    catch test:throw(bar),
    catch test:exit(baz),
    %% Then
    ?assertException(error, foo, meck_history:result(first, '_', test, error, 1)),
    ?assertException(throw, bar, meck_history:result(first, '_', test, throw, 1)),
    ?assertException(exit, baz, meck_history:result(first, '_', test, exit, 1)),
    ?assertError(not_found, meck_history:result(first, '_', test, foo, 0)),
    %% Clean
    meck:unload().

result_different_caller_test() ->
    %% Given
    meck:new(test, [non_strict]),
    meck:expect(test, foo, fun(_, A, _) -> A end),
    %% When
    test:foo(1001, 2001, 3001),
    Self = self(),
    Pid = spawn(fun() ->
                        test:foo(1002, 2002, 3002),
                        Self ! {self(), done}
                end),
    test:foo(1003, 2003, 3003),
    receive {Pid, done} -> ok end,
    %% Then
    ?assertMatch(2003, meck_history:result(2, self(), test, foo, 3)),
    ?assertMatch(2002, meck_history:result(last, Pid, test, foo, 3)),
    %% Clean
    meck:unload().