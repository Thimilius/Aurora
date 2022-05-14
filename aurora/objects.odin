package aurora

Object :: struct {
  position: Vector3,
  
  transform: Matrix4x4,
  transform_inverted: Matrix4x4,

  material: ^Material,

  variant: union{^Sphere},
}

Sphere :: struct {
  using object: Object,

  radius: f32,
}

new_object :: proc($T: typeid, position: Vector3, material: ^Material) -> ^T {
  o := new(T)
  o.variant = o
  o.position = position
  o.transform = Matrix4x4{
    1, 0, 0, position.x,
    0, 1, 0, position.y,
    0, 0, 1, position.z,
    0, 0, 0, 1,
  }
  o.transform_inverted = inverse(o.transform)
  o.material = material
  return o
}

free_object :: proc(object: ^Object) {
  free(object)
}

new_sphere :: proc(material: ^Material, position: Vector3, radius: f32) -> ^Sphere {
  s := new_object(Sphere, position, material)
  s.radius = radius
  return s
}
