extends RefCounted
## Loads each effect only where it is cast or viewed. Each instance owns its clip.

const ART := "res://art/effects/"
const EFFECTS := {
	"fireball": "Playable in Pinewood",
	"summon": "Playable in the Forsaken chapter",
	"ember_dart": "Browser spell · PC effect preview",
	"chill_needle": "Browser spell · PC effect preview",
	"mending_light": "Browser spell · PC effect preview",
	"sanguine_drain": "Earlier Maelis spell · PC effect preview",
	"covenant_thorns": "Earlier Maelis spell · PC effect preview",
	"bone_spear": "Earlier Maelis spell · PC effect preview",
	"fire_skeleton_aura": "Cross-school concept",
	"reinforced_skeleton_aura": "Cross-school concept",
	"equipment_rune": "Item and rune concept",
}

static func frames(effect: String) -> SpriteFrames:
	var path := ART + effect + ".tres"
	if not ResourceLoader.exists(path, "SpriteFrames"):
		return null
	return load(path) as SpriteFrames

static func play(parent: Node2D, effect: String, clip: StringName, where: Vector2) -> AnimatedSprite2D:
	var source := frames(effect)
	if source == null or not source.has_animation(clip):
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = source
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = where
	sprite.z_index = 7
	if not source.get_animation_loop(clip):
		sprite.animation_finished.connect(sprite.queue_free)
	parent.add_child(sprite)
	sprite.play(clip)
	return sprite
