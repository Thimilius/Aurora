package aurora

import "core:math"
import "core:math/rand"
import "core:mem"
import "core:fmt"
import "core:thread"
import "core:time"
import "core:sync"
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

  threads: [dynamic]^thread.Thread,

  scene: ^Scene,
  materials: [dynamic]^Material,
}

@(private="file")
aurora := Aurora{}

aurora_main :: proc() {
  aurora_initialize()

  aurora_raytrace()
  aurora_loop()

  aurora_shutdown()
}

aurora_initialize :: proc() {
  aurora_initialize_window()  
  aurora_initialize_scene()
}

aurora_initialize_window :: proc() {
  sdl.Init(sdl.INIT_VIDEO)

  sdl.CreateWindowAndRenderer(cast(i32)WINDOW_WIDTH, cast(i32)WINDOW_HEIGHT, { .HIDDEN }, &aurora.window, &aurora.renderer)
  sdl.SetWindowTitle(aurora.window, WINDOW_TITLE)

  aurora.texture = sdl.CreateTexture(aurora.renderer, cast(u32)sdl.PixelFormatEnum.RGB24, sdl.TextureAccess.STREAMING, cast(i32)WINDOW_WIDTH, cast(i32)WINDOW_HEIGHT)
  resize(&aurora.pixels, cast(int)(WINDOW_WIDTH * WINDOW_HEIGHT))

  sdl.ShowWindow(aurora.window)
}

aurora_initialize_scene :: proc() {
  aurora.scene = new_scene()
  scene := aurora.scene
  scene.random = rand.create(0) // This is shared between threads!? Works but probably not ideal...

  material_center := new_material_lambert(Color{0.7, 0.3, 0.3})
  append(&aurora.materials, material_center)
  material_ground := new_material_lambert(Color{0.8, 0.8, 0.0})
  append(&aurora.materials, material_ground)
  material_metal := new_material_metal(Color{0.8, 0.8, 0.8}, 0.1)
  append(&aurora.materials, material_metal)

  append(&scene.objects, new_sphere(material_ground, Vector3{0, -100.5, -1}, 100))
  append(&scene.objects, new_sphere(material_metal, Vector3{-1, 0, -1}, 0.5))
  append(&scene.objects, new_sphere(material_center, Vector3{0, 0, -1}, 0.5))
  append(&scene.objects, new_sphere(material_metal, Vector3{1, 0, -1}, 0.5))
}

aurora_raytrace :: proc() {
  t1 := thread.create_and_start_with_poly_data4(u32(0), u32(0), u32(640), u32(360), aurora_raytrace_thread_main)
  t2 := thread.create_and_start_with_poly_data4(u32(640), u32(0), u32(1280), u32(360), aurora_raytrace_thread_main)
  t3 := thread.create_and_start_with_poly_data4(u32(0), u32(360), u32(640), u32(720), aurora_raytrace_thread_main)
  t4 := thread.create_and_start_with_poly_data4(u32(640), u32(360), u32(1280), u32(720), aurora_raytrace_thread_main)

  append(&aurora.threads, t1)
  append(&aurora.threads, t2)
  append(&aurora.threads, t3)
  append(&aurora.threads, t4)
}

aurora_raytrace_thread_main :: proc(x: u32, y: u32, width: u32, height: u32) {
  settings := Raytrace_Settings{}
  settings.rect = Rect{ x, y, width, height }
  settings.full_width = WINDOW_WIDTH
  settings.full_height = WINDOW_HEIGHT
  settings.max_depth = 50
  settings.samples_per_pixel = 12

  raytrace(aurora.scene, &settings)
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
  
  raw_pixels := raw_data(pixels)
  mem.copy(texture_pixels, raw_pixels, (int)(WINDOW_WIDTH * WINDOW_HEIGHT * 3))

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
    
    aurora_copy_to_window(aurora.pixels)
    sdl.RenderPresent(aurora.renderer)
  }
}

aurora_shutdown :: proc() {
  free_scene(aurora.scene)
  for material in aurora.materials {
    free_material(material)
  }

  sdl.DestroyRenderer(aurora.renderer)
  sdl.DestroyWindow(aurora.window)
  sdl.Quit()
}
