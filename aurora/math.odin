package aurora

import "core:math"

Vector2 :: [2]f32
Pixel :: [2]i32

Vector3 :: [3]f32

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

cross :: proc(a, b: Vector3) -> Vector3 {
	i := a.yzx * b.zxy
	j := a.zxy * b.yzx
	return i - j
}

Ray :: struct {
  origin: Vector3,
  direction: Vector3,
}

ray :: proc(origin: Vector3, direction: Vector3) -> Ray {
  return Ray{origin, direction}
}

ray_at :: proc(ray: Ray, t: f32) -> Vector3 {
  return ray.origin + t * ray.direction
}
