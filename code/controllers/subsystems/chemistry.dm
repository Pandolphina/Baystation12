SUBSYSTEM_DEF(chemistry)
	name = "Chemistry"
	priority = SS_PRIORITY_CHEMISTRY
	init_order = SS_INIT_CHEMISTRY

	var/list/active_holders =               list()
	var/list/chemical_reactions =           list()
	var/list/chemical_reactions_by_id =     list()
	var/list/chemical_reactions_by_result = list()
	var/list/processing_holders =           list()

	var/list/random_chem_prototypes =       list()

/datum/controller/subsystem/chemistry/stat_entry()
	..("AH:[active_holders.len]")

/datum/controller/subsystem/chemistry/Initialize()

	// Init reaction list.
	//Chemical Reactions - Initialises all /datum/chemical_reaction into a list
	// It is filtered into multiple lists within a list.
	// For example:
	// chemical_reaction_list["phoron"] is a list of all reactions relating to phoron
	// Note that entries in the list are NOT duplicated. So if a reaction pertains to
	// more than one chemical it will still only appear in only one of the sublists.

	for(var/path in subtypesof(/datum/chemical_reaction))
		var/datum/chemical_reaction/D = new path()
		chemical_reactions += D
		if(!chemical_reactions_by_result[D.result])
			chemical_reactions_by_result[D.result] = list()
		chemical_reactions_by_result[D.result] += D
		if(D.required_reagents && D.required_reagents.len)
			var/reagent_id = D.required_reagents[1]
			if(!chemical_reactions_by_id[reagent_id])
				chemical_reactions_by_id[reagent_id] = list()
			chemical_reactions_by_id[reagent_id] += D
	. = ..()

/datum/controller/subsystem/chemistry/fire(resumed = FALSE)
	if (!resumed)
		processing_holders = active_holders.Copy()

	while(processing_holders.len)
		var/datum/reagents/holder = processing_holders[processing_holders.len]
		processing_holders.len--

		if (QDELETED(holder))
			active_holders -= holder
			log_debug("SSchemistry: QDELETED holder found in processing list!")
			if(MC_TICK_CHECK)
				return
			continue

		if (!holder.process_reactions())
			active_holders -= holder

		if (MC_TICK_CHECK)
			return

/datum/controller/subsystem/chemistry/proc/get_prototype(var/datum/reagent/random/reagent)
	if(!istype(reagent))
		return
	. = random_chem_prototypes[reagent.type]
	if(!.)
		var/datum/reagent/random/new_prototype = new reagent.type(null, TRUE)
		new_prototype.randomize_data()
		. = new_prototype
		random_chem_prototypes[reagent.type] = .

/datum/controller/subsystem/chemistry/proc/get_random_chem(var/only_if_unique = FALSE)
	for(var/type in typesof(/datum/reagent/random))
		if(only_if_unique && random_chem_prototypes[type])
			continue
		get_prototype(type) // we don't need it, but fill the cache to know it's been assigned
		return type