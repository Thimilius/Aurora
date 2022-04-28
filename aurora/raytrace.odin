package aurora

import "core:fmt"
import "core:math"
import "core:math/rand"

Raytrace_Settings :: struct {
  width: u32,
  height: u32,

  samples_per_pixel: u32,
}

raytrace :: proc(scene: ^Scene, settings: Raytrace_Settings) {
  random := rand.create(0)

  camera := make_camera(settings.width, settings.height)

  for y in 0..<settings.height {
    for x in 0..<settings.width {
      pixel := Pixel{x, y}

      color := Color{}
      for s in 0..<settings.samples_per_pixel {
        u := (cast(f32)(x) + rand.float32(&random)) / cast(f32)(settings.width - 1)
        v := (cast(f32)(y) + rand.float32(&random)) / cast(f32)(settings.height - 1)

        ray := camera_get_ray(&camera, u, v)
        color += trace(scene, ray)
      }
      aurora_set_pixel(pixel, color, settings.samples_per_pixel)
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
