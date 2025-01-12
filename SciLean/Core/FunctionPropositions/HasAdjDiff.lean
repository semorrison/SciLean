import SciLean.Core.FunctionPropositions.IsDifferentiable
import SciLean.Core.FunctionPropositions.HasSemiAdjoint
import SciLean.Core.FunctionPropositions.HasAdjDiffAt

import SciLean.Core.FunctionTransformations.CDeriv

set_option linter.unusedVariables false

namespace SciLean

variable 
  (K : Type _) [IsROrC K]
  {X : Type _} [SemiInnerProductSpace K X]
  {Y : Type _} [SemiInnerProductSpace K Y]
  {Z : Type _} [SemiInnerProductSpace K Z]
  {ι : Type _} [Fintype ι] [DecidableEq ι]
  {E : ι → Type _} [∀ i, SemiInnerProductSpace K (E i)]

def HasAdjDiff (f : X → Y)  : Prop := IsDifferentiable K f ∧ ∀ x, HasSemiAdjoint K (cderiv K f x)

namespace HasAdjDiff

variable (X)
theorem id_rule
  : HasAdjDiff K (fun x : X => x) := 
by 
  constructor; fprop; ftrans; fprop

theorem const_rule (y : Y)
  : HasAdjDiff K (fun _ : X => y) := 
by 
  constructor; fprop; ftrans; fprop

variable {X}

variable (E)
theorem proj_rule
  (i : ι)
  : HasAdjDiff K (fun x : (i : ι) → E i => x i) := 
by 
  constructor; fprop; ftrans; fprop

variable {E}

theorem comp_rule
  (f : Y → Z) (g : X → Y)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : HasAdjDiff K (fun x => f (g x)) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop

theorem let_rule
  (f : X → Y → Z) (g : X → Y)
  (hf : HasAdjDiff K (fun (xy : X×Y) => f xy.1 xy.2))
  (hg : HasAdjDiff K g)
  : HasAdjDiff K (fun x => let y := g x; f x y) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop
  
theorem pi_rule
  (f : (i : ι) → X → E i)
  (hf : ∀ i, HasAdjDiff K (f i))
  : HasAdjDiff K (fun x i => f i x) := 
by 
  have := fun i => (hf i).1
  have := fun i => (hf i).2
  constructor; fprop; ftrans; fprop


--------------------------------------------------------------------------------
-- Register HadAdjDiff ---------------------------------------------------------
--------------------------------------------------------------------------------

