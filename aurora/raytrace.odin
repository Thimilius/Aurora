package aurora

import "core:fmt"
import "core:math"
import "core:math/rand"

Raytrace_Settings :: struct {
  rect: Rect,

  full_width: u32,
  full_height: u32,

  max_depth: u32,

  samples_per_pixel: u32,
}

raytrace :: proc(scene: ^Scene, settings: ^Raytrace_Settings) {
  rect := settings.rect
  camera := make_camera(rect.width, rect.height)

  for y in rect.x..<rect.height {
    for x in rect.y..<rect.width {
      pixel := Pixel{x, y}

      color := Color{}
      for s in 0..<settings.samples_per_pixel {
        u := (cast(f32)(x) + rand.float32(&scene.random)) / cast(f32)(settings.full_width - 1)
        v := (cast(f32)(y) + rand.float32(&scene.random)) / cast(f32)(settings.full_height - 1)

        ray := camera_get_ray(&camera, u, v)
        color += trace_ray(scene, ray, settings.max_depth)
      }
      aurora_set_pixel(pixel, color, settings.samples_per_pixel)
    }
  }
}

trace_ray :: proc(scene: ^Scene, ray: Ray, depth: u32) -> Color {
  if depth <= 0 {
    return Color{0, 0, 0}
  }

  is_hit, hit_record := intersect_scene(scene, ray, 0.0001, math.F32_MAX)
  if is_hit {
    scatter_result := material_scatter(hit_record.object.material, &scene.random, ray, &hit_record)
    if scatter_result.scattered {
      return scatter_result.attenuation * trace_ray(scene, scatter_result.scattered_ray, depth - 1)
    }
    return Color{0, 0, 0}
  }

  d := normalize(ray.direction)
  t := 0.5 * (d.y + 1)
  return color_lerp(Color{1, 1, 1}, Color{0.5, 0.7, 1.0}, t)
}
