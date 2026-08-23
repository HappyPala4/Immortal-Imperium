#if !defined(using_map_DATUM)
	#include "../delta/warhammer_areas.dm"
	#include "../delta/jobs/warhammer_jobs.dm"
	#include "geliak_jobs.dm"
	#include "../shared/items/clothing.dm"
	#include "../shared/items/cards_ids.dm"

	#include "geliak.dmm"

	#include "../../code/modules/lobby_music/generic_songs.dm"

	#define using_map_DATUM /datum/map/geliak

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Geliak

#endif
