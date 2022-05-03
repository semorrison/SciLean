import Lean
import Init.Classical

import SciLean.NewStyle.IsSmooth

namespace SciLean

variable {α β γ : Type}
variable {X Y Z : Type} [Vec X] [Vec Y] [Vec Z] 
variable {Y₁ Y₂ : Type} [Vec Y₁] [Vec Y₂]

------------------
-- Differential --
------------------
-- @[irreducible] -- this does not work work as intended and I switched to `constant`
noncomputable 
def differential (f : X → Y) (x dx : X) : Y := 
    match Classical.propDecidable (IsSmooth f) with
      | isTrue  h => sorry
      | _ => (0 : Y)

prefix:max "δ" => differential

----------------------------------------------------------------------

@[simp, diff_core]
theorem id.arg_x.diff_simp
  : δ (λ x : X => x) = λ x dx => dx := sorry

@[simp, diff_core]
theorem const.arg_y.diff_simp (x : X)
  : δ (λ y : Y => x) = λ y dy => (0 : X) := sorry

@[simp low-3]
theorem diff_of_swap (f : α → X → Y) [∀ i, IsSmooth (f i)]
  : δ (λ x a => f a x) = λ x dx a => δ (f a) x dx := sorry

@[simp low-1, diff_core low-1]
theorem diff_of_comp
  (f : Y → Z) [IsSmooth f] 
  (g : X → Y) [IsSmooth g] 
  : δ (λ x => f (g x)) = λ x dx => δ f (g x) (δ g x dx) := sorry

@[simp low-2, diff_core low-2]
theorem diff_of_diag
  (f : Y₁ → Y₂ → Z) [IsSmooth f] [∀ y₁, IsSmooth (f y₁)]
  (g₁ : X → Y₁) [IsSmooth g₁]
  (g₂ : X → Y₂) [IsSmooth g₂]
  : δ (λ x => f (g₁ x) (g₂ x)) 
    = 
    λ x dx => δ f (g₁ x) (δ g₁ x dx) (g₂ x) + 
              δ (f (g₁ x)) (g₂ x) (δ g₂ x dx) := sorry

@[simp low, diff_core low]
theorem diff_of_parm
  (f : X → α → Y) [IsSmooth f] (a : α)
  : δ (λ x => f x a) = λ x dx => δ f x dx a := sorry