package aurora

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

intersect :: proc(ray: Ray, object: ^Object) -> bool {
  switch o in object.variant {
    case ^Sphere: return intersect_sphere(ray, o)
    case: return false
  }
}

intersect_sphere :: proc(ray: Ray, sphere: ^Sphere) -> bool {
  oc := ray.origin - sphere.center
  a := dot(ray.direction, ray.direction)
  b := 2.0 * dot(oc, ray.direction)
  c := dot(oc, oc) - sphere.radius * sphere.radius
  discriminant := b * b - 4 * a * c
  return discriminant > 0
}
