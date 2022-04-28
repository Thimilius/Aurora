package aurora

Scene :: struct {
  objects: [dynamic]^Object,
}

new_scene :: proc() -> ^Scene {
  return new(Scene)
}

free_scene :: proc(scene: ^Scene) {
  free(scene)
}
