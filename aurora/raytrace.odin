package aurora

import random "core:math/rand"

raytrace :: proc(width: i32, height: i32) {
  rand := random.create(0)

  for x in 0..<width {
    for y in 0..<height {
      pixel := Pixel{x, y}

      r := random.float32(&rand)
      g := random.float32(&rand)
      b := random.float32(&rand)

      color := Color{r, g, b}
      aurora_set_pixel(pixel, color)
    }
  }
}
