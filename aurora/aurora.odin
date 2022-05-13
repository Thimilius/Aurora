package aurora

import "core:math"
import "core:math/rand"
import "core:mem"
import "core:fmt"
import "core:thread"
import "core:time"
import "core:sync"
import "core:os"
import "core:log"
import "core:container/queue"
import sdl "vendor:sdl2"

when os.OS == .Windows {
  import "core:sys/windows"
}

WINDOW_WIDTH : u32 : 1280
WINDOW_HEIGHT : u32 : 720
WINDOW_TITLE :: "Aurora"
TILE_SIZE :: 80
TILE_PRIORITY :: Tile_Priority.Spiral

Tile_Priority :: enum {
  Linear,
  Spiral,
}

Aurora :: struct {
  window: ^sdl.Window,
  renderer: ^sdl.Renderer,
  texture: ^sdl.Texture,

  settings: Raytrace_Settings,  
  pixels: [dynamic]Color24,
  tile_queue: queue.Queue(Rect),
  tile_mutex: sync.Mutex,

  threads: [dynamic]^thread.Thread,
  timer: time.Stopwatch,

  scene: ^Scene,
  materials: [dynamic]^Material,
}

@(private="file")
aurora := Aurora{}

aurora_main :: proc() {
  context.logger = log.create_multi_logger(log.create_console_logger(opt = (log.Options{ .Level, .Terminal_Color } | log.Full_Timestamp_Opts)))
  defer {
    logger_data := cast(^log.Multi_Logger_Data)context.logger.data
    for logger in logger_data.loggers {
      l := logger
      log.destroy_console_logger(&l)
    }
    logger := context.logger
    log.destroy_multi_logger(&logger)
  }

  aurora_initialize()

  aurora_raytrace()
  aurora_loop()

  aurora_shutdown()
}

aurora_initialize :: proc() {
  aurora_initialize_window()  
  aurora_initialize_raytracer()
  aurora_initialize_scene()
}

aurora_initialize_window :: proc() {
  sdl.Init(sdl.INIT_VIDEO)
  sdl.CreateWindowAndRenderer(auto_cast WINDOW_WIDTH, auto_cast WINDOW_HEIGHT, { .HIDDEN }, &aurora.window, &aurora.renderer)
  sdl.SetWindowTitle(aurora.window, WINDOW_TITLE)
}

aurora_initialize_raytracer :: proc() {
  assert(WINDOW_WIDTH % TILE_SIZE == 0)
  assert(WINDOW_HEIGHT % TILE_SIZE == 0)

  aurora.settings.frame_width = WINDOW_WIDTH
  aurora.settings.frame_height = WINDOW_HEIGHT
  aurora.settings.max_depth = 32
  aurora.settings.samples_per_pixel = 12

  aurora.texture = sdl.CreateTexture(aurora.renderer, auto_cast sdl.PixelFormatEnum.RGB24, sdl.TextureAccess.STREAMING, auto_cast WINDOW_WIDTH, auto_cast WINDOW_HEIGHT)
  resize(&aurora.pixels, auto_cast(WINDOW_WIDTH * WINDOW_HEIGHT))

  tile_count_x := WINDOW_WIDTH / TILE_SIZE
  tile_count_y := WINDOW_HEIGHT / TILE_SIZE
  queue.reserve(&aurora.tile_queue, auto_cast (tile_count_x * tile_count_y))

  rects: [dynamic]Rect
  defer delete(rects)

  for tile_y in 0..<tile_count_y {
    for tile_x in 0..<tile_count_x {
      x := tile_x * TILE_SIZE
      y := tile_y * TILE_SIZE
      width := x + TILE_SIZE
      height := y + TILE_SIZE

      rect := Rect{ x, y, width, height }
      append(&rects, rect)
    } 
  }
  
  spiral :: proc(X: int, Y: int, rects: []Rect) {
    // Taken from: https://stackoverflow.com/a/1555236
    x, y, dx, dy: int
    dy = -1
    t := max(X, Y)
    maxI := t * t
    for i in 0..<maxI {
      if ((-X / 2 <= x) && (x <= X / 2) && (-Y / 2 <= y) && (y <= Y / 2)) {
        actual_x := x + (X / 2)
        actual_x = X % 2 == 0 ? actual_x - 1 : actual_x
        actual_y := y + (Y / 2)
        actual_y = Y % 2 == 0 ? actual_y - 1 : actual_y

        rect := rects[actual_x + (actual_y * X)]
        queue.push(&aurora.tile_queue, rect)
      }
      if ((x == y) || ((x < 0) && (x == -y)) || ((x > 0) && (x == 1-y))) {
            t = dx
            dx = -dy
            dy = t
        }
        x += dx
        y += dy
    }
  }

  switch TILE_PRIORITY {
    case .Spiral: spiral(auto_cast tile_count_x, auto_cast tile_count_y, rects[:])
    case .Linear: fallthrough
    case:
      for rect in rects {
        queue.push(&aurora.tile_queue, rect)
      }
  }

  log.infof(
    "Initialized raytracer - Frame: %vx%v - Tiles: %vx%v - Max depth: %v - Samples: %v.",
    WINDOW_WIDTH,
    WINDOW_HEIGHT,
    tile_count_x,
    tile_count_y,
    aurora.settings.max_depth,
    aurora.settings.samples_per_pixel,
  )
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
  thread_count := aurora_get_thread_count()
  for i in 0..thread_count {
    thread := thread.create_and_start(aurora_raytrace_thread_main)
    append(&aurora.threads, thread)
  }

  log.infof("Starting raytracing using %v threads.", thread_count)
  time.stopwatch_start(&aurora.timer)
}

