:- dynamic(transpiler_predicate_store/4).
:- discontiguous transpiler_predicate_store/4.

from_prolog_args(_,X,X).
:-dynamic(pred_uses_fallback/2).
:-dynamic(pred_uses_impl/2).

pred_uses_impl(F,A):- transpile_impl_prefix(F,A,Fn),current_predicate(Fn/A).

use_interpreter:- fail.
mc_fallback_unimpl(Fn,Arity,Args,Res):- \+ use_interpreter, !,
  (pred_uses_fallback(Fn,Arity); (length(Args,Len), \+ pred_uses_impl(Fn,Len))),!,
    get_operator_typedef_props(_,Fn,Arity,Types,_RetType0),
    current_self(Self),
    maybe_eval(Self,Types,Args,NewArgs),
    [Fn|NewArgs]=Res.

%mc_fallback_unimpl(Fn,_Arity,Args,Res):-  u_assign([Fn|Args], Res).

maybe_eval(_Self,_Types,[],[]):-!.
maybe_eval(Self,[T|Types],[A|Args],[N|NewArgs]):-
    into_typed_arg(30,Self,T,A,N),
    maybe_eval(Self,Types,Args,NewArgs).


%'mc_2__:'(Obj, Type, [':',Obj, Type]):- current_self(Self), sync_type(10, Self, Obj, Type). %freeze(Obj, get_type(Obj,Type)),!.
%sync_type(D, Self, Obj, Type):- nonvar(Obj), nonvar(Type), !, arg_conform(D, Self, Obj, Type).
%sync_type(D, Self, Obj, Type):- nonvar(Obj), var(Type), !, get_type(D, Self, Obj, Type).
%sync_type(D, Self, Obj, Type):- nonvar(Type), var(Obj), !, set_type(D, Self, Obj, Type). %, freeze(Obj, arg_conform(D, Self, Obj, Type)).
%sync_type(D, Self, Obj, Type):- freeze(Type,sync_type(D, Self, Obj, Type)), freeze(Obj, sync_type(D, Self, Obj, Type)),!.


transpiler_predicate_store('get-type', 2, [x(noeval,eager)], x(doeval,eager)).
%'mc_1__get-type'(Obj,Type):-  attvar(Obj),current_self(Self),!,trace,get_attrs(Obj,Atts),get_type(10, Self, Obj,Type).
'mc_1__get-type'(Obj,Type):- current_self(Self), !, get_type(10, Self, Obj,Type).

%%%%%%%%%%%%%%%%%%%%% arithmetic

