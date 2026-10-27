import Base
import ./artwork.bend as A
import ./model.bend as M

def pose_valid(p: A.Pose) -> Bool:
  match p:
    case A.Pose{+ll, +rl, a, b}:
      Nat.is_le(ll, 2n) && Nat.is_le(rl, 2n) && Nat.is_le(a, 2n) && Nat.is_le(b, 1n) && (Nat.is_eq(ll, 0n) || Nat.is_eq(rl, 0n))

def valid() -> Bool:
  pose_valid(A.pose(0n)) && pose_valid(A.pose(1n)) && pose_valid(A.pose(2n)) && pose_valid(A.pose(3n)) &&
  pose_valid(A.pose(4n)) && pose_valid(A.pose(5n)) && pose_valid(A.pose(6n)) && pose_valid(A.pose(7n)) &&
  Nat.is_lt(Nat.add(A.boot_left(), A.boot_width()), A.boot_right()) &&
  Nat.is_gt(M.eye_width_left(A.eye_pair()), 0n) && Nat.is_gt(M.eye_height_left(A.eye_pair()), 0n)
