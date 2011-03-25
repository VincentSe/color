(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Sidi Ould-Biha & Frederic Blanqui, 2010-05-04

Usable rules from:

Tyrolean Termination Tool: Techniques and Features
Nao Hirokawa and Aart Middeldorp
Information and Computation 205(4), pp. 474 – 511, 2007
*)

Set Implicit Arguments.

Require Import ATrs RelUtil ClassicUtil LogicUtil ARelation ClassicalEpsilon
  NatUtil SN ASN BoolUtil VecUtil ListUtil AReduct ACalls ADP ADepRel AInfSeq.

(***********************************************************************)
(** weak reduction pair *)

Record weakRedPairType (Sig : Signature) : Type := mkWP {
  succ : relation (@term Sig);
  bsucc : @term Sig -> @term Sig -> bool;
  succeq : relation (@term Sig);
  bsucceq : @term Sig -> @term Sig -> bool;
  wf_succ : forall f, ~IS succ f;
  sc_succ : substitution_closed succ;
  bsucc_sub : rel bsucc << succ;
  sc_succeq : substitution_closed succeq;
  cc_succeq : context_closed succeq;
  refl_succeq : reflexive succeq;
  trans_succeq : transitive succeq;
  trans_succ : transitive succ;
  succ_succeq_compat : absorb succ succeq;
  bsucceq_sub : rel bsucceq << succeq
}.

(***********************************************************************)
(** definition of the set of usable rules *)

Section UsableRulesDef.

Variable Sig : Signature.

Notation term := (term Sig). Notation terms := (vector term).
Notation rule := (rule Sig). Notation rules := (list rule).

