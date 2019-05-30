function Client_PresentConfigureUI(rootParent)
	local commanderAttackKillRate = Mod.Settings.CommanderAttackKillRate;
	if commanderAttackKillRate == nil then commanderAttackKillRate = 60; end
	local commanderDefenseKillRate = Mod.Settings.CommanderDefenseKillRate;
	if commanderDefenseKillRate == nil then commanderDefenseKillRate = 70; end
	local commanderStrength = Mod.Settings.CommanderStrength
	if commanderStrength == nil then commanderStrength = 7; end 

	local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Commander\'s attack kill rate[%]');
	commanderAttackKillRateNIF = UI.CreateNumberInputField(horz).SetSliderMinValue(5).SetSliderMaxValue(300).SetValue(commanderAttackKillRate);

	local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Commander\'s defense kill rate[%]');
	commanderDefenseKillRateNIF = UI.CreateNumberInputField(horz).SetSliderMinValue(5).SetSliderMaxValue(300).SetValue(commanderDefenseKillRate)

	local horz = UI.CreateHorizontalLayoutGroup(rootParent);
	UI.CreateLabel(horz).SetText('Commander\'s strength');
	commanderStrengthNIF = UI.CreateNumberInputField(horz).SetSliderMinValue(1).SetSliderMaxValue(100).SetValue(commanderStrength);

end