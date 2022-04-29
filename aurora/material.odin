package aurora

import "core:math/rand"

Material :: struct {
  variant: union{^Material_Lambert, ^Material_Metal},
}

new_material :: proc($T: typeid) -> ^T {
  m := new(T)
  m.variant = m
  return m
}

free_material :: proc(material: ^Material) {
  free(material)
}

Material_Lambert :: struct {
  using material: Material,

  albedo: Color,
}

new_material_lambert :: proc(albedo: Color) -> ^Material_Lambert {
  m := new_material(Material_Lambert)
  m.albedo = albedo
  return m
}

Material_Metal :: struct {
  using material: Material,

  albedo: Color,
  fuzz: f32,
}

new_material_metal :: proc(albedo: Color, fuzz: f32) -> ^Material_Metal {
  m := new_material(Material_Metal)
  m.albedo = albedo
  m.fuzz = fuzz < 1.0 ? fuzz : 1.0
  return m
}

Material_Scatter_Result :: struct {
  scattered: bool,
  scattered_ray: Ray,

  attenuation: Color,
}

material_scatter :: proc(material: ^Material, random: ^rand.Rand, ray: Ray, record: ^Hit_Record) -> Material_Scatter_Result {
  switch m in material.variant {
    case ^Material_Lambert: return material_scatter_lambert(m, random, ray, record)
    case ^Material_Metal: return material_scatter_metal(m, random, ray, record)
    case: return Material_Scatter_Result{}
  }
}

material_scatter_lambert :: proc(material: ^Material_Lambert, random: ^rand.Rand, ray: Ray, record: ^Hit_Record) -> Material_Scatter_Result {
  scatter_direction := record.normal + random_unit_vector(random)
  if is_near_zero(scatter_direction) {
    scatter_direction = record.normal
  }

  result := Material_Scatter_Result{}
  result.scattered = true
  result.scattered_ray = make_ray(record.point, scatter_direction)
  result.attenuation = material.albedo

  return result
}

material_scatter_metal :: proc(material: ^Material_Metal, random: ^rand.Rand, ray: Ray, record: ^Hit_Record) -> Material_Scatter_Result {
  reflected := reflect(normalize(ray.direction), record.normal)

  result := Material_Scatter_Result{}
  result.scattered_ray = make_ray(record.point, reflected + material.fuzz * random_in_unit_sphere(random))
  result.scattered = dot(result.scattered_ray.direction, record.normal) > 0.0
  result.attenuation = material.albedo

  return result
}
