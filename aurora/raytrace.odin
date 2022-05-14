package aurora

import "core:fmt"
import "core:math"
import "core:math/rand"

Raytrace_Settings :: struct {
  frame_width: u32,
  frame_height: u32,

  max_depth: u32,

  samples_per_pixel: u32,
}

raytrace :: proc(scene: ^Scene, rect: Rect, settings: ^Raytrace_Settings) {
  aspect_ratio := cast(f32)settings.frame_width / cast(f32)settings.frame_height
  camera := make_camera(Vector3{ 0, 0, 1 }, Vector3{ 0, 0, -1 }, Vector3{ 0, 1, 0 }, 60, aspect_ratio)

  for y in rect.y..<rect.height {
    for x in rect.x..<rect.width {
      pixel := Pixel{x, y}

      color := Color{}
      for s in 0..<settings.samples_per_pixel {
        u := (cast(f32)(x) + rand.float32(&scene.random)) / cast(f32)(settings.frame_width - 1)
        v := (cast(f32)(y) + rand.float32(&scene.random)) / cast(f32)(settings.frame_height - 1)

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
      // We have to remember to transform the scattered ray from local space to world space.
      scattered_ray := ray_transform(scatter_result.scattered_ray, hit_record.object.transform)
      return scatter_result.attenuation * trace_ray(scene, scattered_ray, depth - 1)
    }
    return Color{0, 0, 0}
  }

  d := normalize(ray.direction)
  t := 0.5 * (d.y + 1)
  return color_lerp(Color{1, 1, 1}, Color{0.5, 0.7, 1.0}, t)
}
