%% priv/leex/jsonpath_lexer.xrl
%% run with: leex:compile("jsonpath_lexer.xrl").
%% Produces a module: jsonpath_lexer

Definitions.

DIGIT       = [0-9]
DIGITS      = {DIGIT}+
INT         = -?{DIGITS}
FRAC        = \.{DIGITS}
EXP         = [eE][+-]?{DIGITS}
NUMBER      = {INT}({FRAC})?({EXP})?
%% Identifiers: start with underscore, ASCII letter, or any non-ASCII char
IDENT_START = [_A-Za-z\x80-\x{10FFFF}]
IDENT_PART  = [_A-Za-z0-9\x80-\x{10FFFF}]
IDENT       = {IDENT_START}{IDENT_PART}*

Rules.

[\s\n\r\t]+               : skip_token.
//.*                      : skip_token.
/\*([^*]|\*+[^*/])*\*+/   : skip_token.

\.\.                      : {token, {'DDOT', TokenLine}}.
\.                        : {token, {'DOT', TokenLine}}.
\[                        : {token, {'LBRACK', TokenLine}}.
\]                        : {token, {'RBRACK', TokenLine}}.
\(                        : {token, {'LPAREN', TokenLine}}.
\)                        : {token, {'RPAREN', TokenLine}}.
,                         : {token, {'COMMA', TokenLine}}.
:                         : {token, {'COLON', TokenLine}}.
\*                        : {token, {'STAR', TokenLine}}.
\?                        : {token, {'QMARK', TokenLine}}.
\$                        : {token, {'DOLLAR', TokenLine}}.
@                         : {token, {'AT', TokenLine}}.

&&                        : {token, {'AND', TokenLine}}.
\|\|                      : {token, {'OR', TokenLine}}.
!                         : {token, {'NOT', TokenLine}}.

==                        : {token, {'EQ', TokenLine}}.
!=                        : {token, {'NE', TokenLine}}.
<=                        : {token, {'LE', TokenLine}}.
>=                        : {token, {'GE', TokenLine}}.
<                         : {token, {'LT', TokenLine}}.
>                         : {token, {'GT', TokenLine}}.

"([^\\"]|\\.)*"           : {token, {'STRING', TokenLine, lexeme_to_string(TokenChars)}}.
'([^\\']|\\.)*'           : {token, {'STRING', TokenLine, lexeme_to_string(TokenChars)}}.

true                      : {token, {'TRUE', TokenLine}}.
false                     : {token, {'FALSE', TokenLine}}.
null                      : {token, {'NULL', TokenLine}}.

{NUMBER}                  : {token, {'NUMBER', TokenLine, list_to_number(TokenChars)}}.

{IDENT}                   : {token, {'IDENT', TokenLine, unicode:characters_to_binary(TokenChars)}}.

.                         : {error, {illegal, TokenChars}}.

Erlang code.

%% convert recognized string token (including quotes) into binary string
lexeme_to_string(Chars) ->
    S = list_to_binary(Chars),
    %% remove surrounding quotes
    Size = byte_size(S) - 2,
    <<_Quote1:8, Body:Size/binary, _Quote2:8>> = S,
    unescape_json_string(Body).

%% convert number lexeme text into number (integer or float)
list_to_number(Chars) ->
    Str = lists:flatten(Chars),
    Fixed =
        case re:run(Str, "^[+-]?[0-9]+[eE][+-]?[0-9]+$") of
            {match, _} -> insert_decimal(Str);
            nomatch -> Str
        end,
    try
        list_to_integer(Fixed)
    catch
        _:_ ->
            list_to_float(Fixed)
    end.

insert_decimal(Str) ->
    %% Split on first e/E and insert ".0"
    case string:chr(Str, $e) of
        0 ->   % no 'e', maybe 'E'
            case string:chr(Str, $E) of
                0 -> Str;
                Pos ->
                    Base = string:substr(Str, 1, Pos-1),
                    Exp  = string:substr(Str, Pos),
                    Base ++ ".0" ++ Exp
            end;
        Pos ->
            Base = string:substr(Str, 1, Pos-1),
            Exp  = string:substr(Str, Pos),
            Base ++ ".0" ++ Exp
    end.



%% unescapes common JSON escapes
unescape_json_string(Bin) ->
    %% a simple unescape: replace \uXXXX and \n,\t etc.
    Unesc1 = re:replace(Bin, <<"\\\\u([0-9A-Fa-f]{4})">>,
                        fun(_, [Hex]) ->
                            HexStr = binary_to_list(Hex),
                            unicode:characters_to_binary([list_to_integer(HexStr, 16)])
                        end,
                        [global, {return, binary}]),
    Unesc2 = re:replace(Unesc1, <<"\\\\\"">>, <<"\"">>, [global, {return, binary}]),
    Unesc3 = re:replace(Unesc2, <<"\\\\'">>, <<"'">>, [global, {return, binary}]),
    Unesc4 = re:replace(Unesc3, <<"\\\\n">>, <<"\n">>, [global, {return, binary}]),
    Unesc5 = re:replace(Unesc4, <<"\\\\r">>, <<"\r">>, [global, {return, binary}]),
    Unesc6 = re:replace(Unesc5, <<"\\\\t">>, <<"\t">>, [global, {return, binary}]),
    Unesc7 = re:replace(Unesc6, <<"\\\\b">>, <<"\b">>, [global, {return, binary}]),
    Unesc8 = re:replace(Unesc7, <<"\\\\f">>, <<"\f">>, [global, {return, binary}]),
    Unesc9 = re:replace(Unesc8, <<"\\\\/">>, <<"/">>, [global, {return, binary}]),
    Unesc10 = re:replace(Unesc9, <<"\\\\\\\\">>, <<"\\">>, [global, {return, binary}]),
    Unesc10.
