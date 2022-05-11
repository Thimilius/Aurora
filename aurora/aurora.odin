package aurora

import "core:math"
import "core:math/rand"
import "core:runtime"
import "core:fmt"
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
  texture: ^sdl.Texture,

  pixels: [dynamic]Color24,
}

@(private="file")
aurora := Aurora{}

aurora_main :: proc() {
  aurora_initialize()

  aurora_raytrace()
  aurora_copy_to_window(aurora.pixels)
  aurora_loop()

  aurora_shutdown()
}

aurora_initialize :: proc() {
  sdl.Init(sdl.INIT_VIDEO)

  sdl.CreateWindowAndRenderer(cast(i32)WINDOW_WIDTH, cast(i32)WINDOW_HEIGHT, { .HIDDEN }, &aurora.window, &aurora.renderer)
  sdl.SetWindowTitle(aurora.window, WINDOW_TITLE)

  aurora.texture = sdl.CreateTexture(aurora.renderer, cast(u32)sdl.PixelFormatEnum.RGB24, sdl.TextureAccess.STREAMING, cast(i32)WINDOW_WIDTH, cast(i32)WINDOW_HEIGHT)
  resize(&aurora.pixels, cast(int)(WINDOW_WIDTH * WINDOW_HEIGHT))

  sdl.ShowWindow(aurora.window)
}

aurora_raytrace :: proc() {
  scene := new_scene()
  defer free_scene(scene)
  scene.random = rand.create(0)

  material_center := new_material_lambert(Color{0.7, 0.3, 0.3})
  defer free_material(material_center)
  material_ground := new_material_lambert(Color{0.8, 0.8, 0.0})
  defer free_material(material_ground)
  material_metal := new_material_metal(Color{0.8, 0.8, 0.8}, 0.1)
  defer free_material(material_metal)

  append(&scene.objects, new_sphere(material_ground, Vector3{0, -100.5, -1}, 100))
  append(&scene.objects, new_sphere(material_metal, Vector3{-1, 0, -1}, 0.5))
  append(&scene.objects, new_sphere(material_center, Vector3{0, 0, -1}, 0.5))
  append(&scene.objects, new_sphere(material_metal, Vector3{1, 0, -1}, 0.5))
  
  settings := Raytrace_Settings{}
  settings.width = WINDOW_WIDTH
  settings.height = WINDOW_HEIGHT
  settings.max_depth = 50
  settings.samples_per_pixel = 12

  raytrace(scene, settings)
}

aurora_set_pixel :: proc(pixel: Pixel, color: Color, samples: u32) {
  scale := 1.0 / cast(f32)samples

  c := Color{}
  c.r = math.sqrt(scale * color.r)
  c.g = math.sqrt(scale * color.g)
  c.b = math.sqrt(scale * color.b)

  color24 := color_to_color24(c)

  aurora.pixels[pixel.x + (pixel.y * WINDOW_WIDTH)] = color24
}

aurora_copy_to_window :: proc(pixels: [dynamic]Color24) {
  texture_pixels: rawptr
  pitch: i32
  sdl.LockTexture(aurora.texture, nil, &texture_pixels, &pitch)
  runtime.mem_copy(texture_pixels, raw_data(pixels), (int)(WINDOW_WIDTH * WINDOW_HEIGHT * 3))
  sdl.UnlockTexture(aurora.texture)
  sdl.RenderCopy(aurora.renderer, aurora.texture, nil, nil)
}

aurora_loop :: proc() {
  sdl.RenderPresent(aurora.renderer)

  event: sdl.Event
  for {
    sdl.PollEvent(&event);
    if event.type == sdl.EventType.QUIT {
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
