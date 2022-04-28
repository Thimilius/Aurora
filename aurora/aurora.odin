package aurora

import "core:math"
import "core:math/rand"
import sdl "vendor:sdl2"

@(private="file")
WINDOW_WIDTH  : u32 : 1280
@(private="file")
WINDOW_HEIGHT : u32 : 720
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
  scene.random = rand.create(0)
  append(&scene.objects, new_sphere(Vector3{0, 0, -1}, 0.5))
  append(&scene.objects, new_sphere(Vector3{0, -100.5, -1}, 100))
  
  settings := Raytrace_Settings{}
  settings.width = WINDOW_WIDTH
  settings.height = WINDOW_HEIGHT
  settings.max_depth = 50
  settings.samples_per_pixel = 12

  raytrace(scene, settings)

  free_scene(scene)

  aurora_loop()
  aurora_shutdown()
}

aurora_initialize :: proc() {
  sdl.Init(sdl.INIT_VIDEO)

  sdl.CreateWindowAndRenderer(cast(i32)WINDOW_WIDTH, cast(i32)WINDOW_HEIGHT, { .HIDDEN }, &aurora.window, &aurora.renderer)
  sdl.SetWindowTitle(aurora.window, WINDOW_TITLE)
  sdl.ShowWindow(aurora.window)
}

aurora_set_pixel :: proc(pixel: Pixel, color: Color, samples: u32) {
  scale := 1.0 / cast(f32)samples

  c := Color{}
  c.r = math.sqrt(scale * color.r)
  c.g = math.sqrt(scale * color.g)
  c.b = math.sqrt(scale * color.b)

  color24 := color_to_color24(c)

  sdl.SetRenderDrawColor(aurora.renderer, color24.r, color24.g, color24.b, 255)
  sdl.RenderDrawPoint(aurora.renderer, cast(i32)pixel.x, cast(i32)pixel.y)
}

aurora_loop :: proc() {
  sdl.RenderPresent(aurora.renderer)
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
