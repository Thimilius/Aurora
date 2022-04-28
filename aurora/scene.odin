package aurora

Scene :: struct {
  objects: [dynamic]^Object,
}

new_scene :: proc() -> ^Scene {
  return new(Scene)
}

free_scene_objects :: proc(scene: ^Scene) {
  for object in scene.objects {
    free(object)
  }
  clear(&scene.objects)
}

free_scene :: proc(scene: ^Scene) {
  free_scene_objects(scene)
  free(scene)
}

intersect_scene :: proc(scene: ^Scene, ray: Ray, t_min: f32, t_max: f32) -> (bool, Hit_Record) {
  record := Hit_Record{}
  hit_anything := false
  closest_so_far := t_max

  for object in scene.objects {
    hit_object, temp_record := intersect_object(object, ray, t_min, closest_so_far)
    if hit_object {
      hit_anything = true
      closest_so_far = temp_record.t
      record = temp_record
    }
  }

  return hit_anything, record
}
