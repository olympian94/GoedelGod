(* Formalization of Goedel's ontological argument in Isabelle/HOL *)
(* Authors: Christoph Benzmueller and Bruno Woltzenlogel-Paleo *)
(* Date: August 9, 2013 *)

theory GoedelGod
imports Main HOL

begin
typedecl i  (* the type for possible worlds *)
typedecl mu (* the type for indiviuals      *)

(* r is an accessibility relation *)
consts r :: "i => i => bool" (infixr "r" 70) 

(* r is reflexive, symmetric and transitive *)
axiomatization where 
  refl: "x r x" and
  sym: "x r y \<longrightarrow> y r x" and
  trans: "x r y & y r z \<longrightarrow> x r z"
  
(* classical negation lifted to possible worlds *)   
definition mnot :: "(i => bool) => (i => bool)" ("\<not>m") where
  "mnot p = (% W. \<not> p W)"

(* classical conjunction lifted to possible worlds *)
definition mand :: "(i => bool) => (i => bool) => (i => bool)" (infixr "\<and>m" 74) where
  "mand p q = (% W. p W & q W) "  

(* classical implication lifted to possible worlds *)
definition mimplies :: "(i => bool) => (i => bool) => (i => bool)" (infixr "\<Rightarrow>m" 79) where
  "mimplies p q = (% W. p W \<longrightarrow> q W)"

(* universial quantification over individuals lifted to possible worlds *)
definition mforall_ind :: "(mu => (i => bool)) => (i => bool)" ("\<forall>i") where
  "mforall_ind abstrP = (% W. \<forall> X.  abstrP X W)"  
  
(* existential quantification over individuals lifted to possible worlds *)
definition mexists_ind :: "(mu => (i => bool)) => (i => bool)" ("\<exists>i") where
  "mexists_ind abstrP = (% W. \<exists> X.  abstrP X W)"    
  
(* universial quantification over sets of individuals lifted to possible worlds *)
definition mforall_indset :: "((mu => (i => bool)) => (i => bool)) => (i => bool)" ("\<forall>iset") where
  "mforall_indset abstrP = (% W. \<forall> X.  abstrP X W)"

(* the s5 box operator based on r *)
definition mbox_s5 :: "(i => bool) => (i => bool)" ("\<box>") where
  "mbox_s5 p = (% W. \<forall> V. \<not> W r V \<or> p V)"
  
(* the s5 diamond operator based on r *)
definition mdia_s5 :: "(i => bool) => (i => bool)" ("\<diamond>") where
  "mdia_s5 p = (% W. \<exists> V. W r V \<and> p V)"  
  
(* grounding of lifted modal formulas *)
definition valid :: "(i => bool) => bool" ("v") where
  "valid p == (\<forall> W. p W)"    
  
(* constant positive *)
consts positive :: "(mu => (i => bool)) => (i => bool)"
  
axiomatization where
  (* ax1: Any property strictly implied by a positive property is positive. *)
  ax1: "v (\<forall>iset (%P. \<forall>iset (%Q. ((positive P) \<and>m \<box> (\<forall>i (%X. P X \<Rightarrow>m Q X))) \<Rightarrow>m positive Q )))" and
  (* ax2a: If a property is positive then its negation is not positive. *)
  ax2a: "v (\<forall>iset (%P. positive P \<Rightarrow>m \<not>m (positive (% W. \<not>m (P W)))))" and
  (* ax2b: A property is positive when its negation is not positive. *)
  ax2b: "v (\<forall>iset (%P. \<not>m (positive (% W. \<not>m (P W))) \<Rightarrow>m positive P))"

(* lemma1: Positive properties are eventually exemplified. *)
lemma lemma1: "v (\<forall>iset (%P. (positive P) \<Rightarrow>m \<diamond> (\<exists>i (%X. P X))))"
  (* lemma1 can be proved from ax1 and ax2a.
     sledgehammer with leo2 and satallax does find the proof; just try:
       sledgehammer [provers = remote_leo2 remote_satallax] 
     Even metis succeeds in finding the proof; see next *)
  using ax1 ax2a 
  unfolding mand_def mbox_s5_def mdia_s5_def mexists_ind_def 
            mforall_ind_def mforall_indset_def mimplies_def 
            mnot_def valid_def
  by metis

(* Definition of God: 
   X is God if and only if X incorporates all positive properties. *)
definition god :: "mu => (i => bool)" where
  "god = (% X. \<forall>iset (% P. (positive P) \<Rightarrow>m (P X)))"

(* ax3: The property of being God-like is positive. *)
axiomatization where
  ax3: "v (positive god)"

(* lemma2: Eventually God exists. *)
lemma lemma2: "v (\<diamond> (\<exists>i (% X. god X)))" 
  (* lemma2 can be proved from ax2a ax2b lemma1 ax3.
     sledgehammer succeeds; try this: 
     sledgehammer [provers = remote_leo2 remote_satallax] 
     Note below that god_def is not even needed.
   *)
  using ax3 lemma1 unfolding mforall_indset_def mimplies_def valid_def
  by metis

(* Definition of essential:
   Property P is essential for X (and essence of X) if and only if P is a 
   property of X and every property Q that X has is strictly implied by P. *)
definition essential :: "(mu => (i => bool)) => mu => (i => bool)" where
  "essential p x = ( p x \<and>m \<forall>iset (%Q. Q x \<Rightarrow>m \<box> (\<forall>i (%Y. p Y \<Rightarrow>m (Q Y)))))"

(* ax4: Positive properties are necessary positive properties. *)
axiomatization where
  ax4: "v (\<forall>iset (%P. positive P \<Rightarrow>m (\<box> (positive P))))"

(* lemma3: If X is a God-like being, then the property of being God-like 
   is an essence of X. *)
lemma lemma3: "v (\<forall>i (%X. god X \<Rightarrow>m (essential god X)))"
  using ax2a ax2b ax4 sym
  unfolding valid_def mforall_indset_def mforall_ind_def mexists_ind_def 
            mnot_def mand_def mimplies_def mdia_s5_def mbox_s5_def god_def 
            essential_def 
  by metis

(* Definition of necessary existence:
   X necessarily exists if and only if every essence of X is necessarily 
   exemplified. *)
definition nec_exists :: "mu => (i => bool)" where
  "nec_exists = (%X. (\<forall>iset (%P. essential P X \<Rightarrow>m \<box> (\<exists>i (%Y. P Y)))))"

(* ax5: Necessary existence is positive. *)
axiomatization where
  ax5: "v (positive nec_exists)"

(* thm1: Necessarily God exists. *)
theorem thm1: "v (\<box> (\<exists>i (%X. god X)))"
  using lemma2 lemma3 ax5 sym refl
  unfolding valid_def mforall_indset_def mforall_ind_def mexists_ind_def mnot_def mand_def mimplies_def mdia_s5_def mbox_s5_def god_def essential_def nec_exists_def 
  sledgehammer [timeout = 60, provers = remote_satallax] 
  (* sledgehammer can prove this statement; just try:
       sledgehammer [timeout = 120, provers = remote_leo2 remote_satallax] 
     and then it is suggested to use 
        by metis (> 3 s)
     but this does not succeed *)

 
(* Corollary cor1: God exists. *)
theorem cor1: "v (\<exists>i (%X. god X))"
  using thm1 refl
  unfolding valid_def mbox_s5_def
  by metis