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
-export([ec_new_key/1, ec_new_key/3, ec_new_private_key/2, ec_new_public_key/2, ec_verify/3, ec_verify/4, ec_sign/2, ec_sign/3, ec_public_key/1, ec_set_public_key/2, ec_private_key/1, ec_set_private_key/2, ec_delete_key/1]).
-export([hex2bin/1, bin2hex/1]).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-endif.

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
ripemd160(Data) ->
    ripemd160_nif(Data).

-spec ripemd160_init() -> binary().
ripemd160_init() ->
    ripemd160_init_nif().

-spec ripemd160_update(binary(), iodata()) -> binary().
ripemd160_update(Context, Data) ->
    ripemd160_update_nif(Context, Data).

-spec ripemd160_final(binary()) -> binary().
ripemd160_final(Context) ->
    ripemd160_final_nif(Context).

ripemd160_nif(_Data) ->
    ?nif_stub.

ripemd160_init_nif() ->
    ?nif_stub.

ripemd160_update_nif(_Context, _Data) ->
    ?nif_stub.

ripemd160_final_nif(_Context) ->
    ?nif_stub.

%%
%% EC.
%%
ec_new_key(Curve) when is_atom(Curve) ->
    KeyRef = ec_new_by_curve_nif(Curve),
    ec_generate_key_nif(KeyRef),
    {ec_key, KeyRef}.

ec_new_key(Curve, PrivateKey, PublicKey) when is_atom(Curve), is_binary(PrivateKey), is_binary(PublicKey) ->
    KeyRef = ec_new_by_curve_nif(Curve),
    case ec_set_private_key({ec_key, KeyRef}, PrivateKey) of
        {ec_key, KeyRef} ->
            ec_set_public_key({ec_key, KeyRef}, PublicKey);
        {error, Error} ->
            {error, Error}
    end.

ec_new_private_key(Curve, PrivateKey) when is_atom(Curve), is_binary(PrivateKey) ->
    KeyRef = ec_new_by_curve_nif(Curve),
    ec_set_private_key({ec_key, KeyRef}, PrivateKey).

ec_new_public_key(Curve, PublicKey) when is_atom(Curve), is_binary(PublicKey) ->
    KeyRef = ec_new_by_curve_nif(Curve),
    ec_set_public_key({ec_key, KeyRef}, PublicKey).

ec_verify(Data, Signature, {ec_key, KeyRef}) ->
    ec_verify_nif(KeyRef, Data, Signature).

ec_verify(Data, Signature, Curve, PublicKey) when is_atom(Curve), is_binary(PublicKey) ->
    case ec_new_public_key(Curve, PublicKey) of
        {ec_key, KeyRef} ->
            case ec_verify(Data, Signature, {ec_key, KeyRef}) of
                Result when is_boolean(Result) ->
                    ec_delete_key({ec_key, KeyRef}),
                    Result;
                Error ->
                    Error
            end;
        Error ->
            Error
    end.

ec_sign(Data, {ec_key, KeyRef}) ->
    ec_sign_nif(KeyRef, Data).

ec_sign(Data, Curve, PrivateKey) when is_atom(Curve), is_binary(PrivateKey) ->
    case ec_new_private_key(Curve, PrivateKey) of
        {ec_key, KeyRef} ->
            case ec_sign(Data, {ec_key, KeyRef}) of
                Result when is_binary(Result) ->
                    ec_delete_key({ec_key, KeyRef}),
                    Result;
                Error ->
                    Error
            end;
        Error ->
            Error
    end.

ec_public_key({ec_key, KeyRef}) ->
    ec_get_public_key_nif(KeyRef).

ec_set_public_key({ec_key, KeyRef}, PublicKey) when is_binary(PublicKey) ->
    case ec_set_public_key_nif(KeyRef, PublicKey) of
        ok ->
            {ec_key, KeyRef};
        error ->
            {error, {failed_to_set_public_key, PublicKey}}
    end.

ec_private_key({ec_key, KeyRef}) ->
    ec_get_private_key_nif(KeyRef).

ec_set_private_key({ec_key, KeyRef}, PrivateKey) when is_binary(PrivateKey) ->
    case ec_set_private_key_nif(KeyRef, PrivateKey) of
        ok ->
            {ec_key, KeyRef};
        error ->
            {error, {failed_to_set_private_key, PrivateKey}}
    end.

ec_delete_key({ec_key, KeyRef}) ->
    ec_delete_key_nif(KeyRef).

ec_new_by_curve_nif(_Curve) ->
    ?nif_stub.

ec_generate_key_nif(_Key) ->
    ?nif_stub.

ec_verify_nif(_Key, _Data, _Signature) ->
    ?nif_stub.

ec_sign_nif(_Key, _Data) ->
    ?nif_stub.

ec_get_public_key_nif(_Key) ->
    ?nif_stub.

ec_set_public_key_nif(_Key, _PublicKey) ->
    ?nif_stub.

ec_get_private_key_nif(_Key) ->
    ?nif_stub.

ec_set_private_key_nif(_Key, _PrivateKey) ->
    ?nif_stub.

ec_delete_key_nif(_Key) ->
    ?nif_stub.

%%
%% Utilities.
%%
hex2bin([A, B | Rest]) ->
    <<(list_to_integer([A, B], 16)), (hex2bin(Rest))/binary>>;
hex2bin([A]) ->
    <<(list_to_integer([A], 16))>>;
hex2bin([]) ->
    <<>>.

bin2hex(Bin) when is_binary(Bin) ->
    lists:flatten([integer_to_list(X, 16) || <<X:4/integer>> <= Bin]).

%%
%% Tests.
%%
-ifdef(TEST).

hex2bin_test() ->
    [
        ?assertEqual(hex2bin(""), <<>>),
        ?assertEqual(hex2bin("0"), <<0>>),
        ?assertEqual(hex2bin("00"), <<0>>),
        ?assertEqual(hex2bin("F"), <<15>>),
        ?assertEqual(hex2bin("0F"), <<15>>),
        ?assertEqual(hex2bin("F0"), <<240>>),
        ?assertEqual(hex2bin("FF"), <<255>>),
        ?assertEqual(hex2bin("FFFF"), <<255,255>>),
        ?assertEqual(hex2bin("000"), <<0,0>>),
        ?assertEqual(hex2bin("0001"), <<0,1>>),
        ?assertEqual(hex2bin("FFFFFFFF"), <<255,255,255,255>>)
    ].

ripemd160_simple_test() ->
    [
        ?assertEqual(hex2bin("9c1185a5c5e9fc54612808977ee8f548b2258d31"), ripemd160("")),
        ?assertEqual(hex2bin("ddadef707ba62c166051b9e3cd0294c27515f2bc"), ripemd160("A")),
        ?assertEqual(hex2bin("5d74fef3f73507f0e8a8ff9ec8cdd88988c472ca"), ripemd160("abcdefghijklmnopqrstuvwxyzæøå"))
    ].

ripemd160_test() ->
    List = ["abc", "def", "gh", "ijkl", "mno", "pqrs", "tuvwx", "yzæøå"],
    InitialContext = ripemd160_init(),
    FinalContext = lists:foldl(fun(X, Context) -> ripemd160_update(Context, X) end, InitialContext, List),
    ?assertEqual(hex2bin("5d74fef3f73507f0e8a8ff9ec8cdd88988c472ca"), ripemd160_final(FinalContext)).

-endif.
