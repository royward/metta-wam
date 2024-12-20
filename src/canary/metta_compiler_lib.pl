:- dynamic(transpiler_clause_store/9).

%%%%%%%%%%%%%%%%%%%%% arithmetic

'mc_2__+'(A,B,R) :- number(A),number(B),!,plus(A,B,R).
'mc_2__+'(A,B,['+',A,B]).

'mc_2__-'(A,B,R) :- number(A),number(B),!,plus(B,R,A).
'mc_2__-'(A,B,['-',A,B]).

'mc_2__*'(A,B,R) :- number(A),number(B),!,R is A*B.
'mc_2__*'(A,B,['*',A,B]).

%%%%%%%%%%%%%%%%%%%%% logic

mc_2__and(A,B,B):- atomic(A), A\=='False', A\==0.
mc_2__and(_,_,'False').

mc_2__or(A,B,B):- (\+ atomic(A); A='False'; A=0), !.
mc_2__or(_,_,'True').

%%%%%%%%%%%%%%%%%%%%% comparison

'mc_2__=='(A,A,1) :- !.
'mc_2__=='(_,_,0).

'mc_2__<'(A,B,R) :- number(A),number(B),!,(A<B -> R=1 ; R=0).
'mc_2__<'(A,B,['<',A,B]).

'mc_2__>'(A,B,R) :- number(A),number(B),!,(A>B -> R=1 ; R=0).
'mc_2__>'(A,B,['>',A,B]).

%%%%%%%%%%%%%%%%%%%%% lists

'mc_1__car-atom'([H|_],H).

'mc_1__cdr-atom'([_|T],T).

'mc_2__cons-atom'(A,B,[A|B]).

%%%%%%%%%%%%%%%%%%%%% superpose, collapse

'mc_1__superpose'(S,R) :- member(R,S).

% put a fake transpiler_clause_store here, just to force the argument to be lazy
transpiler_clause_store(collapse, 2, 0, ['Atom'], 'Expression', [lazy], eager, [], []).
'mc_1__collapse'(is_p1(Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc_1__collapse'(is_p1(true,X),[X]).

%%%%%%%%%%%%%%%%%%%%% spaces

'mc_2__add-atom'(Space,PredDecl,[]) :- 'add-atom'(Space,PredDecl).

'mc_2__remove-atom'(Space,PredDecl,[]) :- 'remove-atom'(Space,PredDecl).

'mc_1__get-atoms'(Space,Atoms) :- metta_atom(Space, Atoms).

'mc_3__match'(Space,Pattern,Template,Template) :- metta_atom(Space, Atom),Atom=Pattern.

%%%%%%%%%%%%%%%%%%%%% misc

'mc_0__empty'(_) :- fail.

'mc_1__eval'(X,R) :- transpile_eval(X,R).

'mc_1__get-metatype'(X,Y) :- 'get-metatype'(X,Y). % use the code in the interpreter for now

'mc_1__stringToChars'(S,C) :- string_chars(S,C).

'mc_1__charsToString'(C,S) :- string_chars(S,C).

mc_2__assertEqualToResult(A, B, C) :- u_assign([assertEqualToResult, A, B], C).
