package aurora

import "core:fmt"
import "core:math"
import "core:math/rand"

raytrace :: proc(scene: ^Scene, width: i32, height: i32) {
  rand := rand.create(0)

  camera := make_camera(width, height)

  for y in 0..<height {
    for x in 0..<width {
      pixel := Pixel{x, y}

      u := cast(f32)(x) / cast(f32)(width - 1)
      v := cast(f32)(y) / cast(f32)(height - 1)

      ray := camera_get_ray(&camera, u, v)
      color := trace(scene, ray)
      aurora_set_pixel(pixel, color)
    }
  }
}

trace :: proc(scene: ^Scene, ray: Ray) -> Color {
  is_hit, hit_record := intersect_scene(scene, ray, 0, math.F32_MAX)

  if (hit_record.t > 0) {
    return 0.5 * (hit_record.normal + Color{1, 1, 1})
  }

  d := normalize(ray.direction)
  t := 0.5 * (d.y + 1)
  return color_lerp(Color{1, 1, 1}, Color{0.5, 0.7, 1.0}, t)
}
