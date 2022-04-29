package aurora

Object :: struct {
  material: ^Material,

  variant: union{^Sphere},
}

Sphere :: struct {
  using object: Object,

  center: Vector3,
  radius: f32,
}

new_object :: proc($T: typeid, material: ^Material) -> ^T {
  o := new(T)
  o.variant = o
  o.material = material
  return o
}

free_object :: proc(object: ^Object) {
  free(object)
}

new_sphere :: proc(material: ^Material, center: Vector3, radius: f32) -> ^Sphere {
  s := new_object(Sphere, material)
  s.center = center
  s.radius = radius
  return s
}
