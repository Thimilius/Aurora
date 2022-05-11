package aurora

import "core:math"
import "core:math/rand"

fabs :: proc(f: f32) -> f32 {
  return f > 0.0 ? f : -f
}

Vector2 :: [2]f32
Pixel :: [2]u32

Vector3 :: [3]f32

Rect :: struct {
  x: u32,
  y: u32,
  width: u32,
  height: u32,
}

length :: proc(v: Vector3) -> f32 {
  return math.sqrt(length_squared(v))
}

length_squared :: proc(v: Vector3) -> f32 {
  return v.x * v.x + v.y * v.y + v.z * v.z
}

normalize :: proc(v: Vector3) -> Vector3 {
  l := length(v)
  if l == 0 {
    return Vector3{}
  } else {
    return v / l
  }
}

dot :: proc(a, b: Vector3) -> f32 {
  return a.x * b.x + a.y * b.y + a.z * b.z
}

cross :: proc(a, b: Vector3) -> Vector3 {
	i := a.yzx * b.zxy
	j := a.zxy * b.yzx
	return i - j
}

reflect :: proc(v, n: Vector3) -> Vector3 {
  return v - 2 * dot(v, n) * n
}

is_near_zero :: proc(v: Vector3) -> bool {
  return (fabs(v[0]) < math.F32_EPSILON) && (fabs(v[1]) < math.F32_EPSILON) && (fabs(v[1]) < math.F32_EPSILON)
}

random_in_unit_sphere :: proc(random: ^rand.Rand) -> Vector3 {
  for {
    x := rand.float32_range(-1, 1, random)
    y := rand.float32_range(-1, 1, random)
    z := rand.float32_range(-1, 1, random)

    p := Vector3{x, y, z}
    if length_squared(p) >= 1 {
      continue
    }
    return p
  }
}

random_unit_vector :: proc(random: ^rand.Rand) -> Vector3 {
  return normalize(random_in_unit_sphere(random))
}

random_in_hemisphere :: proc(random: ^rand.Rand, normal: Vector3) -> Vector3 {
  in_unit_sphere := random_in_unit_sphere(random)
  if dot(in_unit_sphere, normal) > 0.0 {
    return in_unit_sphere
  } else {
    return -in_unit_sphere
  }
}

Ray :: struct {
  origin: Vector3,
  direction: Vector3,
}

make_ray :: proc(origin: Vector3, direction: Vector3) -> Ray {
  return Ray{origin, direction}
}

ray_at :: proc(using ray: Ray, t: f32) -> Vector3 {
  return origin + t * direction
}
