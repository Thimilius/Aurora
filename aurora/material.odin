package aurora

import "core:math/rand"

Material :: struct {
  variant: union{^Material_Lambert},
}

Material_Lambert :: struct {
  using material: Material,

  albedo: Color,
}

new_material :: proc($T: typeid) -> ^T {
  m := new(T)
  m.variant = m
  return m
}

free_material :: proc(material: ^Material) {
  free(material)
}

new_material_lambert :: proc(albedo: Color) -> ^Material_Lambert {
  m := new_material(Material_Lambert)
  m.albedo = albedo
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
    case: return Material_Scatter_Result{}
  }
}

material_scatter_lambert :: proc(material: ^Material_Lambert, random: ^rand.Rand, ray: Ray, record: ^Hit_Record) -> Material_Scatter_Result {
  scatter_direction := record.normal + random_unit_vector(random)

  result := Material_Scatter_Result{}
  result.scattered = true
  result.scattered_ray = make_ray(record.point, scatter_direction)
  result.attenuation = material.albedo

  return result
}
