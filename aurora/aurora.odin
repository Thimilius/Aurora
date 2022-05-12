package aurora

import "core:math"
import "core:math/rand"
import "core:mem"
import "core:fmt"
import "core:thread"
import "core:time"
import "core:sync"
import "core:container/queue"
import sdl "vendor:sdl2"

@(private="file")
WINDOW_WIDTH  : u32 : 1280
@(private="file")
WINDOW_HEIGHT : u32 : 720
@(private="file")
WINDOW_TITLE :: "Aurora"
@(private="file")
BLOCK_SIZE :: 80

@(private="file")
Aurora :: struct {
  window: ^sdl.Window,
  renderer: ^sdl.Renderer,
  texture: ^sdl.Texture,
  
  pixels: [dynamic]Color24,
  blocks: queue.Queue(Rect),
  block_mutex: sync.Mutex,

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
  aurora_initialize_blocks()
  aurora_initialize_scene()
}

aurora_initialize_window :: proc() {
  sdl.Init(sdl.INIT_VIDEO)
  sdl.CreateWindowAndRenderer(cast(i32)WINDOW_WIDTH, cast(i32)WINDOW_HEIGHT, { .HIDDEN }, &aurora.window, &aurora.renderer)
  sdl.SetWindowTitle(aurora.window, WINDOW_TITLE)
}

aurora_initialize_blocks :: proc() {
  assert(WINDOW_WIDTH % BLOCK_SIZE == 0)
  assert(WINDOW_HEIGHT % BLOCK_SIZE == 0)

  aurora.texture = sdl.CreateTexture(aurora.renderer, cast(u32)sdl.PixelFormatEnum.RGB24, sdl.TextureAccess.STREAMING, cast(i32)WINDOW_WIDTH, cast(i32)WINDOW_HEIGHT)
  resize(&aurora.pixels, cast(int)(WINDOW_WIDTH * WINDOW_HEIGHT))

  block_count_x := WINDOW_WIDTH / BLOCK_SIZE
  block_count_y := WINDOW_HEIGHT / BLOCK_SIZE
  for block_y in 0..<block_count_y {
    for block_x in 0..<block_count_x {
      x := block_x * BLOCK_SIZE
      y := block_y * BLOCK_SIZE
      width := x + BLOCK_SIZE
      height := y + BLOCK_SIZE
      rect := Rect{ x, y, width, height }
      queue.push(&aurora.blocks, rect)
    } 
  }
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
  t1 := thread.create_and_start(aurora_raytrace_thread_main)
  t2 := thread.create_and_start(aurora_raytrace_thread_main)
  t3 := thread.create_and_start(aurora_raytrace_thread_main)
  t4 := thread.create_and_start(aurora_raytrace_thread_main)

  append(&aurora.threads, t1)
  append(&aurora.threads, t2)
  append(&aurora.threads, t3)
  append(&aurora.threads, t4)
}

aurora_raytrace_thread_main :: proc(_: ^thread.Thread) {
  for {
    sync.mutex_lock(&aurora.block_mutex)
    rect, ok := queue.pop_front_safe(&aurora.blocks)
    sync.mutex_unlock(&aurora.block_mutex)
    if !ok {
      return
    }

    settings := Raytrace_Settings{}
    settings.rect = rect
    settings.full_width = WINDOW_WIDTH
    settings.full_height = WINDOW_HEIGHT
    settings.max_depth = 50
    settings.samples_per_pixel = 12

    raytrace(aurora.scene, &settings)
  }
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
  sdl.ShowWindow(aurora.window)

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
  delete(aurora.pixels)
  delete(aurora.threads)
  free_scene(aurora.scene)
  for material in aurora.materials {
    free_material(material)
  }
  delete(aurora.materials)

  sdl.DestroyRenderer(aurora.renderer)
  sdl.DestroyWindow(aurora.window)
  sdl.Quit()
}
