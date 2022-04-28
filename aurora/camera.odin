package aurora

Camera :: struct {
  origin: Vector3,
  
  horizontal: Vector3,
  vertical: Vector3,

  upper_left_corner: Vector3,
}

make_camera :: proc(width: u32, height: u32) -> Camera {
  aspect_ratio := cast(f32)width / cast(f32)height
  viewport_height : f32 = 2.0
  viewport_width : f32 = aspect_ratio * viewport_height
  focal_length : f32 = 1.0

  camera := Camera{}
  camera.origin = Vector3{0, 0, 0}
  camera.horizontal = Vector3{viewport_width, 0, 0}
  camera.vertical = Vector3{0, viewport_height, 0}
  camera.upper_left_corner = camera.origin - camera.horizontal / 2 + camera.vertical / 2 - Vector3{0, 0, focal_length}

  return camera
}

camera_get_ray :: proc(using camera: ^Camera, u: f32, v: f32) -> Ray {
  return make_ray(origin, upper_left_corner + u * horizontal - v * vertical - origin)
}
