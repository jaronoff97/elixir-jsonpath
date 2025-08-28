%%--------------------------------------------------------------------
%% jsonpath_parser.yrl
%% Minimal JSONPath grammar producing AST compatible with JsonPath.evaluate/2
%%
%% AST shape expected by evaluator:
%%   Root:      {jsonpath, root, Segments}
%%   Segment:   {child|descendant, Selectors}
%%   Selectors: [{name, Name} | {wildcard} | {index, I} | {slice, Slice} |
%%               {union, [Selector, ...]} | {filter, Expr}]
%%
%%   Slice:     {start_end, S, E} |
%%              {start_end_step, S, E, Step} |
%%              {start_omitted_end, E} |
%%              {start_end_omitted, S} |
%%              {start_omitted_end_step, Step} |
%%              {omitted_all}
%%
%%   Filter expr:
%%     {or, A, B} | {and, A, B} | {not, A} |
%%     {cmp, Op, Left, Right}
%%     Op in: eq ne lt le gt ge
%%
%%   Filter primaries may include tiny queries:
%%     {query, relative|absolute, QSegs}
%%     QSeg  = {qname, Name} | {qindex, I}
%%--------------------------------------------------------------------

Nonterminals jsonpath segments segment selector_list selector selector_items or_expr and_expr unary_expr comp_expr primary literal q_segments q_seg slice function_call arg_list .

Terminals DOLLAR AT DDOT DOT LBRACK RBRACK LPAREN RPAREN COMMA COLON STAR QMARK AND OR NOT EQ NE LE GE LT GT NUMBER STRING IDENT TRUE FALSE NULL .

Rootsymbol jsonpath .

%% ===================================================================
%% Grammar
%% ===================================================================

%% Root
jsonpath -> DOLLAR : { jsonpath , root , [ ] } .

jsonpath -> DOLLAR segments : { jsonpath , root , '$2' } .

%% Segments (left-assoc as list)
segments -> segment : [ '$1' ] .

segments -> segments segment : '$1' ++ [ '$2' ] .

%% A single segment (child or descendant)
segment -> DOT IDENT : { child , [ { name , unwrap_ident( '$2' ) } ] } .

segment -> DOT STAR : { child , [ { wildcard } ] } .

segment -> LBRACK selector_list RBRACK : { child , '$2' } .

segment -> DDOT IDENT : { descendant , [ { name , unwrap_ident( '$2' ) } ] } .

segment -> DDOT STAR : { descendant , [ { wildcard } ] } .

segment -> DDOT LBRACK selector_list RBRACK : { descendant , '$3' } .

%% Inside [...] you can have single selector or a comma-union.
selector_list -> selector_items : case '$1' of [ One ] -> [ One ] ; Many -> [ { union , Many } ] end .

selector_items -> selector : [ '$1' ] .

selector_items -> selector_items COMMA selector : '$1' ++ [ '$3' ] .

%% Selectors
selector -> STRING : { name , unwrap_string( '$1' ) } .

selector -> IDENT : { name , unwrap_ident( '$1' ) } .

selector -> NUMBER : { index , unwrap_number( '$1' ) } .

selector -> STAR : { wildcard } .

selector -> slice : { slice , '$1' } .

selector -> QMARK or_expr : { filter , '$2' } .

%% Slices (minimal set that evaluator normalizes)
% Basic cases
slice -> NUMBER COLON NUMBER : { start_end , unwrap_number( '$1' ) , unwrap_number( '$3' ) } .

slice -> NUMBER COLON NUMBER COLON NUMBER : { start_end_step , unwrap_number( '$1' ) , unwrap_number( '$3' ) , unwrap_number( '$5' ) } .

% Start omitted cases
slice -> COLON NUMBER : { start_omitted_end , unwrap_number( '$2' ) } .

slice -> COLON NUMBER COLON NUMBER : { start_omitted_end_step , unwrap_number( '$2' ) , unwrap_number( '$4' ) } .

slice -> COLON NUMBER COLON : { start_omitted_end , unwrap_number( '$2' ) } .

% End omitted cases
slice -> NUMBER COLON : { start_end_omitted , unwrap_number( '$1' ) } .

slice -> NUMBER COLON COLON : { start_end_omitted , unwrap_number( '$1' ) } .

