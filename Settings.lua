-- TidyMinimap config file

TidyMinimap:enable({
	layout = {
		pos = 'BOTTOMRIGHT#MinimapCluster#BOTTOMRIGHT#0#-10',
		anchor = 'topright',
		grow = 'left',
		scale = 0.7,
		borders = true,

		-- Only use this if you need to move the minimap down to make space for the buttons.
		nudgeminimap = false,
	},

	-- Let these buttons stay on the minimap
	skip = {
		['MiniMapWorldMapButton'] = true,
		['MiniMapBattlefieldFrame'] = true,
	},

	-- If a minimap button is not picked
	-- up automagically, add it here
	special = {
		['OutfitterMinimapButton'] = true,
		['BejeweledMinimapIcon'] = true,
		['WIM3MinimapButton'] = true,
		['Gatherer_MinimapOptionsButton'] = true,
		['BagSync_MinimapButton'] = true,
	}
})
