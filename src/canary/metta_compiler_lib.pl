:- dynamic(transpiler_clause_store/8).

%%%%%%%%%%%%%%%%%%%%% arithmetic

'mc__+'(A,B,R) :- number(A),number(B),!,plus(A,B,R).
'mc__+'(A,B,['+',A,B]).

'mc__-'(A,B,R) :- number(A),number(B),!,plus(B,R,A).
'mc__-'(A,B,['-',A,B]).

'mc__*'(A,B,R) :- number(A),number(B),!,R is A*B.
'mc__*'(A,B,['*',A,B]).

%%%%%%%%%%%%%%%%%%%%% logic

mc__and(A,B,B):- atomic(A), A\=='False', A\==0.
mc__and(_,_,'False').

mc__or(A,B,B):- (\+ atomic(A); A='False'; A=0), !.
mc__or(_,_,'True').

%%%%%%%%%%%%%%%%%%%%% comparison

'mc__=='(A,A,1) :- !.
'mc__=='(_,_,0).

'mc__<'(A,B,R) :- number(A),number(B),!,(A<B -> R=1 ; R=0).
'mc__<'(A,B,['<',A,B]).

'mc__>'(A,B,R) :- number(A),number(B),!,(A>B -> R=1 ; R=0).
'mc__>'(A,B,['>',A,B]).

%%%%%%%%%%%%%%%%%%%%% lists

'mc__car-atom'([H|_],H).

'mc__cdr-atom'([_|T],T).

'mc__cons-atom'(A,B,[A|B]).

%%%%%%%%%%%%%%%%%%%%% superpose, collapse

'mc__superpose'(S,R) :- member(R,S).

% put a fake transpiler_clause_store here, just to force the argument to be lazy
transpiler_clause_store(collapse, 2, ['Atom'], 'Expression', [lazy], eager, [], []).
'mc__collapse'(is_p1(Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc__collapse'(is_p1(true,X),[X]).

%%%%%%%%%%%%%%%%%%%%% spaces

'mc__add-atom'(Space,PredDecl,'Empty') :- 'add-atom'(Space,PredDecl).

'mc__remove-atom'(Space,PredDecl,'Empty') :- 'remove-atom'(Space,PredDecl).

'mc__get-atoms'(Space,Atoms) :- metta_atom(Space, Atoms).

%%%%%%%%%%%%%%%%%%%%% misc

'mc__empty'(_) :- fail.

'mc__get-metatype'(X,Y) :- 'get-metatype'(X,Y). % use the code in the interpreter for now

'mc__stringToChars'(S,C) :- string_chars(S,C).

'mc__charsToString'(C,S) :- string_chars(S,C).

mc__assertEqualToResult(A, B, C) :- u_assign([assertEqualToResult, A, B], C).
