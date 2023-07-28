import SciLean.FTrans.Broadcast.BroadcastType 
import SciLean.Tactic.FTrans.Basic

namespace SciLean


/--
Broadcast vectorizes operations. For example, broadcasting multiplication `fun (x : ℝ) => c * x` will produce scalar multiplication `fun (x₁,...,xₙ) => (c*x₁,...,c*x₂)`.
  
Arguments

1. `tag` - type of broadcasting. The most versatile is `Prod` but dense and sparse matrices are planed in the future.
2. `R`   - field/ring over which we do broadcasting. This is usually ℝ or ℂ. Right now, it is not clear what is the role of this argument for broadcasting, but we need it to specify 
3. `ι`   - broadcast to `ι`-many copies. For example, with `ι := Fin 2` broadcasting `ℝ → ℝ` will produce `ℝ×ℝ → ℝ×ℝ`(for `tag:=Prod`) or `NArray ℝ 2 → NArray ℝ 2`(for `tag := NArray`, currently not supported)
              
-/
def broadcast (tag : Name) (R : Type _) [Ring R]
  {X : Type _} [AddCommGroup X] [Module R X]
  {Y : Type _} [AddCommGroup Y] [Module R Y]
  {MX : Type _} [AddCommGroup MX] [Module R MX]
  {MY : Type _} [AddCommGroup MY] [Module R MY]
  (ι : Type _) [BroadcastType tag R ι X MX] [BroadcastType tag R ι Y MY]
  (f : X → Y) : MX → MY := fun mx =>
  (BroadcastType.equiv tag (R:=R)).symm fun (i : ι) => f ((BroadcastType.equiv tag (R:=R)) mx i)

def broadcastProj (tag : Name) (R : Type _) [Ring R]
  {X : Type _} [AddCommGroup X] [Module R X]
  {MX : Type _} [AddCommGroup MX] [Module R MX]
  {ι : Type _} [BroadcastType tag R ι X MX]
  (mx : MX) (i : ι) : X := (BroadcastType.equiv tag (R:=R)) mx i

def broadcastIntro (tag : Name) (R : Type _) [Ring R]
  {X : Type _} [AddCommGroup X] [Module R X]
  {MX : Type _} [AddCommGroup MX] [Module R MX]
  {ι : Type _} [BroadcastType tag R ι X MX]
  (f : ι → X) : MX := (BroadcastType.equiv tag (R:=R)).symm f


-- Basic lambda calculus rules -------------------------------------------------
--------------------------------------------------------------------------------

section Rules

variable 
  {R : Type _} [Ring R]
  {X : Type _} [AddCommGroup X] [Module R X]
  {Y : Type _} [AddCommGroup Y] [Module R Y]
  {Z : Type _} [AddCommGroup Z] [Module R Z]
  {ι : Type _} {tag : Name}
  {MX : Type _} [AddCommGroup MX] [Module R MX] [BroadcastType tag R ι X MX]
  {MY : Type _} [AddCommGroup MY] [Module R MY] [BroadcastType tag R ι Y MY]
  {MZ : Type _} [AddCommGroup MZ] [Module R MZ] [BroadcastType tag R ι Z MZ]
  {κ : Type _} -- [Fintype κ]
  {E ME : κ → Type _} 
  [∀ j, AddCommGroup (E j)] [∀ j, Module R (E j)]
  [∀ j, AddCommGroup (ME j)] [∀ j, Module R (ME j)]
  [∀ j, BroadcastType tag R ι (E j) (ME j)]


theorem id_rule 
  : broadcast tag R ι (fun (x : X) => x)
    =
    fun (mx : MX) => mx := 
by 
  simp[broadcast]


theorem const_rule (x : X)
  : broadcast tag R ι (fun (_ : Y) => x)
    =
    fun (_ : MY) => broadcastIntro tag R (fun (_ : ι) => x) := 
by 
  simp[broadcast, broadcastIntro]


theorem proj_rule (j : κ)
  : broadcast tag R ι (fun (x : (j : κ) → E j) => x j)
    =
    fun (mx : (j : κ ) → ME j) => mx j := 
by 
  simp[broadcast, broadcastIntro, BroadcastType.equiv]


theorem comp_rule 
  (g : X → Y) (f : Y → Z)
  : broadcast tag R ι (fun x => f (g x))
    =
    fun mx => broadcast tag R ι f (broadcast tag R ι g mx) :=