transpiler_predicate_store('+', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__+'(A,B,R) :- number(A),number(B),!,plus(A,B,R).
'mc_2__+'(A,B,['+',A,B]).

transpiler_predicate_store('-', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__-'(A,B,R) :- number(A),number(B),!,plus(B,R,A).
'mc_2__-'(A,B,['-',A,B]).

transpiler_predicate_store('*', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__*'(A,B,R) :- number(A),number(B),!,R is A*B.
'mc_2__*'(A,B,['*',A,B]).

%%%%%%%%%%%%%%%%%%%%% logic

transpiler_predicate_store('and', 3, [x(doeval,eager), x(doeval,lazy)], x(doeval,eager)).
mc_2__and(A,B,C) :- atomic(A), A\=='False', A\==0, !, as_p1_exec(B,C).
mc_2__and(_,_,'False').
compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :-
  Convert = ['and',A,B],!,
  LazyEval=x(doeval,eager),
  % eval case
  f2p(HeadIs,LazyVars,AResult,AResultN,LazyRetA,A,ACode,ACodeN),
  lazy_impedance_match(LazyRetA,x(doeval,eager),AResult,ACode,AResultN,ACodeN,AResult1,ACode1),
  f2p(HeadIs,LazyVars,BResult,BResultN,LazyRetB,B,BCode,BCodeN),
  lazy_impedance_match(LazyRetB,x(doeval,eager),BResult,BCode,BResultN,BCodeN,BResult1,BCode1),
  append(ACode1,[[native(is_True),AResult1]],ATest),
  append(BCode1,[[assign,RetResult,BResult1]],BTest),
  CodeIf=[[prolog_if,ATest,BTest,[[assign,RetResult,'False']]]],
  Converted=CodeIf,
  % noeval case
  maplist(f2p(HeadIs,LazyVars), _RetResultsParts, RetResultsPartsN, LazyResultParts, Convert, _ConvertedParts, ConvertedNParts),
  f2p_do_group(x(noeval,eager),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
  assign_or_direct_var_only(NoEvalCodeCollected,RetResultN,list(NoEvalRetResults),ConvertedN).

transpiler_predicate_store('or', 3, [x(doeval,eager), x(doeval,lazy)], x(doeval,eager)).
mc_2__or(A,B,C):- (\+ atomic(A); A='False'; A=0), !, as_p1_exec(B,C).
mc_2__or(_,_,'True').
compile_flow_control(HeadIs,LazyVars,RetResult,RetResultN,LazyEval,Convert, Converted, ConvertedN) :-
  Convert = ['or',A,B],!,
  LazyEval=x(doeval,eager),
  % eval case
  f2p(HeadIs,LazyVars,AResult,AResultN,LazyRetA,A,ACode,ACodeN),
  lazy_impedance_match(LazyRetA,x(doeval,eager),AResult,ACode,AResultN,ACodeN,AResult1,ACode1),
  f2p(HeadIs,LazyVars,BResult,BResultN,LazyRetB,B,BCode,BCodeN),
  lazy_impedance_match(LazyRetB,x(doeval,eager),BResult,BCode,BResultN,BCodeN,BResult1,BCode1),
  append(ACode1,[[native(is_True),AResult1]],ATest),
  append(BCode1,[[assign,RetResult,BResult1]],BTest),
  CodeIf=[[prolog_if,ATest,[[assign,RetResult,'True']],BTest]],
  Converted=CodeIf,
  % noeval case
  maplist(f2p(HeadIs,LazyVars), _RetResultsParts, RetResultsPartsN, LazyResultParts, Convert, _ConvertedParts, ConvertedNParts),
  f2p_do_group(x(noeval,eager),LazyResultParts,RetResultsPartsN,NoEvalRetResults,ConvertedNParts,NoEvalCodeCollected),
  assign_or_direct_var_only(NoEvalCodeCollected,RetResultN,list(NoEvalRetResults),ConvertedN).

%transpiler_predicate_store('and', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
%mc_2__and(A,B,B) :- atomic(A), A\=='False', A\==0, !.
%mc_2__and(_,_,'False').

%transpiler_predicate_store('or', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
%mc_2__or(A,B,B):- (\+ atomic(A); A='False'; A=0), !.
%mc_2__or(_,_,'True').

transpiler_predicate_store('not', 2, [x(doeval,eager)], x(doeval,eager)).
mc_1__not(A,'False') :- atomic(A), A\=='False', A\==0, !.
mc_1__not(_,'True').

%%%%%%%%%%%%%%%%%%%%% comparison

% not sure about the signature for this one
transpiler_predicate_store('==', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__=='(A,A,1) :- !.
'mc_2__=='(_,_,0).

transpiler_predicate_store('<', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__<'(A,B,R) :- number(A),number(B),!,(A<B -> R='True' ; R='False').
'mc_2__<'(A,B,['<',A,B]).

transpiler_predicate_store('>', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__>'(A,B,R) :- number(A),number(B),!,(A>B -> R='True' ; R='False').
'mc_2__>'(A,B,['>',A,B]).

transpiler_predicate_store('>=', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__>='(A,B,R) :- number(A),number(B),!,(A>=B -> R='True' ; R='False').
'mc_2__>='(A,B,['>=',A,B]).

transpiler_predicate_store('<=', 3, [x(doeval,eager), x(doeval,eager)], x(doeval,eager)).
'mc_2__<='(A,B,R) :- number(A),number(B),!,(A=<B -> R='True' ; R='False'). % note that Prolog has a different syntax '=<'
'mc_2__<='(A,B,['<=',A,B]).

%%%%%%%%%%%%%%%%%%%%% lists

transpiler_predicate_store('car-atom', 2, [x(noeval,eager)], x(noeval,eager)).
'mc_1__car-atom'([H|_],H).

transpiler_predicate_store('cdr-atom', 2, [x(noeval,eager)], x(noeval,eager)).
'mc_1__cdr-atom'([_|T],T).

transpiler_predicate_store('cons-atom', 3, [x(noeval,eager), x(noeval,eager)], x(noeval,eager)).
'mc_2__cons-atom'(A,B,[A|B]).

transpiler_predicate_store('decons-atom', 2,  [x(noeval,eager)], x(noeval,eager)).
'mc_1__decons-atom'([A|B],[A,B]).

%%%%%%%%%%%%%%%%%%%%% set

lazy_member(P,R2) :- as_p1_exec(R2,P).

transpiler_predicate_store(subtraction, 3, [x(doeval,lazy),x(doeval,lazy)], x(doeval,eager)).
'mc_2__subtraction'(P1,P2,S) :- as_p1_exec(P1,S), \+ lazy_member(S,P2).

transpiler_predicate_store(union, 3, [x(doeval,lazy),x(doeval,lazy)], x(doeval,eager)).
'mc_2__union'(U1,U2,R) :- 'mc_2__subtraction'(U1,U2,R) ; as_p1_exec(U2,R).

%%%%%%%%%%%%%%%%%%%%% superpose, collapse

transpiler_predicate_store(superpose, 2, [x(doeval,eager)], x(doeval,eager)).
'mc_1__superpose'(S,R) :- member(R,S).

transpiler_predicate_store(collapse, 2, [x(doeval,lazy)], x(doeval,eager)).
'mc_1__collapse'(ispu(X),[X]).
'mc_1__collapse'(ispuU(Ret,Code),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc_1__collapse'(ispuU(X,true),[X]) :- !.
'mc_1__collapse'(ispuU(A,Code),X) :- atom(A),findall(_,Code,X),maplist(=(A),X).
'mc_1__collapse'(ispen(Ret,Code,_),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc_1__collapse'(ispeEn(X,true,_),[X]) :- !.
'mc_1__collapse'(ispeEn(A,Code,_),X) :- atom(A),findall(_,Code,X),maplist(=(A),X).
'mc_1__collapse'(ispeEnN(Ret,Code,_,_),R) :- fullvar(Ret),!,findall(Ret,Code,R).
'mc_1__collapse'(ispeEnN(X,true,_,_),[X]) :- !.
'mc_1__collapse'(ispeEnN(A,Code,_,_),X) :- atom(A),findall(_,Code,X),maplist(=(A),X).
'mc_1__collapse'(ispeEnNC(Ret,Code,_,_,Common),R) :- fullvar(Ret),!,findall(Ret,(Common,Code),R).
'mc_1__collapse'(ispeEnNC(A,Code,_,_,Common),X) :- atom(A),findall(_,(Common,Code),X),maplist(=(A),X).
%'mc_1__collapse'(is_p1(_Type,_Expr,Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
%'mc_1__collapse'(is_p1(_Type,_Expr,true,X),[X]) :- !.
%'mc_1__collapse'(is_p1(_,Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
%'mc_1__collapse'(is_p1(_,true,X),[X]).
%'mc_1__collapse'(is_p1(Code,Ret),R) :- fullvar(Ret),!,findall(Ret,Code,R).
%'mc_1__collapse'(is_p1(true,X),[X]).

%%%%%%%%%%%%%%%%%%%%% spaces

transpiler_predicate_store('add-atom', 3, [x(doeval,eager), x(noeval,eager)], x(doeval,eager)).
'mc_2__add-atom'(Space,PredDecl,[]) :- 'add-atom'(Space,PredDecl).

transpiler_predicate_store('remove-atom', 3, [x(doeval,eager), x(noeval,eager)], x(doeval,eager)).
'mc_2__remove-atom'(Space,PredDecl,[]) :- 'remove-atom'(Space,PredDecl).

transpiler_predicate_store('get-atoms', 2, [x(noeval,eager)], x(noeval,eager)).
'mc_1__get-atoms'(Space,Atoms) :- metta_atom(Space, Atoms).

% This allows match to supply hits to the correct metta_atom/2 (Rather than sending a variable
match_pattern(Space, Pattern):-
    if_t(compound(Pattern),
       (functor(Pattern,F,A,Type), functor(Atom,F,A,Type))),
    metta_atom(Space, Atom), Atom=Pattern.

transpiler_predicate_store(match, 4, [x(doeval,eager), x(doeval,eager), x(doeval,lazy)], x(doeval,eager)).
'mc_3__match'(Space,Pattern,P1,Ret) :- match_pattern(Space, Atom),Atom=Pattern,as_p1_exec(P1,Ret).

% unify calls pattern matching if arg1 is a space
unify_pattern(Space,Pattern):- is_metta_space(Space),!, match_pattern(Space, Pattern).
% otherwise calls prolog unification (with occurs check later)
unify_pattern(Atom, Pattern):- metta_unify(Atom, Pattern).

metta_unify(Atom, Pattern):- Atom=Pattern.

% TODO FIXME: sort out the difference between unify and match
transpiler_predicate_store(unify, 4, [x(doeval,eager), x(doeval,eager), x(doeval,lazy)], x(doeval,eager)).
'mc_3__unify'(Space,Pattern,P1,Ret) :- unify_pattern(Space, Atom),Atom=Pattern,as_p1_exec(P1,Ret).

transpiler_predicate_store(unify, 5, [x(doeval,eager), x(doeval,eager), x(doeval,lazy), x(doeval,lazy)], x(doeval,eager)).
'mc_4__unify'(Space,Pattern,Psuccess,PFailure,RetVal) :-
    (unify_pattern(Space,Pattern) -> as_p1_exec(Psuccess,RetVal) ; as_p1_exec(PFailure,RetVal)).

%%%%%%%%%%%%%%%%%%%%% misc

transpiler_predicate_store(time, 2, [x(doeval,lazy)], x(doeval,eager)).
'mc_1__time'(P,Ret) :- wtime_eval(as_p1_exec(P,Ret)).

transpiler_predicate_store(empty, 1, [], x(doeval,eager)).
'mc_0__empty'(_) :- fail.

transpiler_predicate_store('eval', 2, [x(noeval,eager)], x(doeval,eager)).
'mc_1__eval'(X,R) :- transpile_eval(X,R).

transpiler_predicate_store('get-metatype', 2, [x(noeval,eager)], x(doeval,eager)).
'mc_1__get-metatype'(X,Y) :- 'get-metatype'(X,Y). % use the code in the interpreter for now

transpiler_predicate_store('println!', 2, [x(doeval,eager)], x(doeval,eager)).
'mc_1__println!'(X,[]) :- println_impl(X).

transpiler_predicate_store('stringToChars', 2, [x(doeval,eager)], x(doeval,eager)).
'mc_1__stringToChars'(S,C) :- string_chars(S,C).

transpiler_predicate_store('charsToString', 2, [x(doeval,eager)], x(doeval,eager)).
'mc_1__charsToString'(C,S) :- string_chars(S,C).

transpiler_predicate_store('assertEqualToResult', 3, [x(doeval,eager),x(noeval,eager)], x(doeval,eager)).
'mc_2__assertEqualToResult'(A, B, C) :- u_assign([assertEqualToResult, A, B], C).

transpiler_predicate_store('prolog-trace', 1, [], x(doeval,eager)).
'mc_0__prolog-trace'([]) :- trace.

transpiler_predicate_store('quote', 2, [x(noeval,eager)], x(noeval,eager)).
'mc_1__quote'(A,['quote',A]).
