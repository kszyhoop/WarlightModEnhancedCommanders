function Client_PresentSettingsUI(rootParent)
	UI.CreateLabel(rootParent).SetText('Commander\'s attack kill rate[%]: ' .. Mod.Settings.CommanderAttackKillRate);
	UI.CreateLabel(rootParent).SetText('Commander\'s defense kill rate[%]: ' .. Mod.Settings.CommanderDefenseKillRate);
	UI.CreateLabel(rootParent).SetText('Commander\'s strength: ' .. Mod.Settings.CommanderStrength);

	
end

