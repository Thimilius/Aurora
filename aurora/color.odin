package aurora

Color :: [3]f32
Color24 :: [3]u8

color_to_color24 :: proc(color: Color) -> Color24 {
  r := cast(u8)(color.r * 255)
  g := cast(u8)(color.g * 255)
  b := cast(u8)(color.b * 255)

  return Color24{r, g, b}
}