open Lean Meta SciLean FProp
def fpropExt : FPropExt where
  fpropName := ``HasAdjDiff
  getFPropFun? e := 
    if e.isAppOf ``HasAdjDiff then

      if let .some f := e.getArg? 6 then
        some f
      else 
        none
    else
      none

  replaceFPropFun e f := 
    if e.isAppOf ``HasAdjDiff then
      e.modifyArg (fun _ => f) 6 
    else          
      e

  identityRule    e := do
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``id_rule
      origin := .decl ``id_rule
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  constantRule    e :=
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``const_rule
      origin := .decl ``const_rule
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  projRule e :=
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``HasAdjDiff.proj_rule 
      origin := .decl ``HasAdjDiff.proj_rule 
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  compRule e f g := do
    let .some K := e.getArg? 0 | return none

    let thm : SimpTheorem :=
    {
      proof  := ← mkAppM ``comp_rule #[K,f,g]
      origin := .decl ``comp_rule
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  lambdaLetRule e f g := do
    let .some K := e.getArg? 0 | return none

    let thm : SimpTheorem :=
    {
      proof  := ← mkAppM ``let_rule #[K,f,g]
      origin := .decl ``let_rule
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  lambdaLambdaRule e _ :=
    let thm : SimpTheorem :=
    {
      proof  := mkConst ``pi_rule 
      origin := .decl ``pi_rule 
      rfl    := false
    }
    FProp.tryTheorem? e thm (fun _ => pure none)

  discharger e := 
    FProp.tacticToDischarge (Syntax.mkLit ``Lean.Parser.Tactic.assumption "assumption") e


-- register fderiv
#eval show Lean.CoreM Unit from do
  modifyEnv (λ env => FProp.fpropExt.addEntry env (``HasAdjDiff, fpropExt))


end SciLean.HasAdjDiff

--------------------------------------------------------------------------------
-- Function Rules --------------------------------------------------------------
--------------------------------------------------------------------------------

open SciLean

variable 
  (K : Type _) [IsROrC K]
  {X : Type _} [SemiInnerProductSpace K X]
  {Y : Type _} [SemiInnerProductSpace K Y]
  {Z : Type _} [SemiInnerProductSpace K Z]
  {ι : Type _} [Fintype ι] [DecidableEq ι]
  {E : ι → Type _} [∀ i, SemiInnerProductSpace K (E i)] 


-- Id --------------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem id.arg_a.HasAdjDiff_rule (x : X)
  : HasAdjDiff K (id : X → X) := by constructor; fprop; ftrans; fprop


-- Prod ------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Prod.mk --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Prod.mk.arg_fstsnd.HasAdjDiff_rule
  (g : X → Y) (hg : HasAdjDiff K g)
  (f : X → Z) (hf : HasAdjDiff K f)
  : HasAdjDiff K (fun x => (g x, f x)) := 
by 
  have ⟨_,_⟩ := hg
  have ⟨_,_⟩ := hf
  constructor; fprop; ftrans; fprop


-- Prod.fst --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Prod.fst.arg_self.HasAdjDiff_rule 
  (f : X → Y×Z) (hf : HasAdjDiff K f)
  : HasAdjDiff K (fun x => (f x).1) := 
by 
  have ⟨_,_⟩ := hf
  constructor; fprop; ftrans; fprop



-- Prod.snd --------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Prod.snd.arg_self.HasAdjDiff_rule 
  (f : X → Y×Z) (hf : HasAdjDiff K f)
  : HasAdjDiff K (fun x => (f x).2) := 
by 
  have ⟨_,_⟩ := hf
  constructor; fprop; ftrans; fprop


-- cderiv ----------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem SciLean.cderiv.arg_dx.HasSemiAdjoint_rule
  (f : Y → Z) (g : X → Y) (y : Y)
  (hf : HasAdjDiff K f) (hg : HasSemiAdjoint K g)
  : HasSemiAdjoint K fun dx => cderiv K f y (g dx) :=
by
  apply HasSemiAdjoint.comp_rule K (cderiv K f y) g (hf.2 y) hg


-- Function.comp ---------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Function.comp.arg_a0.HasAdjDiff_rule
  (g : X → Y) (hg : HasAdjDiff K g)
  (f : Y → Z) (hf : HasAdjDiff K f)
  : HasAdjDiff K (f ∘ g) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop


-- Neg.neg ---------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem Neg.neg.arg_a0.HasAdjDiff_rule
  (f : X → Y) (hf : HasAdjDiff K f)
  : HasAdjDiff K (fun x => - f x) := 
by 
  have ⟨_,_⟩ := hf
  constructor; fprop; ftrans; fprop


-- HAdd.hAdd -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem HAdd.hAdd.arg_a0a1.HasAdjDiff_rule
  (f g : X → Y) (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : HasAdjDiff K (fun x => f x + g x) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop


-- HSub.hSub -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[fprop]
theorem HSub.hSub.arg_a0a1.HasAdjDiff_rule
  (x : X) (f g : X → Y) (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : HasAdjDiff K (fun x => f x - g x) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop
 

-- HMul.hMul -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[fprop]
def HMul.hMul.arg_a0a1.HasAdjDiff_rule
  (x : X) (f g : X → K) (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : HasAdjDiff K (fun x => f x * g x) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop


-- SMul.sMul -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

open ComplexConjugate in
@[fprop]
theorem HSMul.hSMul.arg_a1.HasAdjDiff_rule
  (c : K) (g : X → Y) (x : X) (hg : HasAdjDiff K g)
  : HasAdjDiff K (fun x => c • g x) :=
by 
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop



@[fprop]
def HSMul.hSMul.arg_a0a1.HasAdjDiff_rule
  {Y : Type _} [NormedAddCommGroup Y] [InnerProductSpace K Y] [CompleteSpace Y]
  (x : X) (f : X → K) (g : X → Y) 
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : HasAdjDiff K (fun x => f x • g x) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop


-- HDiv.hDiv -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[fprop]
def HDiv.hDiv.arg_a0a1.HasAdjDiff_rule
  (f : X → K) (g : X → K) 
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g) (hx : ∀ x, g x ≠ 0)
  : HasAdjDiff K (fun x => f x / g x) := 
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; fprop


-- HPow.hPow -------------------------------------------------------------------
-------------------------------------------------------------------------------- 

@[fprop]
def HPow.hPow.arg_a0.HasAdjDiff_rule
  (n : Nat) (x : X) (f : X → K) (hf : HasAdjDiff K f)
  : HasAdjDiff K (fun x => f x ^ n) := 
by 
  have ⟨_,_⟩ := hf
  constructor; fprop; ftrans; fprop



--------------------------------------------------------------------------------

section InnerProductSpace

variable 
  {K : Type _} [IsROrC K]
  {X : Type _} [SemiInnerProductSpace K X]
  {Y : Type _} [NormedAddCommGroup Y] [InnerProductSpace K Y] [CompleteSpace Y]

-- Inner -----------------------------------------------------------------------
-------------------------------------------------------------------------------- 

open ComplexConjugate

@[fprop]
theorem Inner.inner.arg_a0a1.HasAdjDiff_rule
  (f : X → Y) (g : X → Y)
  (hf : HasAdjDiff K f) (hg : HasAdjDiff K g)
  : HasAdjDiff K fun x => ⟪f x, g x⟫[K] :=
by 
  have ⟨_,_⟩ := hf
  have ⟨_,_⟩ := hg
  constructor; fprop; ftrans; simp; fprop


end InnerProductSpace
