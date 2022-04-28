package aurora

import sdl "vendor:sdl2"

@(private="file")
WINDOW_WIDTH  : i32 : 1280
@(private="file")
WINDOW_HEIGHT : i32 : 720
@(private="file")
WINDOW_TITLE :: "Aurora"

@(private="file")
Aurora :: struct {
  window: ^sdl.Window,
  renderer: ^sdl.Renderer,
}

@(private="file")
aurora := Aurora{}

aurora_main :: proc() {
  aurora_initialize()

  scene := new_scene()
  append(&scene.objects, new_sphere(Vector3{0, 0, -1}, 0.5))
  append(&scene.objects, new_sphere(Vector3{0, -100.5, -1}, 100))
  raytrace(scene, WINDOW_WIDTH, WINDOW_HEIGHT)
  free_scene(scene)

  aurora_loop()
  aurora_shutdown()
}

aurora_initialize :: proc() {
  sdl.Init(sdl.INIT_VIDEO)

  sdl.CreateWindowAndRenderer(WINDOW_WIDTH, WINDOW_HEIGHT, { .HIDDEN }, &aurora.window, &aurora.renderer)
  sdl.SetWindowTitle(aurora.window, WINDOW_TITLE)
}

aurora_set_pixel :: proc(pixel: Pixel, color: Color) {
  color24 := color_to_color24(color)
  sdl.SetRenderDrawColor(aurora.renderer, color24.r, color24.g, color24.b, 255)
  sdl.RenderDrawPoint(aurora.renderer, pixel.x, pixel.y)
}

aurora_loop :: proc() {
  sdl.RenderPresent(aurora.renderer)
  sdl.ShowWindow(aurora.window)
  event: sdl.Event
  for {
    sdl.PollEvent(&event);
    if (event.type == sdl.EventType.QUIT) {
      break
    }
    
    sdl.RenderPresent(aurora.renderer)
  }
}

aurora_shutdown :: proc() {
  sdl.DestroyRenderer(aurora.renderer)
  sdl.DestroyWindow(aurora.window)
  sdl.Quit()
}
