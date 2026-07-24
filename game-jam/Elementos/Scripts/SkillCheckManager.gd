# SkillCheckManager.gd
extends Node

const BONUS_ESCUDO_REBOTE := 2

var instancia: Node = null


func registrar(nodo: Node) -> void:
	instancia = nodo
	if not instancia.rebote_alcanzado.is_connected(_on_rebote_alcanzado):
		instancia.rebote_alcanzado.connect(_on_rebote_alcanzado)


func _on_rebote_alcanzado() -> void:
	VidaManager.ganar_escudo(BONUS_ESCUDO_REBOTE)
	print("¡Rebote! +", BONUS_ESCUDO_REBOTE, " de escudo bonus")


func ejecutar_check() -> Dictionary:
	if instancia == null:
		push_warning("SkillCheck no registrado, se asume éxito normal")
		return {"success": true, "tipo": "normal"}

	instancia.start_check()
	var resultado = await instancia.check_finished  
	var success: bool = resultado[0]
	var tipo: String = resultado[1]
	return {"success": success, "tipo": tipo}
