import Base
import ./model.bend as M
import ./LAWS.bend as Laws

def Laws.eye_widths_equal(pair):
  M.EyePair{left, right, width, height} = pair
  {==}

def Laws.eye_heights_equal(pair):
  M.EyePair{left, right, width, height} = pair
  {==}

def Laws.limb_joint_shared(limb):
  M.Limb{root, knee, tip} = limb
  {==}

def Laws.eyes_preserve_width(left, right, width, height):
  {==}

def Laws.eyes_preserve_height(left, right, width, height):
  {==}

def Laws.origin_rect_serialization():
  {==}
