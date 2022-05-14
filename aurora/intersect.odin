package aurora

import "core:math"

Hit_Record :: struct {
  object: ^Object,

  point: Vector3,
  normal: Vector3,
  t: f32,
  front_face: bool,
}

make_record :: proc(object: ^Object, ray: Ray, hit_point: Vector3, t: f32, normal: Vector3) -> Hit_Record {
  record := Hit_Record{}
  record.object = object;
  record.t = t
  record.point = hit_point
  record.front_face = dot(ray.direction, normal) < 0.0
  record.normal = record.front_face ? normal : -normal
  return record
}

intersect_scene :: proc(scene: ^Scene, ray: Ray, t_min: f32, t_max: f32) -> (bool, Hit_Record) {
  record := Hit_Record{}
  hit_anything := false
  closest_so_far := t_max

  for object in scene.objects {
    // We need to transform the ray from world space to local space to properly calculate the intersection.
    transformed_ray := ray_transform(ray, object.transform_inverted)
    hit_object, temp_record := intersect_object(object, transformed_ray, t_min, closest_so_far)
    if hit_object {
      hit_anything = true
      closest_so_far = temp_record.t
      record = temp_record
    }
  }

  return hit_anything, record
}

intersect_object :: proc(object: ^Object, ray: Ray, t_min: f32, t_max: f32) -> (bool, Hit_Record) {
  switch o in object.variant {
    case ^Sphere: return intersect_sphere(o, ray, t_min, t_max)
    case: return false, Hit_Record{}
  }
}

intersect_sphere :: proc(sphere: ^Sphere, ray: Ray, t_min: f32, t_max: f32) -> (bool, Hit_Record) {
  oc := ray.origin
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
  outward_normal := hit_point / sphere.radius
  record := make_record(sphere, ray, hit_point, root, outward_normal)
  return true, record
}