aurora_get_thread_count :: proc() -> int {
  result := 8

  when os.OS == .Windows {
    system_info: windows.SYSTEM_INFO 
    windows.GetSystemInfo(&system_info)
    if system_info.dwNumberOfProcessors > 0 {
      result = auto_cast system_info.dwNumberOfProcessors
    }
  }

  return result
}

aurora_raytrace_thread_main :: proc(_: ^thread.Thread) {
  for {
    sync.mutex_lock(&aurora.tile_mutex)
    rect, ok := queue.pop_front_safe(&aurora.tile_queue)
    sync.mutex_unlock(&aurora.tile_mutex)
    if !ok {
      return
    }

    raytrace(aurora.scene, rect, &aurora.settings)
  }
}

aurora_set_pixel :: proc(pixel: Pixel, color: Color, samples: u32) {
  scale := 1.0 / cast(f32) samples

  c := Color{}
  c.r = math.sqrt(scale * color.r)
  c.g = math.sqrt(scale * color.g)
  c.b = math.sqrt(scale * color.b)

  color24 := color_to_color24(c)

  aurora.pixels[pixel.x + (pixel.y * WINDOW_WIDTH)] = color24
}

aurora_copy_to_window :: proc(pixels: []Color24) {
  texture_pixels: rawptr
  pitch: i32
  sdl.LockTexture(aurora.texture, nil, &texture_pixels, &pitch)
  
  raw_pixels := raw_data(pixels)
  mem.copy(texture_pixels, raw_pixels, len(pixels) * size_of(pixels[0]))

  sdl.UnlockTexture(aurora.texture)
  sdl.RenderCopy(aurora.renderer, aurora.texture, nil, nil)
}

aurora_loop :: proc() {
  sdl.ShowWindow(aurora.window)

  had_raytracing_finish := false
  event: sdl.Event
  for {
    sdl.PollEvent(&event);
    if event.type == .QUIT {
      break
    } else if event.type == .KEYDOWN {
      keysym := event.key.keysym
      is_w := keysym.scancode == .W
      has_mod := .LCTRL in keysym.mod || .RCTRL in keysym.mod
      if is_w && has_mod {
        break
      }
    }

    raytracing_finished := true
    for t in aurora.threads {
      if !thread.is_done(t) {
        raytracing_finished = false
        break
      }
    }
    if raytracing_finished && !had_raytracing_finish {
      had_raytracing_finish = true

      time.stopwatch_stop(&aurora.timer)
      duration := time.stopwatch_duration(aurora.timer)
      seconds := time.duration_seconds(duration)

      log.infof("Finished raytracing in %v seconds.", seconds)
    }

    aurora_copy_to_window(aurora.pixels[:])
    sdl.RenderPresent(aurora.renderer)
  }
}

aurora_shutdown :: proc() {
  for t in aurora.threads {
    thread.terminate(t, 0)
    thread.destroy(t)
  }

  free_scene(aurora.scene)
  for material in aurora.materials {
    free_material(material)
  }

  sdl.DestroyRenderer(aurora.renderer)
  sdl.DestroyWindow(aurora.window)
  sdl.Quit()
}
