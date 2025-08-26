class_name Globals

enum Zone {
	JUNGLE,
	LAVA,
	ICE,
	CAVE,
	CLIFF
}

enum ModifierType {
	POINTADD,
	MULTIPLIERADD,
	MULTIPLIERMULT,
	STATADD,
	STATMULT,
	OTHER
}

func zone_type_to_name(zone : Zone):
	match zone:
		Zone.JUNGLE:
			return "Jungle"
		Zone.LAVA:
			return "Lava"
		Zone.ICE:
			return "ICE"
		Zone.CAVE:
			return "CAVE"
		Zone.CLIFF:
			return "CLIFF"
