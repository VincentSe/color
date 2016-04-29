(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2005-06-10

algebraic terms with no arity
*)

Set Implicit Arguments.

From CoLoR Require Import LogicUtil BoolUtil ListUtil EqUtil ListDec.
From Coq Require Import Peano_dec.
From CoLoR Require Export VSignature.
From Coq Require Export List.

Section S.

Variable Sig : Signature.

(***********************************************************************)
(* terms *)

(*COQ: we do not use the induction principle generated by Coq since it
     is not good because the argument of Fun is a list *)

Unset Elimination Schemes.

Inductive term : Type :=
  | Var : variable -> term
  | Fun : forall f : Sig, list term -> term.

Set Elimination Schemes.

Notation terms := (list term).

(***********************************************************************)
(** induction principle *)

Section term_rect.

Variables
  (P : term -> Type)
  (Q : terms -> Type)
  (H1 : forall x, P (Var x))
  (H2 : forall f v, Q v -> P (Fun f v))
  (H3 : Q nil)
  (H4 : forall t v, P t -> Q v -> Q (t :: v)).

Fixpoint term_rect t : P t :=
  match t as t return P t with
    | Var x => H1 x
    | Fun f v => H2 f
      ((fix vt_rect (v : terms) : Q v :=
        match v as v return Q v with
          | nil => H3
          | cons t' v' => H4 (term_rect t') (vt_rect v')
        end) v)
  end.

End term_rect.

Definition term_ind (P : term -> Prop) (Q : terms -> Prop) := term_rect P Q.

From CoLoR Require Import ListForall.

Lemma term_ind_forall : forall (P : term -> Prop)
  (H1 : forall x, P (Var x))
  (H2 : forall f v, lforall P v -> P (Fun f v)),
  forall t, P t.

Proof.
  intros. apply term_ind with (Q := fun v => lforall P v).
  hyp. hyp. constructor.
  intros. apply lforall_intro. intros.
  destruct H3. subst t0. hyp.
  apply lforall_in with term v; hyp. 
Qed.

Lemma term_ind_forall2 : forall (P : term -> Prop)
  (H1 : forall x, P (Var x))
  (H2 : forall f v, (forall t, In t v -> P t) -> P (Fun f v)),
  forall t, P t.

Proof.
intros. apply term_ind with (Q := fun v => forall t, In t v -> P t); simpl.
hyp. hyp. intros. contr.
intros. destruct H3. subst. hyp. apply H0. hyp.
Qed.

Section term_rec_forall.

Variable term_eq_dec : forall t u : term, {t=u} + {t<>u}.

Lemma term_rect_forall : forall (P : term -> Type)
  (H1 : forall x, P (Var x))
  (H2 : forall f v, (forall t, Inb term_eq_dec t v = true -> P t) ->
    P (Fun f v)),
  forall t, P t.

Proof.
intros. apply term_rect with 
  (Q := fun v => forall t, Inb term_eq_dec t v = true -> P t); simpl.
hyp. hyp. intros. discr.
intros. destruct (term_eq_dec t1 t0). subst t1. hyp. 
apply X0. hyp.
Qed.

End term_rec_forall.

(***********************************************************************)
(** equality *)

Lemma term_eq : forall f f' v v', f = f' -> v = v' -> Fun f v = Fun f' v'.

Proof. intros. rewrite H, H0. refl. Qed.

Lemma fun_eq : forall f f' v, f = f' -> Fun f v = Fun f' v.

Proof. intros. rewrite H. refl. Qed.

Lemma args_eq : forall f v v', v = v' -> Fun f v = Fun f v'.

Proof. intros. rewrite H. refl. Qed.

From CoLoR Require Import NatUtil.

Fixpoint beq (t u : term) :=
  match t with
    | Var x =>
      match u with
        | Var y => beq_nat x y
        | _ => false
      end
    | Fun f ts =>
      match u with
        | Fun g us =>
          let fix beq_terms (ts us : terms) :=
            match ts with
              | nil =>
                match us with
                  | nil => true
                  | _ => false
                end
              | t :: ts' =>
                match us with
                  | u :: us' => beq t u && beq_terms ts' us'
                  | _ => false
                end
            end
            in beq_symb f g && beq_terms ts us
        | _ => false
      end
  end.

Lemma beq_terms : forall ts us,
  (fix beq_terms (ts us : terms) :=
    match ts with
      | nil =>
        match us with
          | nil => true
          | _ => false
        end
      | t :: ts' =>
        match us with
          | u :: us' => beq t u && beq_terms ts' us'
          | _ => false
        end
    end) ts us = beq_list beq ts us.

Proof. induction ts; destruct us; refl. Qed.

Lemma beq_fun : forall f ts g us,
  beq (Fun f ts) (Fun g us) = beq_symb f g && beq_list beq ts us.

Proof. intros. rewrite <- beq_terms. refl. Qed.

Lemma beq_ok : forall t u, beq t u = true <-> t = u.

Proof.
intro t. pattern t. apply term_ind_forall2; destruct u.
simpl. rewrite beq_nat_ok. intuition. inversion H. refl.
intuition; discr. intuition; discr.
rewrite beq_fun. split; intro. destruct (andb_elim H0).
rewrite beq_symb_ok in H1. subst f0.
rewrite beq_list_ok_in in H2. subst l. refl. exact H.
inversion H0. apply andb_intro. apply (beq_refl (@beq_symb_ok Sig)).
ded (beq_list_ok_in H). subst v. rewrite H1. refl.
Qed.

Definition term_eq_dec := dec_beq beq_ok.

(***********************************************************************)
(** maximal index of a variable *)

From CoLoR Require Import ListMax.

Fixpoint maxvar (t : term) : nat :=
  match t with
    | Var x => x
    | Fun f v => lmax (map maxvar v)
  end.

Lemma maxvar_var : forall k x, maxvar (Var x) <= k -> x <= k.

Proof.
intros. simpl. intuition.
Qed.

Definition maxvar_le k t := maxvar t <= k.

End S.

Arguments Var [Sig] _.
Arguments maxvar_var [Sig k x] _.
