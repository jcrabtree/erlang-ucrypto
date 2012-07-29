%%
%% Copyright (c) 2012 Alexander Færøy
%% All rights reserved.
%%
%% Redistribution and use in source and binary forms, with or without
%% modification, are permitted provided that the following conditions are met:
%%
%% * Redistributions of source code must retain the above copyright notice, this
%%   list of conditions and the following disclaimer.
%%
%% * Redistributions in binary form must reproduce the above copyright notice,
%%   this list of conditions and the following disclaimer in the documentation
%%   and/or other materials provided with the distribution.
%%
%% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
%% ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
%% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
%% FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
%% DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
%% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
%% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
%% OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

-module(ucrypto).
-export([ripemd160/1, ripemd160_init/0, ripemd160_update/2, ripemd160_final/1]).

-on_load(init/0).

%%
%% NIF's.
%%
-define(nif_stub, nif_stub_error(?LINE)).

nif_stub_error(Line) ->
    erlang:nif_error({nif_not_loaded, module, ?MODULE, line, Line}).

%%
%% Init.
%%
-spec init() -> ok | {error, any()}.

init() ->
    File = case code:priv_dir(?MODULE) of
        {error, bad_name} ->
            case code:which(?MODULE) of
                DirectoryName when is_list(DirectoryName) ->
                    filename:join([filename:dirname(DirectoryName), "../priv", "ucrypto"]);
                _Otherwise ->
                    filename:join("../priv", "ucrypto")
            end;
        Directory ->
            filename:join(Directory, "ucrypto")
    end,
    erlang:load_nif(File, 0).

%%
%% RIPEMD160.
%%
-spec ripemd160(iodata()) -> binary().
-spec ripemd160_init() -> binary().
-spec ripemd160_update(binary(), iodata()) -> binary().
-spec ripemd160_final(binary()) -> binary().

ripemd160(Data) ->
    ripemd160_nif(Data).

ripemd160_init() ->
    ripemd160_init_nif().

ripemd160_update(Context, Data) ->
    ripemd160_update_nif(Context, Data).

ripemd160_final(Context) ->
    ripemd160_final_nif(Context).

ripemd160_nif(_Data) -> ?nif_stub.
ripemd160_init_nif() -> ?nif_stub.
ripemd160_update_nif(_Context, _Data) -> ?nif_stub.
ripemd160_final_nif(_Context) -> ?nif_stub.
