(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2009-10-16

unary TRS reversing
*)

Set Implicit Arguments.

Require Import Srs.
Require Import ATrs.
Require Import SReverse.
Require Import ATerm_of_String.
Require Import String_of_ATerm.
Require Import AUnary.
Require Import SN.
Require Import LogicUtil.
Require Import AMorphism.
Require Import EqUtil.
Require Import NatUtil.
Require Import ListUtil.

Section S.

Variable Sig : Signature.
Variable is_unary_sig : is_unary Sig.

Notation term := (term Sig).
Notation rule := (rule Sig). Notation rules := (list rule).
Notation SSig := (SSig_of_ASig Sig). Notation Sig' := (ASig_of_SSig SSig).

Lemma is_unary_sig' : is_unary Sig'.

Proof.
intro f. refl.
Qed.

Definition F (f : Sig) : Sig' := f.

Lemma HF : forall f, arity f = arity (F f).

Proof.
intro. rewrite <- is_unary_sig. refl.
Qed.

Definition G (f : Sig') : Sig := f.

Lemma HG : forall f, arity f = arity (G f).

Proof.
intro. rewrite <- is_unary_sig. refl.
Qed.

Lemma FG : forall f, F (G f) = f.

Proof.
refl.
Qed.

Lemma GF : forall f, G (F f) = f.

Proof.
refl.
Qed.

Require Import VecUtil.

Lemma term_of_string_epi : forall t, maxvar t = 0 ->
  ATerm_of_String.term_of_string (string_of_term t) = Ft HF t.

Proof.
intro t; pattern t; apply (term_ind_forall is_unary_sig); clear t; intros.
simpl. simpl in H. subst. refl.
rewrite string_of_term_fun1. unfold ATerm_of_String.term_of_string;
fold (ATerm_of_String.term_of_string (string_of_term t)).
rewrite H. unfold Fun1. unfold Ft at -1. rewrite Vmap_cast. rewrite Vcast_cast.
simpl Vmap. apply args_eq. rewrite Vcast_refl. refl.
rewrite maxvar_fun1 in H0. hyp.
Qed.

Lemma rule_of_srule_epi : forall a, maxvar (lhs a) = 0 -> maxvar (rhs a) = 0 ->
  rule_of_srule (srule_of_rule a) = Fr HF a.

Proof.
intros [l r] hl hr. unfold rule_of_srule, srule_of_rule. simpl.
repeat rewrite term_of_string_epi; try hyp. refl.
Qed.

Lemma trs_of_srs_epi : forall R,
  (forall a, In a R -> maxvar (lhs a) = 0 /\ maxvar (rhs a) = 0) ->
  trs_of_srs (srs_of_trs R) = Fl HF R.

Proof.
induction R; intros. refl. simpl. rewrite IHR.
assert (In a (a::R)). simpl. auto. destruct (H _ H0).
rewrite rule_of_srule_epi; try hyp. refl.
intros b h. assert (In b (a::R)). simpl. auto. destruct (H _ H0). intuition.
Qed.

Definition reverse_term (t : term) :=
  ATerm_of_String.term_of_string (ListUtil.rev' (string_of_term t)).

Definition reverse_rule (e : rule) :=
  let (l,r) := e in mkRule (reverse_term l) (reverse_term r).

Definition reverse_trs := List.map reverse_rule.

Notation reverse_srule := (@SReverse.reverse SSig).
Notation reverse_srs := (List.map reverse_srule).

Lemma var_reverse_term : forall t, var (reverse_term t) = 0.

Proof.
intro t; pattern t; apply (term_ind_forall is_unary_sig); clear t; intros.
refl. unfold reverse_term. rewrite string_of_term_fun1. rewrite rev'_cons.
rewrite term_of_string_app. change (var
  (sub (@ATerm_of_String.sub_of_string SSig (f :: nil)) (reverse_term t)) = 0).
rewrite var_sub. 2: apply is_unary_sig'. rewrite H. refl.
Qed.

Lemma rules_preserv_vars_reverse_trs :
  forall R, rules_preserv_vars R -> rules_preserv_vars (reverse_trs R).

Proof.
induction R; intros. unfold rules_preserv_vars. simpl. tauto.
simpl. revert H. repeat rewrite rules_preserv_vars_cons. destruct a as [l r].
simpl. intuition. repeat rewrite vars_var; try (hyp||apply is_unary_sig').
repeat rewrite var_reverse_term. intuition.
Qed.

Lemma trs_of_srs_reverse_trs : forall R,
  trs_of_srs (reverse_srs (srs_of_trs R)) = reverse_trs R.

Proof.
induction R. refl. simpl. destruct a as [l r]. unfold rule_of_srule. simpl.
rewrite IHR. refl.
Qed.

Lemma reverse_term_reset : forall t, reverse_term (reset t) = reverse_term t.

Proof.
intro t; pattern t; apply (term_ind_forall is_unary_sig); clear t; intros.
unfold reset, swap, single. simpl. rewrite (beq_refl beq_nat_ok). refl.
rewrite reset_fun1. unfold reverse_term. repeat rewrite string_of_term_fun1.
rewrite string_of_term_reset. refl. hyp.
Qed.

Lemma reset_reverse_term : forall t, reset (reverse_term t) = reverse_term t.

Proof.
intro t; pattern t; apply (term_ind_forall is_unary_sig); clear t; intros.
refl. unfold reverse_term. repeat rewrite string_of_term_fun1.
rewrite reset_term_of_string. refl.
Qed.

Lemma reverse_trs_reset_rules : forall R,
  reverse_trs (reset_rules R) = reset_rules (reverse_trs R).

Proof.
induction R. refl. simpl. destruct a as [l r]. simpl.
repeat rewrite reverse_term_reset. rewrite IHR. unfold reset_rule. simpl.
repeat rewrite reset_reverse_term. refl.
Qed.

Variables E R : rules.
Variable hE : rules_preserv_vars E.
Variable hR : rules_preserv_vars R.

Lemma WF_reverse :
  WF (red_mod (reverse_trs E) (reverse_trs R)) <-> WF (red_mod E R).

Proof.
intros. symmetry. rewrite red_mod_reset_eq; try hyp.
rewrite String_of_ATerm.WF_conv; try apply rules_preserv_vars_reset; try hyp.
rewrite <- WF_reverse_eq. rewrite ATerm_of_String.WF_conv; try hyp.
repeat rewrite trs_of_srs_reverse_trs. repeat rewrite reverse_trs_reset_rules.
rewrite <- red_mod_reset_eq. refl. apply is_unary_sig'.
apply rules_preserv_vars_reverse_trs; hyp.
apply rules_preserv_vars_reverse_trs; hyp.
Qed.

End S.