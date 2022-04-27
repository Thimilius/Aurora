package aurora

import "core:fmt"
import sdl "vendor:sdl2"

aurora_main :: proc() {
  sdl.Init(sdl.INIT_VIDEO)

  window_width : i32 : 1280
  window_height : i32 : 720

  window: ^sdl.Window
  renderer: ^sdl.Renderer
  sdl.CreateWindowAndRenderer(window_width, window_height, { .HIDDEN }, &window, &renderer)

  sdl.SetRenderDrawColor(renderer, 0, 255, 255, 255)
  for x in 0..<window_width {
    for y in 0..<window_height {
      sdl.RenderDrawPoint(renderer, x, y)
    }
  }
  sdl.RenderPresent(renderer)

  sdl.ShowWindow(window)
  event: sdl.Event
  for {
    sdl.PollEvent(&event);
    if (event.type == sdl.EventType.QUIT) {
      break
    }
    
    sdl.RenderPresent(renderer)
  }  

  sdl.DestroyRenderer(renderer)
  sdl.DestroyWindow(window)
  sdl.Quit()
}