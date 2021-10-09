import SciLean.Basic

set_option synthInstance.maxHeartbeats 50000
set_option synthInstance.maxSize 10000

variable {α β γ : Type} 
variable {X : Type} {Y : Type} {Z : Type} [Vec X] [Vec Y] [Vec Z]
variable {U : Type} {V : Type} {W : Type} [Hilbert U] [Hilbert V] [Hilbert W]

section 
variable (c d : ℝ) (x dx : X) (y z : X)
def dtest1 : IsDiff ((subs (comp HAdd.hAdd (swap HAdd.hAdd y)) id) : X → X) := by infer_instance done
def dtest2 : IsDiff ((subs (comp HAdd.hAdd (HAdd.hAdd y)) id) : X → X) := by infer_instance done
def dtest3 : IsDiff ((subs HMul.hMul id) : ℝ → ℝ) := by infer_instance done
def dtest4 : IsDiff ((HMul.hMul c) : ℝ → ℝ) := by infer_instance done
end

section
variable (c d : ℝ) (x dx : X) (y z : X)
def xtest1 : δ (λ x : X => x) x dx = dx := by autodiff done
def xtest2 : δ (λ x : X => c * x) x dx = c * dx := by autodiff done
def xtest3 : δ (λ x : X => x + y) x dx = dx := by autodiff done 
def xtest4 : δ (λ x : X => x + x) x dx = dx + dx := by autodiff done
def xtest5 : δ (λ x : X => c * x + d * x + y) x dx = c * dx + d * dx := by autodiff done
def xtest6 : δ (λ x : X => c * x + y + d * x) x dx = c * dx + d * dx := by autodiff done
def xtest7 : δ (λ x : X => y + c * x + d * x) x dx = c * dx + d * dx := by autodiff done
end

section
variable (c x dx : ℝ)
def rtest1 : δ (λ x : ℝ => c * x) x dx = c * dx := by autodiff done
def rtest2 : δ (λ x : ℝ => x * x) x dx = dx * x + x * dx := by autodiff done
def rtest3 : δ (λ x : ℝ => x * x * x) x dx = (dx * x + x * dx) * x + x * x * dx := by autodiff done
def rtest4 : δ (λ x : ℝ => x * (x * x) * x) x dx = (dx * (x * x) + x * (dx * x + x * dx)) * x + x * (x * x) * dx := by autodiff done
end

section 
variable (f : X → X) (c : ℝ → X) [IsDiff f] [IsDiff c]
variable (t : ℝ) 
def ddtest1 : ⅆ (comp f c) t = δ f (c t) (ⅆ c t) := by simp done
def ddtest2 : ⅆ (comp f (comp f c)) t = δ f (f (c t)) (δ f (c t) (ⅆ c t)) := by simp done
def ddtest3 : ⅆ (comp (comp f f) c) t = δ f (f (c t)) (δ f (c t) (ⅆ c t)) := by simp done
end

section 
variable (x dx y : U)
def htest1 : δ (λ x => ⟨x, y⟩) x dx = ⟨dx, y⟩ := by autodiff done
def htest2 : δ (λ x => ⟨x, x⟩) x dx = ⟨dx, x⟩ + ⟨x, dx⟩ := by autodiff done
def htest3 : δ (λ x => ⟨x, ⟨x,x⟩*x⟩) x dx = ⟨dx,⟨x,x⟩*x⟩ + ⟨x,(⟨dx,x⟩+⟨x,dx⟩)*x + ⟨x,x⟩*dx⟩:= by autodiff done
end

section 
variable (x dx y : U)
-- def gtest1 : ∇ (λ x => ⟨x, y⟩) x = y := by autograd done
-- def gtest2 : ∇ (λ x => ⟨x, x⟩) x = x + x := by autograd done
-- def gtest3 : ∇ (λ x => ⟨x, x⟩*⟨x, x⟩) x = (⟨x,x⟩ : ℝ) * x + (⟨x,x⟩:ℝ)*x + ((⟨x,x⟩:ℝ)*x + (⟨x,x⟩:ℝ)*x) := by rmlamlet; simp[gradient]; rw[dual_intro]; simp; autodiff done
-- def gtest4 (c : ℝ) : ∇ (λ x => c * ⟨x, x⟩) x = c * x + c * x := by rmlamlet; simp[gradient]; rw[dual_intro]; simp; autodiff done
end

-- Tests for differentiable monads
section
variable (x dx y : U)

def mtest1 
 : δ (λ x₀ : U => do 
       let mut x := x₀
       let mut y := x₀
       x := x + x 
       y := x + y
       x + y) x dx
   =
   (dx + dx) + ((dx + dx) + dx)
   := by rmlamlet; admit;

end

-- ForIn tests
section 
variable (x dx y : U)

def ftest1 (a b : Nat) (f : U → U)
 : δ (λ x₀ : U => do 
       let mut x := x₀
       for i in [a:b] do
         x := f x
       x) x dx
   =
   dx 
   := by rmlamlet; admit

end



-- def mutForLoop {X: Type} (n : Nat) (f : Nat → X → X) (x₀ : X) : X :=
-- do
--   let mut x := x₀
--   for i in [0 : n] do
--     x := f i x
--   x

-- #check (@forIn Id _ _ )

-- -- This needs [IsSmooth f] 
-- -- def forLoopIsDiff_1 {X} [Vec X] (n:Nat) : IsDiff ((comp (swap (@forIn Id _ _ _ _ _ ([0 : n]))) (comp (comp ForInStep.yield))) : ((Nat → X → X) → X → X)) := sorry




-- def Impl {α} (a : α) := α 

-- #check (@forIn)

-- #check (@Std.Range.forIn.loop)



-- def hihi {X Y : Type} (n : Nat) : Impl (λ (f : Nat → X → X) (x₀ : X) => mutForLoop n f x₀) :=
-- by
--   simp [mutForLoop];
--   rmlamlet
  
--   simp [forIn];
--   simp [Std.Range.forIn];
--   simp [Std.Range.forIn];
--   simp [ForInStep.yield]
--   admit

-- def hoho {X Y : Type} (n : Nat) (f : Nat → X → X) : Impl (λ (x₀ : X) => mutForLoop n f x₀) :=
-- by
--   simp [mutForLoop];
--   rmlamlet; 

--   admit


-- def haha {X Y : Type} (n : Nat) (f : Nat → X → X) (x₀ : X) : Impl (mutForLoop n f x₀) :=
-- by
--   simp [mutForLoop];
--   rmlamlet

--   admit



  
-- @[simp] def adsfe {X Y} (p : X × Y) : (p.1, p.2) = p := by induction p; simp
