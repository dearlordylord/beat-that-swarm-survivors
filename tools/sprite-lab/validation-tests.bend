import Base
import ./artwork.bend as A
import ./validation.bend as V

# Finite checks of the actual authored catalog, not universal gait proofs.
def catalog_accepted() -> {V.valid() == True{} : Bool}:
  {==}

def excessive_lift_rejected() -> {V.pose_valid(A.Pose{3n, 0n, 0n, 0n}) == False{} : Bool}:
  {==}

def both_feet_airborne_rejected() -> {V.pose_valid(A.Pose{1n, 1n, 0n, 0n}) == False{} : Bool}:
  {==}

def excessive_bob_rejected() -> {V.pose_valid(A.Pose{0n, 0n, 0n, 2n}) == False{} : Bool}:
  {==}