by
  simp[broadcast]


theorem let_rule 
  (g : X → Y) (f : X → Y → Z)
  : broadcast tag R ι (fun x => let y := g x; f x y)
    =
    fun mx =>
      let my := broadcast tag R ι g mx
      let mz := broadcast tag R ι (fun (xy : X×Y) => f xy.1 xy.2) (mx,my)
      mz :=
by
  rw[comp_rule (fun x' => (x', g x')) (fun (xy : X×Y) => f xy.1 xy.2)]
  funext mx; simp[broadcast, BroadcastType.equiv]
  

theorem pi_rule
  (f : (j : κ) → X → E j)
  : broadcast tag R ι (fun x j => f j x)
    =
    fun mx j => (broadcast tag R ι (f j) mx) :=
by
  funext mx j
  simp[broadcast,BroadcastType.equiv]
  
  
end Rules


-- Register `broadcast` as function transformation -----------------------------
--------------------------------------------------------------------------------

open Lean Meta Qq

def broadcast.discharger (e : Expr) : SimpM (Option Expr) := return none
  -- withTraceNode `broadcast_discharger (fun _ => return s!"discharge {← ppExpr e}") do
  -- let cache := (← get).cache
  -- let config : FProp.Config := {}
  -- let state  : FProp.State := { cache := cache }
  -- let (proof?, state) ← FProp.fprop e |>.run config |>.run state
  -- modify (fun simpState => { simpState with cache := state.cache })
  -- return proof?

open Lean Elab Term FTrans
def broadcast.ftransExt : FTransExt where
  ftransName := ``broadcast

  getFTransFun? e := 
    if e.isAppOf ``broadcast then

      if let .some f := e.getArg? 19 then
        some f
      else 
        none
    else
      none

  replaceFTransFun e f := 
    if e.isAppOf ``broadcast then
      e.modifyArg (fun _ => f) 19
    else          
      e

  idRule    := tryNamedTheorem ``id_rule discharger
  constRule := tryNamedTheorem ``const_rule discharger
  projRule  := tryNamedTheorem ``proj_rule discharger
  compRule  e f g := do
    let .some K := e.getArg? 0
      | return none

    let mut thrms : Array SimpTheorem := #[]

    thrms := thrms.push {
      proof := ← mkAppM ``comp_rule #[K, f, g]
      origin := .decl ``comp_rule
      rfl := false
    }

    for thm in thrms do
      if let some result ← Meta.Simp.tryTheorem? e thm discharger then
        return Simp.Step.visit result
    return none

  letRule e f g := do
    let .some K := e.getArg? 0
      | return none

    let mut thrms : Array SimpTheorem := #[]

    thrms := thrms.push {
      proof := ← mkAppM ``let_rule #[K, f, g]
      origin := .decl ``comp_rule
      rfl := false
    }

    for thm in thrms do
      if let some result ← Meta.Simp.tryTheorem? e thm discharger then
        return Simp.Step.visit result
    return none

  piRule  e f := do
    let .some K := e.getArg? 0
      | return none

    let mut thrms : Array SimpTheorem := #[]

    thrms := thrms.push {
      proof := ← mkAppM ``pi_rule #[K, f]
      origin := .decl ``comp_rule
      rfl := false
    }

    for thm in thrms do
      if let some result ← Meta.Simp.tryTheorem? e thm discharger then
        return Simp.Step.visit result
    return none

  discharger := broadcast.discharger


-- register broadcast
#eval show Lean.CoreM Unit from do
  modifyEnv (λ env => FTrans.ftransExt.addEntry env (``broadcast, broadcast.ftransExt))


section Functions

variable 
  {R : Type _} [Ring R]
  {X : Type _} [AddCommGroup X] [Module R X]
  {Y : Type _} [AddCommGroup Y] [Module R Y]
  {Z : Type _} [AddCommGroup Z] [Module R Z]
  {ι : Type _} {tag : Name}
  {MR : Type _} [AddCommGroup MR] [Module R MR] [BroadcastType tag R ι R MR]
  {MX : Type _} [AddCommGroup MX] [Module R MX] [BroadcastType tag R ι X MX]
  {MY : Type _} [AddCommGroup MY] [Module R MY] [BroadcastType tag R ι Y MY]
  {MZ : Type _} [AddCommGroup MZ] [Module R MZ] [BroadcastType tag R ι Z MZ]
  {κ : Type _} -- [Fintype κ]
  {E ME : κ → Type _} 
  [∀ j, AddCommGroup (E j)] [∀ j, Module R (E j)]
  [∀ j, AddCommGroup (ME j)] [∀ j, Module R (ME j)]
  [∀ j, BroadcastType tag R ι (E j) (ME j)]


-- Prod ------------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans_rule]
theorem Prod.mk.arg_fstsnd.broadcast_comp
  (g : X → Y)
  (f : X → Z)
  : broadcast tag R ι (fun x => (g x, f x))
    =
    fun (mx : MX) => (broadcast tag R ι g mx,
                      broadcast tag R ι f mx) :=
by 
  funext mx; simp[broadcast, BroadcastType.equiv]


@[ftrans_rule]
theorem Prod.fst.arg_self.broadcast_comp
  (f : X → Y×Z)
  : broadcast tag R ι (fun x => (f x).1)
    =
    fun mx => (broadcast tag R ι f mx).1 := 
by 
  funext mx; simp[broadcast, BroadcastType.equiv]


@[ftrans_rule]
theorem Prod.snd.arg_self.broadcast_comp
  (f : X → Y×Z)
  : broadcast tag R ι (fun x => (f x).2)
    =
    fun mx => (broadcast tag R ι f mx).2 := 
by 
  funext mx; simp[broadcast, BroadcastType.equiv]



-- HAdd.hAdd -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans_rule]
theorem HAdd.hAdd.arg_a4a5.broadcast_comp (f g : X → Y)
  : (broadcast tag R ι fun x => f x + g x)
    =
    fun mx =>
      broadcast tag R ι f mx + broadcast tag R ι g mx := 
by 
  funext mx; unfold broadcast; rw[← map_add]; rfl



-- HSub.hSub -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans_rule]
theorem HSub.hSub.arg_a4a5.broadcast_comp (f g : X → Y)
  : (broadcast tag R ι fun x => f x - g x)
    =
    fun mx =>
      broadcast tag R ι f mx - broadcast tag R ι g mx := 
by 
  funext mx; unfold broadcast; rw[← map_sub]; rfl



-- Neg.neg ---------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans_rule]
theorem Neg.neg.arg_a2.broadcast_comp (f : X → Y)
  : (broadcast tag R ι fun x => - f x)
    =
    fun mx => - broadcast tag R ι f mx := 
by 
  funext mx; unfold broadcast; rw[← map_neg]; rfl



-- HMul.hmul -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans_rule]
theorem HMul.hMul.arg_a5.broadcast_comp
  (f : R → R) (c : R)
  : (broadcast tag R ι fun x => c * f x)
    =
    fun mx => c • (broadcast tag R ι f mx) :=
by
  funext mx; unfold broadcast; rw[← map_smul]; rfl


@[ftrans_rule]
theorem HMul.hMul.arg_a4.broadcast_comp
  {R : Type _} [CommRing R]
  {ι : Type _} {tag : Name}
  {MR : Type _} [AddCommGroup MR] [Module R MR] [BroadcastType tag R ι R MR]
  (f : R → R) (c : R)
  : (broadcast tag R ι fun x => f x * c)
    =
    fun mx => c • (broadcast tag R ι f mx)  :=
by
  funext mx; unfold broadcast; rw[← map_smul]; congr; funext i; simp[mul_comm]



-- SMul.smul -------------------------------------------------------------------
--------------------------------------------------------------------------------

@[ftrans_rule]
theorem SMul.smul.arg_a4.broadcast_comp
  (c : R) (f : X → Y) 
  : (broadcast tag R ι fun x => c • f x)
    = 
    fun mx => c • broadcast tag R ι f mx := 
by
  funext mx; unfold broadcast; rw[← map_smul]; rfl


-- This has to be done for each `tag` reparatelly as we do not have access to elemntwise operations
@[ftrans_rule]
theorem SMul.smul.arg_a3.broadcast_comp
  (f : X → R) (y : Y) 
  [BroadcastType `Prod R (Fin n) X MX]
  [BroadcastType `Prod R (Fin n) Y MY]
  : (broadcast `Prod R (Fin (n+1)) fun x => f x • y)
    =
    fun (x,mx) => (f x • y, (broadcast `Prod R (Fin n) fun x => f x • y) mx) := 
by 
  funext mx; unfold broadcast; rfl



end Functions
