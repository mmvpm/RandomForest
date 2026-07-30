// Build authored content before camera and HUD Create events run.
var styled_level = funStyleGeneratedLevel(global.generated_level_data)
funBuildGeneratedLevel(styled_level)
instance_destroy()
