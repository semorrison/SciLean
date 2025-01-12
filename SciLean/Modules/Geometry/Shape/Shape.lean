import SciLean.Core
import Mathlib.Data.Real.EReal

namespace SciLean

/--
Shape parametrized by `P` living in `X`
-/
structure Shape {P X} [TopologicalSpace X] (toSet : P → Set X) where
  params : P  
  
  is_closed : ∀ p, IsClosed (toSet p)

namespace Shape

  variable {X} {toSet : P → Set X} [TopologicalSpace X]

  def asSet (s : Shape toSet) : Set X := toSet s.params
  def interior (s : Shape toSet) : Set X := _root_.interior (toSet s.params)
  def exterior (s : Shape toSet) : Set X := Set.univ \ closure (toSet s.params)
  def boundary (s : Shape toSet) : Set X := Set.univ \ (s.interior ∪ s.exterior)

  variable {P X : Type} [TopologicalSpace X] {toSet : P → Set X}

  ------------------------------------------------------------------------------
  -- Locate
  ------------------------------------------------------------------------------
  inductive Location | inside | boundary | outside 
  deriving Inhabited, BEq, Repr

  noncomputable 
  def locateSpec (s : Shape toSet) (x : X) : Location := 
    have := Classical.propDecidable
    if (x ∈ s.interior) then
      .inside
    else if (x ∈ s.exterior) then
      .outside
    else
      .boundary

  class HasLocate (toSet : P → Set X) where
    locate : Shape toSet → X → Location
    is_locate : locateSpec = locate

  attribute [simp] HasLocate.is_locate

  def locate [HasLocate toSet] (s : Shape toSet) (x : X) := HasLocate.locate s x

  ------------------------------------------------------------------------------
  -- Level Set 
  ------------------------------------------------------------------------------
  def IsLevelSet {R : Type _} [Zero R] [Ord R] (f : Shape toSet → X → R) (s : Shape toSet) (x : X) : Prop :=
    match compare 0 (f s x) with
    | .lt => s.locateSpec x = .outside
    | .gt => s.locateSpec x = .inside
    | .eq => s.locateSpec x = .boundary


  class HasLevelSet (R : outParam $ Type _) [Zero R] [Ord R] (toSet : P → Set X) where
    levelSet : Shape toSet → X → R
    is_level_set : ∀ s x, IsLevelSet levelSet s x

  def levelSet {R} [Zero R] [Ord R] [HasLevelSet R toSet] (s : Shape toSet) (x : X) := HasLevelSet.levelSet s x

  def locateFromLevelSet (R : Type _) [Zero R] [Ord R] [HasLevelSet R toSet] : HasLocate toSet := 
  {
    locate := λ s x =>
      match compare 0 (s.levelSet x) with
      | .lt => .outside
      | .gt => .inside
      | .eq => .boundary
    is_locate := sorry_proof
  }
  open BigOperators

  ------------------------------------------------------------------------------
  -- Signed Distance Function
  ------------------------------------------------------------------------------  
  noncomputable 
  def sdfSpec [EDist X] (s : Shape toSet) (x : X) : EReal := 
    have := Classical.propDecidable
    if ¬(x ∈ s.asSet) then
      sInf {edist x y | y ∈ s.asSet}
    else
      - sInf {edist x y | y ∈ Set.univ \ s.asSet}

  def IsOutsideDist {R} [IsReal R] [EDist X] (f : Shape toSet → X → ExtendedReal R) : Prop :=
    ∀ s x, (0 ≤ s.sdfSpec x) → (f s x).toEReal = s.sdfSpec x

  def IsInsideDist {R} [IsReal R] [EDist X] (f : Shape toSet → X → ExtendedReal R) : Prop :=
    ∀ s x, (s.sdfSpec x ≤ 0) → (f s x).toEReal = s.sdfSpec x

  def IsSdf {R} [IsReal R] [EDist X] (f : Shape toSet → X → ExtendedReal R) : Prop :=
    IsOutsideDist f ∧ IsInsideDist f

  class HasSdf (R : outParam $ Type _) [IsReal R] [EDist X] (toSet : P → Set X) where
    sdf (s : Shape toSet) (x : X) : ExtendedReal R
    is_sdf : IsSdf sdf
  
  def sdf {R} [IsReal R] [EDist X] [HasSdf R toSet] (s : Shape toSet) (x : X) := HasSdf.sdf s x

  def locateFromSdf {R} [IsReal R] [Ord R] [EDist X] [HasSdf R toSet] : HasLocate toSet := 
  {
    locate := λ s x =>
      match compare 0 (s.sdf x) with
      | .lt => .outside
      | .gt => .inside
      | .eq => .boundary
    is_locate := sorry_proof
  }
