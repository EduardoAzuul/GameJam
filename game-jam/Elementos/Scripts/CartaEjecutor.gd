# CartaEjecutor.gd (puede ser autoload o un script estático)
extends Node

func jugar_carta(carta: Carta, enemigo_objetivo: Node) -> bool:
	if not VidaManager.pagar_costo_carta(carta.costo_vida):
		return false  # no hay vida suficiente, la carta no se jugó

	match carta.tipo_efecto:
		Carta.TipoEfecto.ATACAR:
			enemigo_objetivo.recibir_dano(carta.valor_efecto)
		Carta.TipoEfecto.DEFENDER:
			VidaManager.ganar_escudo(carta.valor_efecto)
		Carta.TipoEfecto.CURAR:
			VidaManager.curar(carta.valor_efecto)
		Carta.TipoEfecto.APLICAR_ESTADO:
			EstadoManager.aplicar(carta.estado_a_aplicar, carta.valor_estado)
		Carta.TipoEfecto.ROBAR_CARTAS:
			ManoManager.robar(carta.valor_efecto)

	return true
