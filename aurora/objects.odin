package aurora

import "core:math"

Object :: struct {
  variant: union{^Sphere},
}

Sphere :: struct {
  using object: Object,

  center: Vector3,
  radius: f32,
}

new_object :: proc($T: typeid) -> ^T {
  o := new(T)
  o.variant = o
  return o
}

free_object :: proc(object: ^Object) {
  free(object)
}

new_sphere :: proc(center: Vector3, radius: f32) -> ^Sphere {
  s := new_object(Sphere)
  s.center = center
  s.radius = radius
  return s
}

intersect :: proc(ray: Ray, object: ^Object) -> f32 {
  switch o in object.variant {
    case ^Sphere: return intersect_sphere(ray, o)
    case: return 0.0
  }
}

intersect_sphere :: proc(ray: Ray, sphere: ^Sphere) -> f32 {
  oc := ray.origin - sphere.center
  a := length_squared(ray.direction)
  half_b := dot(oc, ray.direction)
  c := length_squared(oc) - sphere.radius * sphere.radius
  discriminant := half_b * half_b - a * c

  if discriminant < 0.0 {
    return -1.0
  } else {
    return (-half_b - math.sqrt(discriminant)) / a
  }
}
