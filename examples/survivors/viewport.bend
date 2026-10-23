import Base

# Native presentation uses a fixed square Image. App maps it into a
# power-of-two pixel square; a nonsquare window crops part of that image.
# The full 512-square raster is a conservative bound for every visible crop.
def native_scale() -> F32: 0.65
def native_center_x() -> F32: 256.0
def native_center_y() -> F32: 210.0
def native_image_extent() -> F32: 512.0
def native_x(x: F32,px: F32) -> F32: ((x - px) * native_scale() + native_center_x() : F32)
def native_y(y: F32,py: F32) -> F32: ((y - py) * native_scale() + native_center_y() : F32)
# Browser landscape width <=1024 and height <=1024; portrait height640.
# This player-centered square also encloses the asymmetric native camera.
def exclusion_half_extent() -> F32: 512.0
