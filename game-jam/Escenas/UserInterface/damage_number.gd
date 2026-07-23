# DamageNumber.gd
extends Label

func _ready() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60, 0.6).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.15)
	tween.chain().tween_callback(queue_free)


func configurar(valor: int, es_curacion: bool = false) -> void:
	text = str(valor)
	modulate = Color(0.3, 1, 0.3) if es_curacion else Color(1, 0.3, 0.3)
	scale = Vector2(0.5, 0.5)
	var tween_pop = create_tween()
	tween_pop.tween_property(self, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_BACK)
