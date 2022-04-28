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
