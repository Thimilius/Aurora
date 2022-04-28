package aurora

import "core:math"

Hit_Record :: struct {
  point: Vector3,
  normal: Vector3,
  t: f32,
  front_face: bool,
}

make_record :: proc(ray: Ray, hit_point: Vector3, t: f32, normal: Vector3) -> Hit_Record {
  record := Hit_Record{}
  record.t = t
  record.point = hit_point
  record.front_face = dot(ray.direction, normal) < 0.0
  record.normal = record.front_face ? normal : -normal
  return record
}

intersect_object :: proc(object: ^Object, ray: Ray, t_min: f32, t_max: f32) -> (bool, Hit_Record) {
  switch o in object.variant {
    case ^Sphere: return intersect_sphere(o, ray, t_min, t_max)
    case: return false, Hit_Record{}
  }
}

intersect_sphere :: proc(sphere: ^Sphere, ray: Ray, t_min: f32, t_max: f32) -> (bool, Hit_Record) {
  oc := ray.origin - sphere.center
  a := length_squared(ray.direction)
  half_b := dot(oc, ray.direction)
  c := length_squared(oc) - sphere.radius * sphere.radius
  
  discriminant := half_b * half_b - a * c
  if discriminant < 0.0 {
    return false, Hit_Record{}
  }
  sqrtd := math.sqrt(discriminant)
  
  root := (-half_b - sqrtd) / a
  if (root < t_min || t_max < root) {
    root = (-half_b + sqrtd) / a
    if (root < t_min || t_max < root) {
      return false, Hit_Record{}
    }
  }

  hit_point := ray_at(ray, root)
  outward_normal := (hit_point - sphere.center) / sphere.radius
  record := make_record(ray, hit_point, root, outward_normal)
  return true, record
}
