package aurora

import "core:math/rand"

Scene :: struct {
  objects: [dynamic]^Object,

  random: rand.Rand,
}

new_scene :: proc() -> ^Scene {
  return new(Scene)
}

free_scene_objects :: proc(using scene: ^Scene) {
  for object in objects {
    free(object)
  }
  delete(objects)
}

free_scene :: proc(using scene: ^Scene) {
  free_scene_objects(scene)
  free(scene)
}
