import SciLean.Core.Defs

namespace SciLean

class UnsafeAD : Prop where
  kaboom : False

class IgnoreFunProp : Prop where
  kaboom : False

/-- 
Allows automatic differentiation to perform inconsistent rewrites like `∀ x∈ℝ, d/dx (1/x) = -1/x²` or differentiate through if statements like `if 0 < x then x else 0`.

The set of inconsistent rewrites is carefully chosen such that automatic differentiation outputs reasonable answer, e.g. the result is correct almost everywhere, but right now we do not provide any formal guarantees.

Yes we agree, this is not an ideal state of affairs! Assuming inconsistency is not great but not having these rewrites would severely limit the usefullness of automatic differentiation. Hopefully, in the future we will have a better way to handle this. One potential solution would be for AD to also produce a set where the result is valid.
-/
macro (name:=unsafeADTactic) "unsafe_ad" : tactic => 
  `(tactic| have unsafe_ad : UnsafeAD := sorry_proof)

@[inherit_doc unsafeADTactic]
macro (name:=unsafeADConv) "unsafe_ad" : conv => `(conv| tactic => unsafe_ad)


/-- 
Do not check certain function propositions. The main purpose of this is to speed up automatic differentiation.

Every function is is now assumed to satisfy:
  - `IsSmooth`
  - `HasAdjDiff`
-/
macro (name:=ignoreFunPropTactic) "ignore_fun_prop" : tactic => 
  `(tactic| have ignore_fun_prop : IgnoreFunProp := sorry_proof)

@[inherit_doc ignoreFunPropTactic] 
macro (name:=ignoreFunPropConv) "ignore_fun_prop" : conv => `(conv| tactic => ignore_fun_prop)


instance (priority:=high) [inst : IgnoreFunProp] {X Y} [Vec X] [Vec Y] (f : X → Y) 
  : IsSmooth f := inst.kaboom.elim

instance (priority:=high) [inst : IgnoreFunProp] {X Y} [SemiHilbert X] [SemiHilbert Y] (f : X → Y) 
  : HasAdjDiff f := inst.kaboom.elim

instance (priority:=high) [inst : IgnoreFunProp] {X Y} [SemiHilbert X] [SemiHilbert Y] (f : X → Y) 
  : HasAdjoint f := inst.kaboom.elim


instance (priority:=high) [inst : IgnoreFunProp] {X Y} [Nonempty X] (f : X → Y) 
  : IsInv f := inst.kaboom.elim
