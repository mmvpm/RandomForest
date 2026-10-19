/// Loads the shared authoring catalogue once without consuming gameplay RNG.
function funWorldPropCatalog() {
    if (!variable_global_exists("world_prop_catalog")) {
        global.world_prop_catalog = json_parse(funReadGeneratedLevelFile("world_props/catalog.json")).props
    }
    return global.world_prop_catalog
}

/// Resolves one stable prop slug from the shared catalogue.
function funWorldPropDefinition(slug) {
    var definitions = funWorldPropCatalog()
    for (var i = 0; i < array_length(definitions); ++i) {
        if (definitions[i].slug == slug) return definitions[i]
    }
    return undefined
}

/// Accepts integer coordinates only, including negative local cell offsets.
function __funWorldPropInteger(value) {
    return is_real(value) && !is_bool(value) && floor(value) == value
}

/// Defaults legacy props to full visibility while keeping the authored percentage.
function funWorldPropOpacity(prop) {
    return variable_struct_exists(prop, "opacity") ? prop.opacity : 100
}

/// Defaults legacy props to their original position above platforms.
function funWorldPropPlatformLayer(prop) {
    return variable_struct_exists(prop, "platform_layer") ? prop.platform_layer : "above"
}

/// Treats older prop groups as having no authored one-way collision cells.
function funWorldPropJumpThroughs(prop) {
    return variable_struct_exists(prop, "jump_thrus") ? prop.jump_thrus : []
}

/// Checks either collision type using the same reflected local six-pixel coordinates.
function __funValidateWorldPropCells(prop, cells, width, height) {
    if (!is_array(cells)) return "Prop collision cells must be an array."
    for (var j = 0; j < array_length(cells); ++j) {
        var cell = cells[j]
        if (!is_array(cell) || array_length(cell) != 2) return "Prop collision cell must contain two coordinates."
        if (!__funWorldPropInteger(cell[0]) || !__funWorldPropInteger(cell[1])) return "Prop collision coordinates must be integers."
        var column = prop.x div 6 + (prop.mirrored ? -cell[0] - 1 : cell[0])
        var row = prop.y div 6 + cell[1]
        if (column < 0 || row < 0 || column >= width * 2 || row >= height * 2) return "Prop collision leaves the room."
    }
    return ""
}

/// Reports malformed authored groups before the builder accesses their geometry.
function funValidateWorldProps(level_data) {
    if (!variable_struct_exists(level_data, "props")) return ""
    if (!is_array(level_data.props)) return "props must be an array."
    var ids = {}
    for (var i = 0; i < array_length(level_data.props); ++i) {
        var prop = level_data.props[i]
        if (!is_struct(prop)) return "Each prop must be an object."
        var fields = ["id", "type", "x", "y", "mirrored", "solids"]
        for (var j = 0; j < array_length(fields); ++j) {
            if (!variable_struct_exists(prop, fields[j])) return "Prop is missing " + fields[j] + "."
        }
        if (!is_string(prop.id) || prop.id == "" || variable_struct_exists(ids, prop.id)) return "Prop IDs must be unique non-empty strings."
        variable_struct_set(ids, prop.id, true)
        if (!is_string(prop.type) || is_undefined(funWorldPropDefinition(prop.type))) return "Unknown prop type."
        if (!__funWorldPropInteger(prop.x) || !__funWorldPropInteger(prop.y)) return "Prop positions must be integers."
        if (prop.x mod 6 != 0 || prop.y mod 6 != 0) return "Prop positions must use the 6 px grid."
        if (prop.x < 0 || prop.y < 0 || prop.x > level_data.width * 12 || prop.y > level_data.height * 12) return "Prop anchor leaves the room."
        if (!is_bool(prop.mirrored) || !is_array(prop.solids)) return "Invalid prop reflection or solid cells."
        var opacity = funWorldPropOpacity(prop)
        if (!__funWorldPropInteger(opacity) || opacity < 0 || opacity > 100) return "Prop opacity must be an integer from 0 to 100."
        var platform_layer = funWorldPropPlatformLayer(prop)
        if (!is_string(platform_layer) || (platform_layer != "above" && platform_layer != "below")) return "Prop platform_layer must be above or below."
        var cell_error = __funValidateWorldPropCells(prop, prop.solids, level_data.width, level_data.height)
        if (cell_error != "") return cell_error
        cell_error = __funValidateWorldPropCells(prop, funWorldPropJumpThroughs(prop), level_data.width, level_data.height)
        if (cell_error != "") return cell_error
    }
    return ""
}

/// Adds authored prop cells to the same collision union as terrain and spike bases.
function funMarkWorldPropSolids(level_data, solid_cells) {
    if (!variable_struct_exists(level_data, "props")) return
    for (var i = 0; i < array_length(level_data.props); ++i) {
        var prop = level_data.props[i]
        for (var j = 0; j < array_length(prop.solids); ++j) {
            var cell = prop.solids[j]
            var column = prop.x div 6 + (prop.mirrored ? -cell[0] - 1 : cell[0])
            __funMarkGeneratedFineSolid(solid_cells, column, prop.y div 6 + cell[1])
        }
    }
}

