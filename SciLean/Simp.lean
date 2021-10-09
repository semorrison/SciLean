import SciLean.Algebra

variable {X Y Z : Type} [Vec X] [Vec Y] [Vec Z]
variable {U V W : Type} [Hilbert U] [Hilbert V] [Hilbert W]

@[simp] theorem add_zero (x : X) : x + 0 = x := sorry
@[simp] theorem zero_add (x : X) : 0 + x = x := sorry

@[simp] theorem mul_one (x : ℝ) : x * 1 = x := sorry
@[simp] theorem one_mul (x : X) : (1:ℝ) * x = x := sorry

@[simp] theorem neg_neg (x : X) : - - x = x := sorry

@[simp] theorem neg_sub (x y : X) : x - (-y) = x + y := sorry
@[simp] theorem add_neg (x y : X) : x + (-y) = x - y := sorry

@[simp] theorem mul_neg_neg (r : ℝ) (x : X) : (-r) * (-x) = r * x := sorry
@[simp] theorem mul_neg_1 (r : ℝ) (x : X) : (-r) * x = -(r * x) := sorry
@[simp] theorem mul_neg_2 (r : ℝ) (x : X) : r * (-x) = -(r * x) := sorry

@[simp] theorem pair_mul (r : ℝ) (x : X) (y : Y) : (r * x, r * y) = r * (x, y) := sorry

@[simp] theorem inner_mul (r : ℝ) (x y : U) : ⟨r * x, r * y⟩ = (r*r) * ⟨x,y⟩ := sorry
@[simp] theorem inner_prod (u u' : U) (v v' : V) : ⟨(u,v), (u',v')⟩ = ⟨u,u'⟩ + ⟨v,v'⟩ := sorry
@[simp] theorem inner_real (x y : ℝ) : ⟨x, y⟩ = x * y := sorry

@[simp] theorem add_same_1 (a b : ℝ) (x : X) : a*x + b*x = (a+b)*x := sorry
@[simp] theorem add_same_2 (a : ℝ) (x : X) : a*x + x = (a+1)*x := sorry
@[simp] theorem add_same_3 (a : ℝ) (x : X) : x + a*x = (1+a)*x := sorry
@[simp] theorem add_same_4 (x : X) : x + x = (2:ℝ)*x := sorry

@[simp] theorem smul_smul_mul (a b : ℝ) (x : X) : a * (b * x) = (a*b) * x := sorry

@[simp] theorem prod_sum (x x' : X) (y y' : Y) : (x, y) + (x', y') = (x + x', y + y') := sorry


-- @[simp] theorem real_nat_mul (n m : Nat) : ((OfNat.ofNat n) : ℝ) * ((OfNat.ofNat m) : ℝ) = (( (m*n)) : ℝ) := sorry


