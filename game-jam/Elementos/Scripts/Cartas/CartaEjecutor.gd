# CartaEjecutor.gd
extends Node

func jugar_carta(carta: Carta, enemigo_objetivo: Node) -> bool:
	if not VidaManager.pagar_costo_carta(carta.costo_vida):
		return false
	for efecto in carta.efectos:
		match efecto.tipo:
			Efecto.TipoEfecto.ATACAR:
				enemigo_objetivo.recibir_dano(efecto.valor)
			Efecto.TipoEfecto.DEFENDER:
				VidaManager.ganar_escudo(efecto.valor)
			Efecto.TipoEfecto.CURAR:
				VidaManager.curar(efecto.valor)
			Efecto.TipoEfecto.APLICAR_ESTADO:
				EstadoManager.aplicar(efecto.estado_a_aplicar, efecto.valor)
			Efecto.TipoEfecto.ROBAR_CARTAS:
				ManoManager.robar(efecto.valor)
	return true