/// Unions one-way cells across prop groups without adding them to the solid grid.
function __funWorldPropJumpThroughGrid(level_data) {
    var jump_cells = undefined
    if (!variable_struct_exists(level_data, "props")) return jump_cells
    for (var i = 0; i < array_length(level_data.props); ++i) {
        var prop = level_data.props[i]
        var cells = funWorldPropJumpThroughs(prop)
        if (array_length(cells) == 0) continue
        if (is_undefined(jump_cells)) jump_cells = __funGeneratedGrid(level_data.width * 2, level_data.height * 2, false)
        for (var j = 0; j < array_length(cells); ++j) {
            var cell = cells[j]
            var column = prop.x div 6 + (prop.mirrored ? -cell[0] - 1 : cell[0])
            __funMarkGeneratedFineSolid(jump_cells, column, prop.y div 6 + cell[1])
        }
    }
    return jump_cells
}

/// Merges horizontal runs only; each six-pixel row keeps its own one-way top surface.
function funBuildWorldPropJumpThroughs(level_data) {
    var jump_cells = __funWorldPropJumpThroughGrid(level_data)
    if (is_undefined(jump_cells)) return
    var width = level_data.width * 2
    for (var row = 0; row < level_data.height * 2; ++row) {
        var column = 0
        while (column < width) {
            if (!jump_cells[row][column]) {
                ++column
                continue
            }
            var start_column = column
            while (column < width && jump_cells[row][column]) {
                ++column
            }
            instance_create_layer(start_column * 6, row * 6, "Instances", oJumpThru, {
                image_xscale: (column - start_column) * 0.5,
                image_yscale: 1
            })
        }
    }
}

/// Creates static art on either side of platforms, behind spikes and actors.
function funBuildWorldProps(level_data) {
    if (!variable_struct_exists(level_data, "props")) return
    var prop_layer = layer_create(350, "WorldProps")
    var behind_layer = layer_create(450, "WorldPropsBehind")
    for (var i = 0; i < array_length(level_data.props); ++i) {
        var prop = level_data.props[i]
        var definition = funWorldPropDefinition(prop.type)
        var target_layer = funWorldPropPlatformLayer(prop) == "below" ? behind_layer : prop_layer
        instance_create_layer(prop.x, prop.y, target_layer, oWorldProp, {
            sprite_index: asset_get_index(definition.variants.day.sprite),
            image_xscale: prop.mirrored ? -1 : 1,
            image_speed: 0,
            image_alpha: funWorldPropOpacity(prop) / 100,
            world_prop_light: variable_struct_exists(definition, "light") ? definition.light : undefined
        })
    }
}

/// Draws a quiet lantern beam behind the prop and lets the platform layer occlude it.
function funDrawWorldPropLight() {
    if (!variable_instance_exists(self, "world_prop_light") || is_undefined(self.world_prop_light)) return
    var light = self.world_prop_light
    var theme = funCurrentLevelTheme()
    var strength = theme == "night" ? 1 : (theme == "evening" ? 0.65 : 0.25)
    var facing = sign(self.image_xscale)
    var source_x = self.x + facing * light.x
    var source_y = self.y + light.y
    var end_x = source_x + facing * light.dx
    var end_y = source_y + light.dy
    var colour = make_color_rgb(224, 210, 247)
    var alpha = strength * self.image_alpha
    draw_primitive_begin(pr_trianglestrip)
    draw_vertex_color(source_x, source_y - 3, colour, alpha * 0.17)
    draw_vertex_color(source_x, source_y + 3, colour, alpha * 0.17)
    draw_vertex_color(end_x, end_y - light.half_width, colour, 0)
    draw_vertex_color(end_x, end_y + light.half_width, colour, 0)
    draw_primitive_end()
    draw_sprite_ext(sPlayerBloom2, 0, source_x, source_y, 1.8, 1.8, 0, colour, alpha * 0.65)
}

/// Keeps the lantern glass luminous instead of hiding the source behind opaque artwork.
function funDrawWorldPropLightSource() {
    if (!variable_instance_exists(self, "world_prop_light") || is_undefined(self.world_prop_light)) return
    var light = self.world_prop_light
    var theme = funCurrentLevelTheme()
    var strength = theme == "night" ? 1 : (theme == "evening" ? 0.65 : 0.25)
    var source_x = self.x + sign(self.image_xscale) * (light.x - 7)
    draw_sprite_ext(sPlayerBloom2, 0, source_x, self.y + light.y, 0.55, 0.55, 0,
                    make_color_rgb(238, 222, 255), strength * self.image_alpha * 0.85)
}