(*

(* function computing all the successors of a defined symbol in the
  reflexive and transitive closure of the dependency relation symb_ord *)

(* version using RelDec: inefficient *)

Require Import RelSub RelDec.

Lemma succs_symb_proof_tc : forall (R : rules) (f : Sig),
  {l : list Sig | forall g, In g l <-> (symb_ord R)! f g}.

Proof.
intros R f.
pose (symb_ord_dom :=
 root_lhs_rules R ++ flat_map (fun x => symb_ord_img R x) (root_lhs_rules R)).
assert (symb_ord_domP : is_restricted (symb_ord R) symb_ord_dom).
intros x y Hxy. unfold symb_ord_dom. rewrite in_app. split.
left. destruct Hxy as [a [H0 [H1 H2]]]. rewrite root_lhsP.
exists a; auto.
rewrite in_app, in_flat_map; right. exists x. split.
destruct Hxy as [a [H0 [H1 H2]]]. rewrite root_lhsP. exists a; auto.
rewrite symb_ord_imgP. auto.
assert (trs_dec : rel_dec (symb_ord R !)).
apply restricted_dec_clos_trans_dec with (l := symb_ord_dom); auto.
intros x y. destruct (eq_symb_dec x y); auto.
apply symb_ord_dec.
pose (P := fun x => if (trs_dec f x) then true else false).
pose (ls := filter P (list_defined R)).
exists ls. intro. split; intro.
unfold ls, P in H; rewrite filter_In in H. destruct H.
destruct (trs_dec f g); auto. inversion H0.
unfold ls, P. rewrite filter_In. destruct (trs_dec f g); try tauto.
split; auto. clear c.
induction H; auto. destruct H as [a [H0 [H1 H2]]].
unfold def_symbs in H2; rewrite filter_In in H2. destruct H2 as [_ H2].
apply defined_list_ok; auto.
Defined.

(* version using TransClosure in Coccinelle: inefficient too

Require Import TransClosure.

Lemma trans_clos_equiv : forall A (R : relation A) x y,
  trans_clos R x y <-> R! x y.

Proof.
intros; split; intro.
induction H. apply tc_incl; auto.
apply tc_trans with (y := y); auto. apply tc_incl; auto.
induction H. apply t_step; auto. apply trans_clos_is_trans with (b := y); auto.
Qed.

Lemma succs_symb_proof_tc : forall (R : rules) (f : Sig),
  {l : list Sig | forall g, In g l <-> (symb_ord R)! f g}.

Proof.
intros R f.
cut ({l : list Sig | forall g : Sig, In g l <-> trans_clos (symb_ord R) f g}).
intros. destruct X. exists x. intros. 
rewrite <- trans_clos_equiv with (R := symb_ord R). auto.
pose (symb_ord_dom := flat_map
  (fun x => map (fun y => (x, y)) (symb_ord_img R x)) (root_lhs_rules R)).
assert (trs_dec : rel_dec (trans_clos (symb_ord R))).
intros x y. apply trans_clos_dec with (eq_bool := (@beq_symb Sig))
 (Rlist := symb_ord_dom).
intros. case_eq (beq_symb a b). rewrite beq_symb_ok in H; auto.
intro. rewrite <- beq_symb_ok, H in H0. inversion H0.
intros a b; split; unfold symb_ord_dom; intro Hab.
destruct Hab. apply in_flat_map. exists a; split.
apply root_lhsP. exists x0; tauto.
apply in_map. apply symb_ord_imgP. exists x0; auto.
rewrite in_flat_map in Hab. destruct Hab as [x0 [H1 H2]].
rewrite in_map_iff in H2. destruct H2 as [x1 [Hx1 Hx2]].
inversion Hx1. subst. apply symb_ord_imgP; auto.
pose (P := fun x => if (trs_dec f x) then true else false).
pose (ls := filter P (list_defined R)).
exists ls. intro. split; intro.
unfold ls, P in H; rewrite filter_In in H. destruct H.
destruct (trs_dec f g); auto. inversion H0.
unfold ls, P. rewrite filter_In. destruct (trs_dec f g); try tauto.
split; auto.
induction H; auto. destruct H as [a [H0 [H1 H2]]].
unfold def_symbs in H2; rewrite filter_In in H2. destruct H2 as [_ H2].
apply defined_list_ok; auto.
Defined.*)

Lemma succs_symb_proof : forall (R : rules) (f : Sig),
  {l : list Sig | forall g, In g l <-> (symb_ord R)# f g}.

Proof.
intros. destruct (succs_symb_proof_tc R f) as [l' Hl].
exists (f :: l'). intro. split; intro.
destruct (in_inv H). subst. apply rtc_refl.
apply tc_incl_rtc. apply Hl; auto.
apply In_cons; destruct (rtc_split H). subst; auto.
right. apply Hl; auto.
Defined.

Definition succs_symb R f : list Sig := projT1 (succs_symb_proof R f).
Definition succs_symbP R f := projT2 (succs_symb_proof R f).

*)

Variables (succs_symb : rules -> Sig -> list Sig)
  (succs_symbP : forall R f g, In g (succs_symb R f) <-> symb_ord R# f g).

Fixpoint succs_symbs R (fs : list Sig) : list Sig :=
  match fs with
    | nil => nil
    | f :: fs' => succs_symb R f ++ succs_symbs R fs'
  end.

Definition rrules_list R (G : Sig -> bool) :=
  filter (fun x => match lhs x with Fun f _ => G f | _ => false end) R.

(*IMPROVE:
1) replace Inb by ListDec.mem
2) define usable rules as a set, assuming a total ordering on rules?
*)

Definition tusable_rules R t := rrules_list R
  (fun f => Inb (@eq_symb_dec Sig) f (succs_symbs R (def_symbs R t))).

Fixpoint usable_rules R (C : rules) : rules :=
  match C with
    | nil => nil
    | c :: C' => tusable_rules R (rhs c) ++ usable_rules R C'
  end.

(***********************************************************************)
(** properties of the set of usable rules *)

Lemma in_succs_symbs : forall R l f, In f (succs_symbs R l) <->
  exists g, In g l /\ In f (succs_symb R g).

Proof.
intros. induction l. simpl; split; try tauto. intro. destruct H. tauto.
unfold succs_symbs. rewrite in_app. split; intro. destruct H.
exists a. split; auto. rewrite In_cons; auto.
rewrite IHl in H. destruct H as [h H]. exists h. intuition.
destruct H as [g H]. destruct H as [H0 H]. destruct H0. subst. auto.
right. rewrite IHl. exists g. auto.
Qed.

Lemma tusable_rules_incl : forall R t, tusable_rules R t [= R.

Proof.
intros. apply filter_incl.
Qed.

Lemma In_tusable : forall R t f v r,
  In (mkRule (Fun f v) r) (tusable_rules R t)
  <-> In (mkRule (Fun f v) r) R
      /\ exists g, In g (def_symbs R t) /\ (symb_ord R)# g f.

Proof.
intros. unfold tusable_rules, rrules_list. rewrite filter_In. split; intro.
destruct H. split; auto. simpl in H0. generalize (Inb_true _ _ _ H0).
rewrite in_succs_symbs. intro. destruct H1 as [g H1]. destruct H1 as [H1 H2].
exists g. split; auto. rewrite (succs_symbP R g f) in H2. intuition.
simpl. destruct H. split; auto. apply Inb_intro. rewrite in_succs_symbs.
destruct H0 as [g H0]; destruct H0. exists g. split; auto.
rewrite (succs_symbP R g f); auto.
Qed.

Lemma usable_rules_incl : forall R C, usable_rules R C [= R.

Proof.
intros. induction C; simpl. apply incl_nil.
intro x. rewrite in_app; intro H. destruct H.
apply (tusable_rules_incl R (rhs a)); auto. apply IHC; auto.
Qed.

Lemma In_usable : forall R C l r,
  In (mkRule l r) (usable_rules R C)
  <-> exists a, In a C /\ In (mkRule l r) (tusable_rules R (rhs a)).

Proof.
intros. induction C; simpl. split; try tauto.
intro H; destruct H as [? [? H]]; auto.
rewrite in_app. split; intro H; destruct H. exists a. intuition.
rewrite IHC in H. destruct H. exists x. intuition.
destruct H. destruct H. subst. auto.
rewrite IHC. right. exists x. intuition.
Qed.

Lemma defined_uc : forall f R C t1 t2,
  (In (mkRule t1 t2) C /\ defined f (tusable_rules R t2) = true)
  -> defined f (usable_rules R C) = true.

Proof.
intros. induction C. simpl; simpl in H. tauto. simpl. simpl in H.
destruct H. rewrite defined_app. destruct H. subst. simpl; rewrite H0. auto.
rewrite IHC; auto. rewrite orb_true_r. auto.
Qed.

Variables (R C : rules).

Notation UC := (usable_rules R C).
Notation G := (fun f => defined f R && negb (defined f UC)).

Lemma urules_equiv :
  forallb (@is_notvar_lhs Sig) R = true -> R [=] UC ++ rrules_list R G.

Proof.
intro L; split; intros x Hx. rewrite in_app. unfold rrules_list.
induction C. simpl. right. rewrite filter_In. split; auto.
destruct x as [x1 x2]. simpl. destruct x1.
rewrite forallb_forall in L; generalize (L _ Hx). auto.
rewrite (lhs_fun_defined f v x2 R Hx); auto.
destruct IHl. left. simpl. rewrite in_app; auto.
rewrite filter_In; rewrite filter_In in H; destruct H as [_ H].
destruct x as [x1 x2]. simpl; simpl in H. rewrite in_app.
destruct x1; auto. rewrite defined_app, orb_comm, negb_orb, andb_assoc.
rewrite H; simpl. case_eq (defined f (tusable_rules R (rhs a))); auto.
left; left. unfold tusable_rules, rrules_list. rewrite filter_In.
split; auto. simpl. destruct (proj1 (defined_equiv _ _) H0) as [v1 H1].
destruct H1 as [r1 H1]. unfold tusable_rules, rrules_list in H1.
rewrite filter_In in H1. simpl in H1. destruct H1; auto.
rewrite in_app in Hx. destruct Hx. apply (usable_rules_incl R C x); auto.
eapply filter_incl. apply H.
Qed.

Lemma lhs_defsymbG_rec : forall t1 t2 l r, 
  In (mkRule t1 t2) C -> In (mkRule l r) (tusable_rules R t2)
  -> forall f, In f (symbs r) -> G f = false.

Proof.
intros. simpl. case_eq (defined f R); auto. simpl.
destruct l as [ | g v]. unfold tusable_rules, rrules_list in H0.
rewrite filter_In in H0. simpl in H0. intuition.
rewrite In_tusable in H0. symmetry. apply negb_sym. simpl.
apply (defined_uc _ _ _ t1 t2); split; auto.
destruct (proj1 (defined_equiv _ _) H2) as [v' [r' H3]]. destruct H0.
apply (lhs_fun_defined f v' r'). rewrite In_tusable. split; auto.
destruct H4 as [g0 H4]. exists g0. split; try apply (proj1 H4).
apply rtc_trans with (y := g). apply (proj2 H4). apply rt_step.
exists (mkRule (Fun g v) r). split; auto. simpl. rewrite beq_symb_ok.
split; auto. unfold def_symbs. rewrite filter_In. auto.
Qed.

Lemma lhs_defsymbG : forall l r, 
  In (mkRule l r) (usable_rules R C) -> forall f, In f (symbs r) -> G f = false.

Proof.
intros. rewrite In_usable in H. destruct H. destruct x as [x1 x2].
apply lhs_defsymbG_rec with (t1 := x1) (t2 := x2) (l := l) (r := r); auto.
intuition. intuition.
Qed.

Lemma rhsC_defsymbG :
  forall HDPR : forall f, defined f R && defined f C = false,
    forall l r, In (mkRule l r) C -> forall f, In f (symbs r) -> G f = false.

Proof.
intros. simpl. case_eq (defined f R); auto. generalize (HDPR f).
rewrite H1. simpl. intro. symmetry. apply negb_sym. simpl.
destruct (proj1 (defined_equiv _ _) H1) as [v [r' H3]].
apply (defined_uc f R C l r). split; auto.
assert (H4 : In (mkRule (Fun f v) r') (tusable_rules R r)).
rewrite In_tusable; split; auto. exists f; split.
unfold def_symbs; rewrite filter_In; split; auto. apply rt_refl.
rewrite defined_equiv. exists v. exists r'; auto.
Qed.

End UsableRulesDef.

(***********************************************************************)
(** definition of the interpretation function *)

Require Import ABinary ProofIrrelevance.

Section UsableRulesProp.

  Variable Sig : BinSignature.

  Notation P := (proj_cons Sig).

  Notation term := (term Sig). Notation terms := (vector term).
  Notation rule := (rule Sig). Notation rules := (list rule).
  Notation supterm := (@supterm Sig).

  Variables (R : rules) (HR : rules_preserve_vars R)

    (* for the function reducts to return the list of all reducts *)
    (NVlR : forallb (@is_notvar_lhs Sig) R = true).

  Lemma SN_reducts_def : forall t f v, SN (red R U supterm) t ->
    t = Fun f v -> forall i, i < length (reducts R (Fun f v)) ->
      SN (red R U supterm) (nth i (reducts R (Fun f v)) (Fun f v)).

  Proof.
    intros t f v SNt Et i Hi. destruct SNt as [H]. apply H. left.
    apply reducts_correct. rewrite Et. apply nth_In. auto.
  Defined.

  Lemma SN_subs_def : forall t f v, SN (red R U supterm) t ->
    t = Fun f v -> forall i (Hi : i < arity f),
      SN (red R U supterm) (Vnth v Hi).

  Proof.
    intros t f v SNt Et i Hi. destruct SNt as [H]. apply H. right. rewrite Et.
    apply subterm_fun. apply Vnth_in.
  Defined.

  Section Def.

    Variable G : Sig -> bool.

    Fixpoint interp_rec t (Ht : SN (red R U supterm) t) {struct Ht} :=
      match t as t0 return t = t0 -> term with
        | Var n => fun _ : t = Var n => Var n
        | Fun f v => fun H : t = Fun f v =>
          let fIv := Fun f (Vbuild (fun i (Hi : i < arity f) =>
            interp_rec (SN_subs_def Ht H Hi))) in
          let vr := Vbuild (fun i (Hi : i < length (reducts R (Fun f v))) =>
            interp_rec (SN_reducts_def Ht H Hi)) in
          if G f then cons_term _ fIv vr else fIv
      end (refl_equal t).

    Lemma interp_rec_eq : forall x y
      (Hx : SN (red R U supterm) x) (Hy : SN (red R U supterm) y),
      x = y -> interp_rec Hx = interp_rec Hy.

    Proof.
      intros. generalize Hx Hy. clear Hx Hy. rewrite H. intros.
      rewrite (proof_irrelevance _ Hx Hy). refl.
    Qed.

    Definition interp_vec n v 
      (SNv : forall x, Vin x v -> SN (red R U supterm) x) :=
      Vbuild (fun i (Hi : i < n) => interp_rec (SNv _ (Vnth_in v Hi))).

    Implicit Arguments interp_vec [n v].

    Lemma SN_reducts : forall f v, SN (red R U supterm) (Fun f v) ->
      forall x, Vin x (vec_of_list (reducts R (Fun f v))) ->
        SN (red R U supterm) x.

    Proof.
      intros. destruct H. apply H. left. apply reducts_correct.
      rewrite Vin_vec_of_list. auto.
    Qed.

    Lemma SN_subs :forall f v, SN (red R U supterm) (Fun f v) ->
      forall x, Vin x v -> SN (red R U supterm) x.

    Proof.
      intros. destruct H. apply H. right. apply subterm_fun. auto.
    Qed.

    Lemma interp_rec_funE : forall f v (Ht : SN (red R U supterm) (Fun f v)),
      let vs := interp_vec (SN_subs Ht) in
        let vr := interp_vec (SN_reducts Ht) in
          interp_rec Ht = if G f then cons_term _ (Fun f vs) vr else Fun f vs.

    Proof.
      intros.
      set (vs' := Vbuild (fun i (Hi : i < arity f) =>
        interp_rec (SN_subs_def Ht (refl_equal (Fun f v)) Hi))).
      set (vr' := Vbuild (fun i (Hi : i < (length (reducts R (Fun f v)))) =>
        interp_rec (SN_reducts_def Ht (refl_equal (Fun f v)) Hi))).
      assert (H1 : interp_rec Ht =
        if G f then cons_term _ (Fun f vs') vr' else Fun f vs').
      unfold vs', vr'. case Ht. simpl. auto.
      assert (H2 : vs = vs'). apply Veq_nth. intros. unfold vs, vs', interp_vec.
      rewrite !Vbuild_nth. apply interp_rec_eq. refl.
      assert (H3 : vr = vr'). apply Veq_nth. intros. unfold vr, vr', interp_vec.
      rewrite !Vbuild_nth. apply interp_rec_eq. apply Vnth_vec_of_list.
      rewrite H1, H2, H3; refl.
    Qed.

    Definition interp t (Ht : SN (red R) t) := interp_rec (SN_red_supterm Ht).

    Lemma interp_proof_eq :
      forall t (Ht : SN (red R) t) (H : SN (red R U supterm) t),
        interp Ht = interp_rec H.

    Proof.
      intros. unfold interp.
      rewrite (proof_irrelevance _ H (SN_red_supterm Ht)). refl.
    Qed.

    Lemma interp_eq : forall x y
      (Hx : SN (red R) x) (Hy : SN (red R) y), x = y -> interp Hx = interp Hy.

    Proof.
      intros. unfold interp. apply interp_rec_eq; auto.
    Qed.

    Lemma interp_funE : forall f v (Ht : SN (red R) (Fun f v)),
      let vs := interp_vec (SN_subs (SN_red_supterm Ht)) in
        let vr := interp_vec (SN_reducts (SN_red_supterm Ht)) in
          interp Ht = if G f then cons_term _ (Fun f vs) vr else Fun f vs.

    Proof.
      intros. unfold interp. rewrite interp_rec_funE. auto.
    Qed.

    (* terminating substitution *)
    Definition tsub s t (SNst : SN (red R) (sub s t)) x :=
      match bool_dec (var_occurs_in x t) true with
        | left H => interp (sub_sn _ _ _ (proj1 (var_occurs_in_ok _ _) H) SNst)
        | right _ => interp SNst
      end.

    Implicit Arguments tsub [s t].

    Lemma sub_tsub_proof : forall s f v (SNst : SN (red R) (sub s (Fun f v)))
      i (Hi : i < arity f), SN (red R) (sub s (Vnth v Hi)).

    Proof.
      intros. apply (subterm_eq_sn SNst). apply subterm_eq_sub.
      apply subterm_strict. apply subterm_fun. apply Vnth_in.
    Qed.

    Lemma sub_tsub_fun :
      forall s f v (SNst : SN (red R) (sub s (Fun f v))),
        Fun f (Vmap (sub (tsub SNst)) v)
        = Fun f (Vbuild (fun i (Hi : i < arity f) =>
          sub (tsub (sub_tsub_proof SNst Hi)) (Vnth v Hi))).

    Proof.
      intros. apply args_eq. apply Vmap_eq_nth. intros i Hi.
      rewrite Vbuild_nth. simpl in SNst. apply sub_eq. intros x Hx.
      unfold tsub. case (bool_dec (var_occurs_in x (Vnth v Hi))). Focus 2.
      intro H'. rewrite <- var_occurs_in_ok in Hx. rewrite Hx in H'. tauto.
      intro. generalize (vars_vec_in Hx (Vnth_in v Hi)). rewrite <- vars_fun.
      intro Hfv. case (bool_dec (var_occurs_in x (Fun f v))); intro Hfvb.
      Focus 2. rewrite <- var_occurs_in_ok in Hfv; rewrite Hfv in Hfvb. tauto.
      set (H1 := sub_sn (Fun f v) x s
        (proj1 (var_occurs_in_ok x (Fun f v)) Hfvb) SNst);
      rewrite (proof_irrelevance _ H1 (sub_sn (Vnth v Hi) x s
        (proj1 (var_occurs_in_ok x (Vnth v Hi)) e) (sub_tsub_proof SNst Hi)));
      refl.
    Qed.

    Lemma sub_tsub_eq : forall s t u (Ht : SN (red R) (sub s t))
      (Hu : SN (red R) (sub s u)), vars u [= vars t ->
        sub_eq_dom (tsub Hu) (tsub Ht) (vars u).

    Proof.
      intros. intros x Hx. unfold tsub. case (bool_dec (var_occurs_in x t)).
      Focus 2. cut (var_occurs_in x t = true). intro T; rewrite T; tauto.
      rewrite var_occurs_in_ok. apply H; auto.
      intro T. case (bool_dec (var_occurs_in x u)). intro T'.
      rewrite (proof_irrelevance _
        (sub_sn t x s (proj1 (var_occurs_in_ok x t) T) Ht)
        (sub_sn u x s (proj1 (var_occurs_in_ok x u) T') Hu)). auto.
      rewrite var_occurs_in_ok. tauto.
    Qed.

  End Def.

  Implicit Arguments tsub [s t].

(***********************************************************************)
(** Lemma 17 *)

  Section Lemma17.

    Variable G : Sig -> bool.

    Lemma proj_interp : forall f v t (Hf : SN (red R U supterm) (Fun f v)) 
      (Ht : SN (red R U supterm) t), (red R) (Fun f v) t -> G f = true ->
      red P! (interp_rec G Hf) (interp_rec G Ht).

    Proof.
      intros. rewrite interp_rec_funE, H0. apply proj_cons_tc_r.
      unfold interp_vec. generalize (reducts_complete HR H); intro.
      apply Vin_build. destruct (in_elim H1) as [l1 H2]. destruct H2 as [l2 H2].
      assert (H3 : (length l1) < length (reducts R (Fun f v))).
      rewrite H2, length_app; simpl. omega.
      exists (length l1); exists H3. apply interp_rec_eq.
      rewrite (Vnth_vec_of_list _ t), H2, app_nth2; auto. rewrite minus_diag.
      refl.
    Qed.

    Variable s : substitution Sig.

    Lemma Lemma17 : forall t (SNt : SN (red R) (sub s t)),
      let st := (tsub G SNt) in
        red P# (interp G SNt) (sub st t) /\
        ((forall x, In x (symbs t) -> G x = false) -> interp G SNt = sub st t).

    Proof.
intro t.
set (Pt := fun x => forall H : SN (red R) (sub s x),
  let st := tsub G H in red P# (interp G H) (sub st x) /\
    ((forall y : Sig, In y (symbs x) -> G y = false) ->
      interp G H = sub st x)).
apply term_ind_forall with (P := Pt); unfold Pt; intros.
unfold tsub. simpl. destruct (bool_dec (beq_nat v v) true). Focus 2.
split; intros; try apply rtc_refl; auto.
simpl in H. split; intros; pattern H at 1;
rewrite (proof_irrelevance _ H (sub_sn _ _ _
  (proj1 (var_occurs_in_ok v (Var v)) e) H)); auto. apply rtc_refl.
rewrite symbs_fun. simpl; rewrite interp_funE. rewrite Vforall_eq in H.
assert (H1 : forall i (Hi : i < arity f), SN (red R) (sub s (Vnth v Hi))).
intros. apply subterm_eq_sn with (t := sub s (Fun f v)); auto.
apply subterm_eq_sub. apply subterm_strict. apply subterm_fun.
apply Vnth_in.
assert (H2 : forall i (Hi : i < arity f), Vnth (Vmap (sub s) v) Hi =
  sub s (Vnth v Hi)). intros. rewrite Vnth_map; auto.
assert (H3 : forall i (Hi : i < arity f),
  SN (red R U supterm) (sub s (Vnth v Hi))).
intros; apply SN_red_supterm; auto.
assert (H4 : forall i (Hi : i < arity f),
  (forall y : Sig, f = y \/ In y (symbs_vec v) -> G y = false) -> 
  forall y : Sig, In y (symbs (Vnth v Hi)) -> G y = false).
intros. apply H4. right.
apply symbs_vec_in with (t := Vnth v Hi); auto; apply Vnth_in.
assert (H5 : forall i (Hi : i < arity f),
  sub_eq_dom (tsub G (H1 i Hi)) (tsub G H0) (vars (Vnth v Hi))).
intros. apply sub_tsub_eq. intros x Hx. rewrite vars_fun.
apply vars_vec_in with (t := (Vnth v Hi)); auto. apply Vnth_in.
case_eq (G f); unfold interp_vec.
(* 1 *) Focus 2. simpl. split. rewrite sub_tsub_fun.
apply proj_cons_fun. intros. rewrite !Vbuild_nth.
destruct (H (Vnth v Hi) (Vnth_in v Hi) (H1 _ Hi)) as [H7 _]. simpl in H0.
rewrite (interp_rec_eq G (SN_subs (SN_red_supterm H0)
  (Vnth (Vmap (sub s) v) Hi) (Vnth_in (Vmap (sub s) v) Hi))
  (H3 _ Hi) (H2 _ Hi)).
rewrite <- (interp_proof_eq G (H1 _ Hi) (H3 _ Hi)).
rewrite (proof_irrelevance _ (sub_tsub_proof H0 Hi) (H1 _ Hi)). auto.
intro. apply args_eq. apply Veq_nth; intros i Hi.
rewrite Vbuild_nth, Vnth_map.
destruct (H (Vnth v Hi) (Vnth_in v Hi) (H1 _ Hi)) as [_ H8]. simpl in H0.
rewrite (interp_rec_eq G (SN_subs (SN_red_supterm H0)
  (Vnth (Vmap (sub s) v) Hi) (Vnth_in (Vmap (sub s) v) Hi))
  (H3 _ Hi) (H2 _ Hi)).
rewrite <- (interp_proof_eq G (H1 _ Hi) (H3 _ Hi)), H8; auto.
apply (sub_eq_dom_incl_sub (H5 i Hi)). apply incl_refl. apply H4; auto.
(* 2 *) split. apply rt_trans with (y := Fun f (Vbuild (fun (i : nat)
(Hi : i < arity f) => interp_rec G (SN_subs (SN_red_supterm H0)
  (Vnth (Vmap (sub s) v) Hi) (Vnth_in (Vmap (sub s) v) Hi))))).
apply proj_cons_rtc_l. apply proj_cons_fun. intros.
rewrite !Vbuild_nth, Vnth_map.
destruct (H (Vnth v Hi) (Vnth_in v Hi) (H1 _ Hi)) as [H7 _].
rewrite (interp_rec_eq G (SN_subs (SN_red_supterm H0)
  (Vnth (Vmap (sub s) v) Hi) (Vnth_in (Vmap (sub s) v) Hi))
  (H3 _ Hi) (H2 _ Hi)).
rewrite <- (interp_proof_eq G (H1 _ Hi) (H3 _ Hi)).
rewrite (sub_eq_dom_incl_sub (H5 i Hi)) in H7; auto. apply incl_refl.
intros.
rewrite (H7 _ (or_introl (In f (symbs_vec v)) (refl_equal f))) in H6.
generalize (diff_false_true H6). tauto.
    Qed.

  End Lemma17.

(***********************************************************************)
(** Lemma 19 *)

  Variables (succs_symb : rules -> Sig -> list Sig)
    (succs_symbP : forall R f g, In g (succs_symb R f) <-> symb_ord R# f g).

  Variable C : rules.

  Notation UC := (usable_rules succs_symb R C).
  Notation G := (fun f => defined f R && negb (defined f UC)).

  Section Lemma19.

    Lemma SN_ctx_l : forall c u f i j (H : i + S j = arity f) v1 v2,
      SN (red R) (fill (Cont f H v1 c v2) u) ->
      forall x, Vin x v1 -> SN (red R) x.

    Proof.
      intros. apply (@subterm_eq_sn _ _ (fill (Cont f H v1 c v2) u)); auto.
      simpl. apply subterm_strict. apply subterm_fun.
      apply Vin_cast_intro; apply Vin_appl. auto.
    Qed.

    Lemma SN_ctx_r : forall c u f i j (H : i + S j = arity f) v1 v2,
      SN (red R) (fill (Cont f H v1 c v2) u) ->
      forall x, Vin x v2 -> SN (red R) x.

    Proof.
      intros. apply (@subterm_eq_sn _ _ (fill (Cont f H v1 c v2) u)); auto.
      simpl. apply subterm_strict. apply subterm_fun. apply Vin_cast_intro.
      apply Vin_appr. simpl. auto.
    Qed.

    Lemma SN_ctx_term : forall c u f i j (H : i + S j = arity f) v1 v2,
      SN (red R) (fill (Cont f H v1 c v2) u) -> SN (red R) u.

    Proof.
      intros. apply (@subterm_eq_sn _ _ (fill (Cont f H v1 c v2) u)); auto.
      simpl. apply (@subterm_eq_trans _ _ (fill c u)). exists c; auto.
      apply subterm_strict. apply subterm_fun. apply Vin_cast_intro.
      apply Vin_app_cons.
    Qed.

    Lemma Lemma19 : forall u t (Hu : SN (red R) u) (Ht : SN (red R) t),
      red R u t -> (red UC U red P)! (interp G Hu) (interp G Ht).

    Proof.
intros. rewrite forallb_forall in NVlR. destruct u. unfold interp.
case (SN_red_supterm Hu). simpl. intro. clear s. destruct H as [l H].
destruct H as [r H]; destruct H as [c H]. destruct H as [s H].
destruct H as [H H0]. destruct H0 as [H0 H1]. destruct (var_eq_fill H0).
rewrite H2 in H0, H1. simpl in H0, H1. clear H3.
destruct (vars_eq_sub s _ H0) as [m H3]. generalize (NVlR _ H).
unfold is_notvar_lhs. rewrite H3; simpl. intro. discriminate H4.
case_eq (defined f R && negb (defined f UC)).
eapply clos_trans_m'. apply incl_union_r. refl. apply proj_interp; auto.
destruct H as [l H]. destruct H as [r H]. destruct H as [c H].
destruct H as [s H]. destruct H as [Rlr H]. destruct H as [H1 H2].
generalize f v t Hu Ht H0 Rlr H1 H2. clear Rlr H2 H1 H0 Ht Hu t v f.
induction c; intros; simpl in H1, H2.
(* 1 *) assert (UClr : In (mkRule l r) UC).
generalize (Inb_intro (@eq_rule_dec Sig) _ _ Rlr).
rewrite <- forallb_forall in NVlR.
rewrite (Inb_equiv (@eq_rule_dec Sig) _  (urules_equiv succs_symb R C NVlR)).
intro. generalize (Inb_true _ _ _ H). rewrite in_app. intro. destruct H3; auto.
unfold rrules_list in H3; rewrite filter_In in H3; destruct H3 as [_ H3].
simpl in H3. destruct l. discriminate H3.
simpl in H1. rewrite (symb_eq H1) in H0. rewrite H0 in H3. discriminate H3.
generalize Hu, Ht. rewrite H1, H2. clear Hu Ht. intros. apply tc_split_inv.
exists (sub (tsub G Hu) l). split. rewrite <- clos_refl_trans_equiv.
apply union_rel_rt_right. rewrite clos_refl_trans_equiv.
apply (proj1 (Lemma17 G _ l Hu)).
rewrite (proj2 (Lemma17 G _ r Ht)). left. exists l; exists r. exists Hole.
exists (tsub G Hu). split; auto. simpl; split; auto.
apply (@sub_eq_dom_incl_sub _ _ _ (vars r)); try apply incl_refl.
apply sub_tsub_eq. apply HR; auto.
intros. apply lhs_defsymbG with (l := l) (r := r); auto.
(* 2 *) generalize Ht Hu. rewrite H1, H2. clear Ht Hu. intros.
rewrite !interp_funE. rewrite (symb_eq H1) in H0. rewrite H0.
set (u1 :=  (interp_vec G (Vcast (Vapp v (Vcons (fill c (sub s l)) v0)) e)
        (SN_subs (SN_red_supterm Hu)))).
set (u2 :=  (interp_vec G (Vcast (Vapp v (Vcons (fill c (sub s r)) v0)) e)
        (SN_subs (SN_red_supterm Ht)))).
assert (Hi : i < arity f). rewrite <- e. omega.
rewrite (fun_eq_nth_fill f u1 Hi), (fun_eq_nth_fill f u2 Hi). 
apply (clos_trans_m' (red_union UC (proj_cons Sig))).
cut ((Vsub u2 (Veq_app_cons_aux1 Hi)) = (Vsub u1 (Veq_app_cons_aux1 Hi))).
intro. Focus 2. apply Veq_nth; intros. rewrite !Vnth_sub.
unfold u1, u2, interp_vec. rewrite !Vbuild_nth. apply interp_rec_eq.
rewrite !Vnth_cast, !Vnth_app. case (le_gt_dec i (0 + i0)); auto.
intro ip'. simpl in ip'. generalize (lt_not_le _ _ ip). tauto.
cut ((Vsub u2 (Veq_app_cons_aux2 Hi)) = (Vsub u1 (Veq_app_cons_aux2 Hi))).
intro. Focus 2. apply Veq_nth; intros. rewrite !Vnth_sub.
unfold u1, u2, interp_vec. rewrite !Vbuild_nth. apply interp_rec_eq.
rewrite !Vnth_cast, !Vnth_app. case (le_gt_dec i (S i + i0)); auto.
intro ip'. set (Hij := (Vnth_app_aux (S j)
     (Vnth_cast_aux e (Vnth_sub_aux (S i) (Veq_app_cons_aux2 Hi) ip)) ip')).
assert (HSi : S i + i0 - i = S i0). omega.
generalize Hij. rewrite HSi. clear Hij; intro. rewrite !Vnth_cons; auto.
rewrite H, H3. clear H H3. unfold u1, u2. clear u1 u2.
apply (@context_closed_tc _ _ (@context_closed_red _ (UC ++ proj_cons Sig))).
unfold interp_vec. rewrite !Vbuild_nth.
set (Hls := SN_subs (SN_red_supterm Hu)
        (Vnth (Vcast (Vapp v (Vcons (fill c (sub s l)) v0)) e) Hi)
        (Vnth_in (Vcast (Vapp v (Vcons (fill c (sub s l)) v0)) e) Hi)).
set (Hrs := SN_subs (SN_red_supterm Ht)
        (Vnth (Vcast (Vapp v (Vcons (fill c (sub s r)) v0)) e) Hi)
        (Vnth_in (Vcast (Vapp v (Vcons (fill c (sub s r)) v0)) e) Hi)).
generalize Hls Hrs. clear Hls Hrs. rewrite !Vnth_cast, !Vnth_app.
case (le_gt_dec i i). Focus 2. intro g. absurd_arith.
intro. rewrite !Vnth_cons_head; try rewrite minus_diag; auto. clear l0.
case_eq (fill c (sub s l)). symmetry in H.
destruct (var_eq_fill H). symmetry in H4. destruct (vars_eq_sub _ _ H4).
generalize (NVlR _ Rlr). rewrite H5. unfold is_notvar_lhs. simpl. intro T.
discriminate T. symmetry in H.
assert (Hl : SN (red R) (Fun f1 v2)). apply subterm_eq_sn with
 (t := Fun f (Vcast (Vapp v (Vcons (fill c (sub s l)) v0)) e)); auto.
rewrite H. apply subterm_strict. apply subterm_fun. apply Vin_cast_intro.
apply Vin_app_cons.
assert (Hr : SN (red R) (fill c (sub s r))). apply subterm_eq_sn with
 (t := Fun f (Vcast (Vapp v (Vcons (fill c (sub s r)) v0)) e)); auto.
apply subterm_strict. apply subterm_fun. apply Vin_cast_intro.
apply Vin_app_cons.
apply (clos_trans_m' (@red_union_inv _ UC (proj_cons Sig))).
case_eq (defined f1 R && negb (defined f1 UC)). Focus 2.
generalize (IHc f1 v2 (fill c (sub s r)) Hl Hr H3 Rlr H (refl_equal _)).
rewrite (interp_proof_eq _ Hl Hls), (interp_proof_eq _ Hr Hrs); auto.
eapply clos_trans_m'. apply incl_union_r. refl. apply proj_interp; auto.
exists l. exists r. exists c. exists s. auto.
Qed.

  End Lemma19.

(***********************************************************************)
(** termination proof *)

  Require Import NotSN_IS NatLeast.

  Variables (HC : rules_preserve_vars C)

    (NVlC : forallb (@is_notvar_lhs Sig) C = true)

    (* rules R C do not have any common defined symbol *)
    (HDPR : forall f, defined f R && defined f C = false)

    (WP : weakRedPairType Sig).

  Notation succ := (succ WP). Notation succeq := (succeq WP).

  Variables (hyp1 : forall l r, In (mkRule l r) (UC ++ P) -> succeq l r)
    (hyp2 : forall l r, In (mkRule l r) C -> (succeq U succ) l r)
    (hyp3 : exists l, exists r, In (mkRule l r) C /\ succ l r).

  Lemma Usablerules_IS : forall f g, ~ISModMin R C f g.

Proof.
intros f g HM. destruct HM as [HisM [hmin [Hsg Hsf]]].
unfold ISModInfRuleApp in hmin. unfold MinNT in Hsf, Hsg. unfold ISMod in HisM.
assert (SNgi : forall i, SN (red R) (g i)).
intros. case_eq (g i). apply sn_var. auto. apply sn_args_sn_fun; auto.
destruct (proj2 (HisM i)) as [l [r [s [Clr Hgi]]]]. destruct l.
generalize (is_notvar_lhs_false _ NVlC _ _ Clr); tauto.
rewrite H in Hgi; simpl in Hgi. rewrite (symb_eq (proj1 Hgi)).
generalize (HDPR f1). rewrite (lhs_fun_defined _ _ _ _ Clr), andb_true_r; auto.
apply Vforall_intro; intros. apply NNPP; intro HSx.
destruct (notSN_IS HSx) as [h [Hh1 Hh2]].
assert (T : subterm x (g i)). rewrite H. apply subterm_fun; auto.
apply (Hsg i x T h Hh2 Hh1).
assert (SNfi : forall i, SN (red R) (f i)). intro i.
destruct (int_red_rtc_preserve_hd (proj1 (HisM i))). rewrite H. apply SNgi.
destruct H as [F [us [vs [Efi Egi]]]]. rewrite Efi; apply sn_args_sn_fun; auto.
destruct (proj2 (HisM i)) as [l [r [s [Clr Hgi]]]]. destruct l.
generalize (is_notvar_lhs_false _ NVlC _ _ Clr); tauto.
rewrite Egi in Hgi; simpl in Hgi. rewrite (symb_eq (proj1 Hgi)).
generalize (HDPR f0). rewrite (lhs_fun_defined _ _ _ _ Clr), andb_true_r; auto.
apply Vforall_intro; intros. apply NNPP; intro HSx.
destruct (notSN_IS HSx) as [h [Hh1 Hh2]].
assert (T : subterm x (f i)). rewrite Efi. apply subterm_fun; auto.
apply (Hsf i x T h Hh2 Hh1).

assert (Hsucceq : (red UC U red P)# << succeq).
apply inclusion_Trans with (succeq#). Focus 2.
apply trans_rtc_incl; try apply trans_succeq. apply refl_succeq.
apply incl_rtc_rtc. apply inclusion_Trans with succeq.
Focus 2. apply rtc_incl.
apply inclusion_Trans with (red (UC ++ P)). apply red_union_inv.
intros x y Hxy. destruct Hxy as [l [r [c [ s [Clr Hxy]]]]].
rewrite (proj1 Hxy), (proj2 Hxy). apply cc_succeq. apply sc_succeq.
apply hyp1; auto. 

pose (f' := fun i => interp G (SNfi i)).
pose (g' := fun i => interp G (SNgi i)).
assert (IMfg1 : forall i, succeq (f' i) (g' i)). intros. unfold f', g'.
apply Hsucceq. destruct (HisM i) as [H0 _]. generalize (SNgi i) (SNfi i).
induction H0; intros. apply tc_incl_rtc. apply Lemma19.
apply int_red_incl_red; auto. rewrite (interp_eq _ _ s (refl_equal x)).
apply rtc_refl. assert (sy : SN (red R) y). apply (SN_rtc s0).
apply incl_rtc_rtc with (R := int_red R) (S := red R); auto.
apply (@inclusion_Trans _ _ (red R)). apply int_red_incl_red. apply rtc_incl.
apply rtc_trans with (y := interp G sy). apply IHclos_refl_trans1.
apply IHclos_refl_trans2.

assert (Tfg : forall i, (red P # @ hd_red C) (g' i) (f' (S i))).
intros. unfold f', g'; destruct (HisM i) as [_ [l [r [s [Clr [Hi1 Hi2]]]]]].
assert (SNl : SN (red R) (sub s l)). rewrite <- Hi1. apply SNgi.
assert (SNr : SN (red R) (sub s r)). rewrite <- Hi2. apply SNfi.
rewrite (interp_eq _ _ SNl Hi1), (interp_eq _ _ SNr Hi2).
exists (sub (tsub G SNl) l); split. apply (proj1 (Lemma17 G s _ SNl)).
assert (Hr0 : forall x, In x (symbs r) -> G x = false).
intros. apply rhsC_defsymbG with (l := l) (r := r); auto.
rewrite (proj2 (Lemma17 G s _ SNr) Hr0). exists l; exists r.
exists (tsub G SNl); split; auto; simpl; split; auto.
apply (@sub_eq_dom_incl_sub _ _ _ (vars r)); try apply incl_refl.
apply sub_tsub_eq. apply HC; auto.

assert (IMfg2 : forall i, (succeq @ (succeq U succ)) (g' i) (f' (S i))).
intro. destruct (Tfg i) as [x [Hx1 Hx2]]. exists x. split.
apply Hsucceq. apply incl_rtc_rtc with (R := (red P)); auto.
apply inclusion_Trans with (red UC U red P). apply incl_union_r. refl.
apply rtc_incl.
destruct Hx2 as [l [r [s [Clr Hx2]]]]. rewrite (proj1 Hx2), (proj2 Hx2).
destruct (hyp2 _ _ Clr). left. apply sc_succeq; auto.
right. apply sc_succ; auto.

assert (IMfg : ISMod succeq (succeq @ (succeq U succ)) f' g').
intros i; apply (conj (IMfg1 i) (IMfg2 i)).

assert (hmin' : forall d, In d C -> exists h : nat -> nat, forall j,
 h j < h (S j) /\ (red P # @ hd_red (d :: nil)) (g' (h j)) (f' (S (h j)))).
intros. destruct (hmin _ H) as [h h_def]. exists h. intro. split.
apply (proj1 (h_def j)). destruct (h_def j) as [_ [l [r [s [Dlr [Hj1 Hj2]]]]]].
assert (SNl : SN (red R) (sub s l)). rewrite <- Hj1. apply SNgi.
assert (SNr : SN (red R) (sub s r)). rewrite <- Hj2. apply SNfi.
unfold f', g'. rewrite (interp_eq _ _ SNl Hj1), (interp_eq _ _ SNr Hj2).
exists (sub (tsub G SNl) l); split. apply (proj1 (Lemma17 G s _ SNl)).
assert (Clr : In (mkRule l r) C). destruct d as [l' r'].
destruct Dlr; try tauto. rewrite <- rule_eq in H0. simpl in H0.
rewrite <- (proj1 H0), <- (proj2 H0); auto.
assert (Hr0 : forall x, In x (symbs r) -> G x = false).
intros. apply rhsC_defsymbG with (l := l) (r := r); auto.
rewrite (proj2 (Lemma17 G s _ SNr) Hr0). exists l; exists r.
exists (tsub G SNl); split; auto; simpl; split; auto.
apply (@sub_eq_dom_incl_sub _ _ _ (vars r)); try apply incl_refl.
apply sub_tsub_eq. apply HC; auto.

assert (Hex : forall i, exists j, i <= j /\ (succ (g' j) (f' (S j)))).
intro. destruct hyp3 as [l [r [Clr Hlr]]]. destruct (hmin' _ Clr) as [h h_def].
assert (hMj : forall j, j <= h j). induction 0. omega.
apply lt_le_S. apply (le_lt_trans _ _ _ IHj). destruct (h_def j). auto.
exists (h i). split; try apply hMj. destruct (h_def i) as [_ [x [Hx Hi]]].
apply succ_succeq_compat. exists x. split. apply Hsucceq.
apply incl_rtc_rtc with (R := red P); auto.
apply inclusion_Trans with (red UC U red P). apply incl_union_r. refl.
apply rtc_incl. destruct Hi as [l' [r' [s [Elr Hi]]]].
destruct Elr as [Elr |]; try tauto. rewrite <- rule_eq in Elr. simpl in Elr.
rewrite (proj1 Hi), (proj2 Hi), <- (proj1 Elr), <- (proj2 Elr).
apply sc_succ; auto.

assert (IMfg' : ISMod succeq (succeq U succ) f' g'). intro i. split.
apply (proj1 (IMfg i)). destruct (proj2 (IMfg i)) as [x Hx].
destruct (proj2 Hx). left. apply trans_succeq with x; intuition.
right. apply succ_succeq_compat. exists x. intuition.
destruct (ISMod_union IMfg' Hex (@trans_succeq _ WP)) as [f1 [g1 IM2]].

assert (IS succ f1). intro. apply succ_succeq_compat. exists (g1 i).
apply (proj1 IM2). apply (@wf_succ _ WP f1); auto.
Qed.

End UsableRulesProp.

(***********************************************************************)
(** termination proof with boolean conditions *)

Axiom WF_IS_DP : forall Sig (M D : rules Sig), D [= dp M -> 
  ~WF (hd_red_Mod (red M #) D) -> exists f, exists g, ISModMin M D f g.

Section UsableRules.

  Variable Sig : BinSignature.

  Notation P := (proj_cons Sig).

  Notation term := (term Sig). Notation terms := (vector term).
  Notation rule := (rule Sig). Notation rules := (list rule).

  Variables (succs_symb : rules -> Sig -> list Sig)
    (succs_symbP : forall R f g, In g (succs_symb R f) <-> symb_ord R# f g).

  Variable WP : weakRedPairType Sig.

  Notation succ := (succ WP). Notation succeq := (succeq WP).
  Notation bsucc := (bsucc WP). Notation bsucceq := (bsucceq WP).

  Lemma usable_rules_WF : forall M D1 D2,
    let UC := usable_rules succs_symb M (D1 ++ D2) in
    let G := fun f => defined f M && negb (defined f UC) in
      D1 ++ D2 [= dp M ->
      brules_preserve_vars M = true ->
      forallb (@is_notvar_lhs Sig) M = true ->
      brules_preserve_vars (D1 ++ D2) = true ->
      is_empty (filter (fun x => defined x M) (list_defined (D1++D2))) = true ->
      forallb (@is_notvar_lhs Sig) (D1 ++ D2) = true ->
      forallb (brule bsucceq) (UC ++ P) = true ->
      forallb (brule (fun x y => bsucceq x y || bsucc x y)) (D1 ++ D2) = true ->
      forallb (brule bsucc) D1 = true -> 
      WF (hd_red_Mod (red M #) D2) -> WF (hd_red_Mod (red M #) (D1 ++ D2)).

  Proof.
intros. induction D1. simpl. hyp.
simpl. apply NNPP. intro. destruct (WF_IS_DP H H9) as [f [g H10]].
assert (H11 : exists l, exists r, In (mkRule l r) (a :: D1 ++ D2) /\ succ l r).
exists (lhs a); exists (rhs a); split. simpl. left. destruct a; simpl. auto.
rewrite forallb_forall in H7. generalize (H7 a (in_eq a D1)). unfold brule.
apply bsucc_sub.
rewrite <- brules_preserve_vars_ok in H0, H2.
assert (H12 : forall f, defined f M && defined f (a :: D1 ++ D2) = false).
intro. case_eq (defined f0 M); case_eq (defined f0 (a :: D1 ++ D2)); auto.
rewrite defined_list_ok in H13.
cut (In f0 (filter (fun x => defined x M) (list_defined ((a :: D1) ++ D2)))).
case_eq (filter (fun x => defined x M) (list_defined ((a :: D1) ++ D2))).
destruct H15. rewrite H14 in H3. simpl in H3. discriminate H3.
rewrite filter_In; auto.
assert (H16 : forall l r, In (mkRule l r) (UC ++ P) -> succeq l r).
intros; rewrite forallb_forall in H5. generalize (H5 _ H13). unfold brule.
apply bsucceq_sub.
assert (H17 : forall l r,
 In (mkRule l r) (a :: D1 ++ D2) -> (succeq U succ) l r).
intros. rewrite forallb_forall in H6. generalize (H6 _ H13). unfold brule.
rewrite orb_eq. simpl. intro TH. destruct TH. left. apply bsucceq_sub; auto.
right. apply bsucc_sub; auto.
eapply Usablerules_IS with (R:=M) (C:=a::D1++D2) (WP:=WP) (f:=f) (g:=g); auto.
Qed.

Lemma usable_rules_criterion : forall M D,
 let D' := filter (brule (neg bsucc)) D in
 let UC := usable_rules succs_symb M D in
 let G := fun f => defined f M && negb (defined f UC) in
  D [= dp M ->
  brules_preserve_vars M = true ->
  forallb (@is_notvar_lhs Sig) M = true ->
  brules_preserve_vars D = true ->
  is_empty (filter (fun x => defined x M) (list_defined D)) = true ->
  forallb (@is_notvar_lhs Sig) D = true ->
  forallb (brule bsucceq) (UC ++ P) = true ->
  forallb (brule (fun x y => bsucceq x y || bsucc x y)) D = true ->
  WF (hd_red_Mod (red M #) D') -> WF (hd_red_Mod (red M #) D).

Proof.
intros. pose (D0 := filter (brule bsucc) D).
assert (HD : (hd_red_Mod (red M #) D) << (hd_red_Mod (red M #) (D0 ++ D'))).
apply hd_red_Mod_incl. refl. intros d Dd. apply in_or_app.
case_eq (brule (neg bsucc) d). unfold D'. rewrite filter_In. intuition.
left; unfold D0; rewrite filter_In. split; try hyp. unfold brule in H8.
generalize (proj1 (negb_lr _ _) H8). simpl. auto.
apply (WF_incl HD). apply usable_rules_WF; auto.
intros x T. rewrite in_app in T. destruct T as [T|T]; apply H.
unfold D0 in T; rewrite filter_In in T; destruct T; auto.
unfold D' in T; rewrite filter_In in T; destruct T; auto.
rewrite <- brules_preserve_vars_ok in H2 |- *. intros l r Dlr.
apply H2. unfold D0, D' in Dlr; rewrite in_app in Dlr.
destruct Dlr as [Dlr | Dlr]; rewrite filter_In in Dlr; intuition.
case_eq (filter (fun x => defined x M) (list_defined (D0 ++ D'))); auto.
cut (In s (filter (fun x : Sig => defined x M) (list_defined D))).
case_eq (filter (fun x => defined x M) (list_defined D)); auto.
rewrite H9 in H3; simpl in H3; auto.
generalize (in_eq s l); rewrite <- H8, !filter_In, <- defined_list_ok.
intro. destruct H9. rewrite H10; split; auto. rewrite <- defined_list_ok.
unfold D0, D' in H9; rewrite defined_equiv in H9. destruct H9 as [v [r H9]].
rewrite defined_equiv. exists v; exists r. rewrite in_app, !filter_In in H9.
intuition.
rewrite forallb_forall in H4 |- *; intros. apply H4. unfold D0, D' in H8.
rewrite in_app, 2?filter_In in H8. intuition.
rewrite forallb_forall in H5 |- *; intros. apply H5. rewrite in_app in H8 |- *.
destruct H8; try intuition. left. destruct x as [l r]. unfold UC.
rewrite In_usable in H8 |- *. destruct H8 as [a H8]. exists a.
split; try intuition. unfold D0, D' in H9; rewrite in_app in H9.
rewrite !filter_In in H9; intuition.
rewrite forallb_forall in H6 |- *; intros. apply H6. unfold D0, D' in H8.
rewrite in_app, 2?filter_In in H8. intuition.
rewrite forallb_forall; unfold D0. intros. rewrite filter_In in H8. intuition.
Qed.

End UsableRules.

(***********************************************************************)
(** functor for Rainbow *)

Require Import ARedPair WF_NotIS SetoidList.

Module Type Binary.
  Variable Sig : Signature.
  Variable some_symbol : Sig.
  Variable arity_some_symbol_eq_2 : arity some_symbol = 2.
End Binary.

Module Usable (WP : WeakRedPair) (B : Binary with Definition Sig := WP.Sig)
  (W : WSIG with Definition Sig := WP.Sig).

  Module OT := OrdType W.

  Require TransClos.
  Module Import TC := TransClos.Make OT.

  Definition def_symbs_rule R (a : rule B.Sig) :=
    match lhs a with
      | Var _ => None
      | Fun f _ => Some (f, def_symbs R (rhs a))
    end.

  Lemma def_symbs_rule_ok : forall R,
    fold_left (add_edge_list (def_symbs_rule R)) R empty == symb_ord R.

  Proof.
    intro R. rewrite rel_eq. intros f g. rewrite rel_list_fold_left.
    (* forall G a, F G a == F empty a U G *)
    Focus 2. intros G a. do 2 rewrite rel_add_edge_list.
    destruct (def_symbs_rule R a). destruct p as [h l].
    rewrite rel_empty, union_empty_r. refl.
    rewrite rel_empty, union_empty_l. refl. Focus 1.
    (* end In_list_fold_left conditions *)
    unfold symb_ord. intuition.
    (* 1 *)
    apply rel_empty in H0. contradiction.
    (* 2 *)
    destruct H0 as [a [a1 a2]]. apply rel_add_edge_list in a2. gen a2.
    case_eq (def_symbs_rule R a).
    2: apply rel_empty in a2; contradiction.
    destruct p as [x m]. destruct a2.
    2: apply rel_empty in H0; contradiction.
    unfold succ_list in H0. rewrite <- In_InA_eq in H0. destruct H0. subst x.
    gen H. unfold def_symbs_rule, root_eq. exists a. destruct (lhs a).
    discr. inversion H. subst m. intuition. rewrite beq_symb_ok. refl.
    (* 3 *)
    destruct H as [a]. case_eq (def_symbs_rule R a).
    (* def_symbs_rule R a = Some (x,l) *)
    right. exists a. intuition. apply rel_add_edge_list. rewrite H0.
    destruct p as [x l]. left. unfold succ_list. rewrite <- In_InA_eq.
    unfold def_symbs_rule in H0. unfold root_eq in H. destruct (lhs a).
    discr. rewrite beq_symb_ok in H. inversion H0. subst f0. intuition.
    (* def_symbs_rule R a = None *)
    intuition. unfold def_symbs_rule in H0. unfold root_eq in H.
    destruct (lhs a); discr.
  Qed.

  Definition succs_symb' R f :=
    XSet.elements (succs f (trans_clos_list (def_symbs_rule R) R)).

  Lemma succs_symbP' : forall R f g,
    List.In g (succs_symb' R f) <-> symb_ord R! f g.

  Proof.
    intros R f g. unfold succs_symb'. rewrite In_InA_eq.
    rewrite <- elements_iff. rewrite In_succs_rel.
    gen g; gen f. rewrite <- rel_eq. rewrite rel_trans_clos_list.
    rewrite def_symbs_rule_ok. refl.
  Qed.

  Definition succs_symb R f := f :: succs_symb' R f.

  Lemma succs_symbP : forall R f g,
    List.In g (succs_symb R f) <-> symb_ord R# f g.

  Proof.
    intros R f g. unfold succs_symb. simpl. rewrite succs_symbP'.
    ded (rtc_split_eq (symb_ord R)). rewrite rel_eq in H. firstorder.
  Qed.

  Definition Sig := ABinary.Make WP.Sig B.some_symbol B.arity_some_symbol_eq_2.

  Notation P := (proj_cons Sig).

  Definition WP : weakRedPairType WP.Sig.

  Proof.
    eapply mkWP. apply WF_notIS. apply WP.wf_succ. apply WP.sc_succ.
    apply WP.bsucc_sub. apply WP.sc_succeq. apply WP.cc_succeq.
    apply WP.refl_succeq. apply WP.trans_succeq. apply WP.trans_succ.
    apply WP.succ_succeq_compat. apply WP.bsucceq_sub.
  Defined.

  Notation bsucc := (bsucc WP). Notation bsucceq := (bsucceq WP).

  Lemma usable_rules_criterion : forall M D,
    let D' := List.filter (brule (neg bsucc)) D in
    let UC := usable_rules succs_symb M D in
    let G := fun f => defined f M && negb (defined f UC) in
      D [= dp M ->
      brules_preserve_vars M = true ->
      forallb (@is_notvar_lhs Sig) M = true ->
      brules_preserve_vars D = true ->
      ListUtil.is_empty
        (List.filter (fun x => defined x M) (list_defined D)) = true ->
      forallb (@is_notvar_lhs Sig) D = true ->
      forallb (brule bsucceq) (UC ++ P) = true ->
      forallb (brule (fun x y => bsucceq x y || bsucc x y)) D = true ->
      WF (hd_red_Mod (red M #) D') -> WF (hd_red_Mod (red M #) D).

  Proof.
    intros. eapply usable_rules_criterion with (Sig:=Sig); try eassumption.
    apply succs_symbP. hyp.
  Qed.

  Ltac prove_termin := apply usable_rules_criterion;
    match goal with
      | |- WF _ => idtac
      | |- _ = _ => check_eq || fail 10 "condition not satisfied"
    end.

End Usable.
