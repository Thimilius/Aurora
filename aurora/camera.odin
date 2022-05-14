package aurora

import "core:math"

Camera :: struct {
  origin: Vector3,
  
  horizontal: Vector3,
  vertical: Vector3,

  upper_left_corner: Vector3,
}

make_camera :: proc(look_from, look_at, up: Vector3, vertical_fov: f32, aspect_ratio: f32) -> Camera {
  theta := math.to_radians(vertical_fov)
  h := math.tan(theta / 2)
  viewport_height := 2.0 * h
  viewport_width := aspect_ratio * viewport_height

  w := normalize(look_from - look_at)
  u := normalize(cross(up, w))
  v := cross(w, u)

  camera := Camera{}
  camera.origin = look_from
  camera.horizontal = viewport_width * u
  camera.vertical = viewport_height * v
  camera.upper_left_corner = camera.origin - camera.horizontal / 2 + camera.vertical / 2 - w

  return camera
}

camera_get_ray :: proc(using camera: ^Camera, u: f32, v: f32) -> Ray {
  return make_ray(origin, upper_left_corner + u * horizontal - v * vertical - origin)
}
