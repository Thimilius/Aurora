package aurora

import "core:fmt"
import random "core:math/rand"

sphere: ^Sphere

raytrace :: proc(width: i32, height: i32) {
  rand := random.create(0)

  aspect_ratio := cast(f32)width / cast(f32)height
  viewport_height : f32 = 2.0
  viewport_width : f32 = aspect_ratio * viewport_height
  focal_length : f32 = 1.0

  origin := Vector3{0, 0, 0}
  horizontal := Vector3{viewport_width, 0, 0}
  vertical := Vector3{0, viewport_height, 0}
  upper_left_corner := origin + horizontal / 2 + vertical / 2 - Vector3{0, 0, focal_length}

  sphere = new_sphere(Vector3{0, 0, -1}, 0.5)

  for y in 0..<height {
    for x in 0..<width {
      pixel := Pixel{x, y}

      u := cast(f32)(x) / cast(f32)(width)
      v := cast(f32)(y) / cast(f32)(height)

      ray := ray(origin, upper_left_corner - u * horizontal - v * vertical - origin)
      color := trace(ray)
      aurora_set_pixel(pixel, color)
    }
  }
}

trace :: proc(ray: Ray) -> Color {
  hit := intersect(ray, sphere)
  if (hit > 0) {
    n := normalize(ray_at(ray, hit) - Vector3{0, 0, -1})
    return 0.5 * Color{n.x + 1, n.y + 1, n.z + 1}
  }

  d := normalize(ray.direction)
  t := 0.5 * (d.y + 1)
  return color_lerp(Color{1, 1, 1}, Color{0.5, 0.7, 1.0}, t)
}