slice -> NUMBER COLON COLON NUMBER : { start_end_omitted_step , unwrap_number( '$1' ) , unwrap_number( '$4' ) } .

% Both start and end omitted
slice -> COLON : { omitted_all } .

slice -> COLON COLON : { omitted_all } .

slice -> COLON COLON NUMBER : { start_omitted_end_step , unwrap_number( '$3' ) } .

%% -------------------------------------------------------------------
%% Filter expressions
%% precedence: NOT > AND > OR
%% -------------------------------------------------------------------

or_expr -> or_expr OR and_expr : { 'or' , '$1' , '$3' } .

or_expr -> and_expr : '$1' .

and_expr -> and_expr AND unary_expr : { 'and' , '$1' , '$3' } .

and_expr -> unary_expr : '$1' .

unary_expr -> NOT unary_expr : { 'not' , '$2' } .

unary_expr -> comp_expr : '$1' .

comp_expr -> primary EQ primary : { cmp , eq , '$1' , '$3' } .

comp_expr -> primary NE primary : { cmp , ne , '$1' , '$3' } .

comp_expr -> primary LT primary : { cmp , lt , '$1' , '$3' } .

comp_expr -> primary LE primary : { cmp , le , '$1' , '$3' } .

comp_expr -> primary GT primary : { cmp , gt , '$1' , '$3' } .

comp_expr -> primary GE primary : { cmp , ge , '$1' , '$3' } .

comp_expr -> primary : '$1' .

primary -> literal : '$1' .

primary -> function_call : '$1' .

primary -> AT q_segments : { query , relative , '$2' } .

primary -> AT : { query , relative , [ ] } .

primary -> DOLLAR : { query , absolute , [ ] } .

primary -> DOLLAR q_segments : { query , absolute , '$2' } .

primary -> LPAREN or_expr RPAREN : '$2' .

%% Tiny query segments for filters: @.name, @['name'], @[0]
q_segments -> q_seg : [ '$1' ] .

q_segments -> q_segments q_seg : '$1' ++ [ '$2' ] .

q_seg -> DOT IDENT : { qname , unwrap_ident( '$2' ) } .

q_seg -> DOT STAR : { qwildcard } .

q_seg -> LBRACK STRING RBRACK : { qname , unwrap_string( '$2' ) } .

q_seg -> LBRACK NUMBER RBRACK : { qindex , unwrap_number( '$2' ) } .

q_seg -> LBRACK STAR RBRACK : { qwildcard } .

q_seg -> LBRACK slice RBRACK : { qslice , '$2' } .

q_seg -> DDOT IDENT : { qdescendant_name , unwrap_ident( '$2' ) } .

q_seg -> DDOT STAR : { qdescendant_wildcard } .

q_seg -> DDOT LBRACK STRING RBRACK : { qdescendant_name , unwrap_string( '$3' ) } .

q_seg -> DDOT LBRACK NUMBER RBRACK : { qdescendant_index , unwrap_number( '$3' ) } .

q_seg -> DDOT LBRACK STAR RBRACK : { qdescendant_wildcard } .

q_seg -> DDOT LBRACK slice RBRACK : { qdescendant_slice , '$3' } .

%% Literals (numbers, strings, booleans, null)
literal -> NUMBER : { lit , unwrap_number( '$1' ) } .

literal -> STRING : { lit , unwrap_string( '$1' ) } .

literal -> TRUE : { lit , true } .

literal -> FALSE : { lit , false } .

literal -> NULL : { lit , null } .

%% Function calls
function_call -> IDENT LPAREN RPAREN : { function , unwrap_ident( '$1' ) , [ ] } .

function_call -> IDENT LPAREN arg_list RPAREN : { function , unwrap_ident( '$1' ) , '$3' } .

%% Function argument list
arg_list -> or_expr : [ '$1' ] .

arg_list -> arg_list COMMA or_expr : '$1' ++ [ '$3' ] .

%% ===================================================================
%% Erlang helper code
%% ===================================================================
Erlang code .

%% Expect tokens like {IDENT, Line, "foo"}, {STRING, Line, "bar"}, {NUMBER, Line, N}
unwrap_ident({_IDENT, _, V}) ->
    V.

unwrap_string({_STRING, _, V}) ->
    V.

unwrap_number({_NUMBER, _, V}) ->
    V.
