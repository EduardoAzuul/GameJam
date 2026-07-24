# CartaEjecutor.gd
extends Node

const MULTIPLICADOR_PERFECT := 2.0
const MULTIPLICADOR_NORMAL := 1.0
const MULTIPLICADOR_FALLO := 0.25


func jugar_carta(carta: Carta, enemigo_objetivo: Node) -> bool:
	if carta.solo_primera_carta and TurnoManager.cartas_jugadas_este_turno > 0:
		return false

	if not VidaManager.pagar_costo_carta(carta.costo_vida):
		return false

	var multiplicador := 1.0

	if carta.requiere_skill_check:
		var resultado = await SkillCheckManager.ejecutar_check()
		match resultado.tipo:
			"perfect":
				if EstadoManager.obtener_nivel("herradura") > 0:
					multiplicador = 3.0
					EstadoManager.aplicar("herradura", -1)
				else:
					multiplicador = MULTIPLICADOR_PERFECT
			"normal":
				multiplicador = MULTIPLICADOR_NORMAL
			"fallo":
				multiplicador = MULTIPLICADOR_FALLO

	for efecto in carta.efectos:
		var valor_final = efecto.valor
		if carta.requiere_skill_check:
			valor_final = max(1, int(round(efecto.valor * multiplicador)))

		match efecto.tipo:
			Efecto.TipoEfecto.ATACAR:
				if efecto.num_golpes > 1:
					for _i in range(efecto.num_golpes):
						if not is_instance_valid(enemigo_objetivo):
							break
						var hit_mult := 1.0
						var resultado = await SkillCheckManager.ejecutar_check()
						match resultado.tipo:
							"perfect":
								if EstadoManager.obtener_nivel("herradura") > 0:
									hit_mult = 3.0
									EstadoManager.aplicar("herradura", -1)
								else:
									hit_mult = MULTIPLICADOR_PERFECT
							"normal":  hit_mult = MULTIPLICADOR_NORMAL
							"fallo":   hit_mult = MULTIPLICADOR_FALLO
						if not is_instance_valid(enemigo_objetivo):
							break
						var hit_dano = max(1, int(round(efecto.valor * hit_mult)))
						if EstadoManager.obtener_nivel("fuerza") > 0:
							hit_dano = int(hit_dano * 2.0)
						if EstadoManager.obtener_nivel("debilidad") > 0:
							hit_dano = max(1, int(hit_dano * 0.5))
						if enemigo_objetivo.tiene_estado("vulnerabilidad"):
							hit_dano = int(hit_dano * 1.5)
						enemigo_objetivo.recibir_dano(RelicManager.calcular_dano_con_primer_golpe(hit_dano))
				else:
					if not is_instance_valid(enemigo_objetivo):
						break
					if efecto.escalado_vida:
						var vida_perdida = VidaManager.vida_maxima - VidaManager.vida_actual
						valor_final = max(1, int(round((vida_perdida / 2.0) * multiplicador)))
					if EstadoManager.obtener_nivel("fuerza") > 0:
						valor_final = int(valor_final * 2.0)
					if EstadoManager.obtener_nivel("debilidad") > 0:
						valor_final = max(1, int(valor_final * 0.5))
					if enemigo_objetivo.tiene_estado("vulnerabilidad"):
						valor_final = int(valor_final * 1.5)
					enemigo_objetivo.recibir_dano(RelicManager.calcular_dano_con_primer_golpe(valor_final))
			Efecto.TipoEfecto.DEFENDER:
				VidaManager.ganar_escudo(valor_final)
			Efecto.TipoEfecto.CURAR:
				var cura = efecto.valor
				if efecto.aleatorio:
					cura = randi_range(efecto.valor, efecto.valor_max)
				VidaManager.curar(cura)
			Efecto.TipoEfecto.APLICAR_ESTADO:
				EstadoManager.aplicar(efecto.estado_a_aplicar, efecto.valor)
			Efecto.TipoEfecto.ROBAR_CARTAS:
				ManoManager.robar(efecto.valor)
			Efecto.TipoEfecto.APLICAR_ESTADO_ENEMIGO:
				if is_instance_valid(enemigo_objetivo):
					enemigo_objetivo.aplicar_estado(efecto.estado_a_aplicar, efecto.valor)
			Efecto.TipoEfecto.DESCARTAR_ELEGIDAS:
				ManoManager.solicitar_seleccion_descarte.emit(efecto.valor)
				await ManoManager.descarte_elegido_confirmado
			Efecto.TipoEfecto.TODO_O_NADA:
				var cantidad = ManoManager.mano.size()
				ManoManager.descartar_mano_completa()
				ManoManager.robar(cantidad)

	TurnoManager.cartas_jugadas_este_turno += 1
	return true