#exit
  ------------------------------------------------------------------------------
  -- Closest Point
  ------------------------------------------------------------------------------
  /--
  Finds a closest point on the boundary of `s` to the point `x` and also tells you if 
  `x` is inside/outside or on the boundary of `s`.
  If the closest point is not unique, it will just pick one.
  -/
  class HasClosestPoint (toSet : P → Set X) where
    closestPointLoc (s : Shape toSet) (x : X) : (Option X) × Location
    is_closest_point : (sorry : Prop)

  def closestPoint [HasClosestPoint toSet] (s : Shape toSet) (x : X) : Option X := 
    (HasClosestPoint.closestPointLoc s x).1

  def closestPointLoc [HasClosestPoint toSet] (s : Shape toSet) (x : X) : (Option X) × Location := 
    HasClosestPoint.closestPointLoc s x

  
  ------------------------------------------------------------------------------
  -- Shape Transform
  ------------------------------------------------------------------------------
  class HasTransform (toSet : P → Set X) (f : X → X) where
    trans : P → P
    is_trans : ∀ p x, x ∈ toSet p ↔ f x ∈ toSet (trans p)

  def trans (f : X → X) [HasTransform p f] (s : Shape p) : Shape p := ⟨HasTransform.trans p f s.params⟩

  -- Common transformations
  abbrev HasReflect (p : P → Set X) := HasTransform p Neg.neg
  abbrev HasTranslate (p : P → Set X) := ∀ t, HasTransform p λ x => x + t
  abbrev HasRotate (R : Type) [Group R] [LieGroup.SO R X] (p : P → Set X)  
    := ∀ r : R, HasTransform p λ x => r • x
  abbrev HasScale (p : P → Set X)  
    := ∀ s : ℝ, HasTransform p λ x => s • x
  abbrev HasMirror (p : P → Set X) := ∀ n : X, HasTransform p λ x => x - ((2 : ℝ) * ⟪x,n⟫) • n

  abbrev reflect [HasReflect p] (s : Shape p) := s.trans Neg.neg
  abbrev translate [HasTranslate p] (s : Shape p) (t : X) := s.trans λ x => x + t
  abbrev rotate {R : Type} [Group R] [LieGroup.SO R X] [HasRotate R p]
    (s : Shape p) (r : R) := s.trans λ x => r • x 
  abbrev scale [HasScale p] (s : Shape p) (r : ℝ) := s.trans λ x => r • x 
  abbrev mirror [HasMirror p] (s : Shape p) (n : X) := s.trans λ x => x - ((2 : ℝ) * ⟪x,n⟫) • n


  ------------------------------------------------------------------------------
  -- Minkowski Sum
  ------------------------------------------------------------------------------
  class HasMinkowskiSum (toSet₁ : P → Set X) (toSet₂ : Q → Set X) (toSet₃ : outParam $ R → Set X) where
    sum : P → Q → R
    is_sum : ∀ p q z, 
      (z ∈ toSet₃ (sum p q)) 
      ↔ 
      ∃ (x y : X), (z = x + y) ∧ (x ∈ toSet₁ p) ∧ (y ∈ toSet₂ q)


  ------------------------------------------------------------------------------
  -- Distance between two shapes
  ------------------------------------------------------------------------------
  noncomputable
  def distSpec (A : Shape p) (B : Shape q) : ℝ := sorry
    -- evaluate signed distance of minkowski sum of A,-B at the origin

  class HasDist (p : P → Set X) (q : Q → Set X) where
    dist (A : Shape p) (B : Shape q) : ℝ 
    is_dist : ∀ A B, distSpec A B = dist A B

  def dist [HasDist p q] (A : Shape p) (B : Shape q) : ℝ := HasDist.dist A B
  @[simp] theorem dist_spec [HasDist p q] (A : Shape p) (B : Shape q)
    : distSpec A B = dist A B := by apply HasDist.is_dist

  


end Shape
