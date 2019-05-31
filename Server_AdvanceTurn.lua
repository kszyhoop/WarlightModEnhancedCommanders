function Server_AdvanceTurn_Start(game, addNewOrder)
	
end

CopiedActualArmies = nil;
UseCopiedActualArmies = false;
ForceTransferAll = false;

function recalculateOrder(game, order, result)
	local defendingTerritory = game.ServerGame.LatestTurnStanding.Territories[order.To]
	local attackingCommanderPresent = result.ActualArmies.AttackPower ~= result.ActualArmies.NumArmies;	
	local defendingCommanderPresent = defendingTerritory.NumArmies.DefensePower ~= defendingTerritory.NumArmies.NumArmies;

	local killRate
	local attackPower
	local defensePower;
	
	if (attackingCommanderPresent) then
		killRate = Mod.Settings.CommanderAttackKillRate / 100;
		attackPower = result.ActualArmies.NumArmies + Mod.Settings.CommanderStrength;
	else 
		killRate = game.Settings.OffenseKillRate;
		attackPower = result.ActualArmies.AttackPower;
	end;

	local defendingUnitsToKill = math.floor(attackPower * killRate + 0.5);  -- TODO: luck and rounding mode

	if (defendingCommanderPresent) then
		killRate = Mod.Settings.CommanderDefenseKillRate / 100;
		defensePower = defendingTerritory.NumArmies.NumArmies + Mod.Settings.CommanderStrength;
	else
		killRate = game.Settings.DefenseKillRate;
		defensePower = defendingTerritory.NumArmies.DefensePower;
	end;
	
	local attackingUnitsToKill = math.floor(defensePower * killRate + 0.5) -- TODO: luck and roundingMode;
	
	if (attackingCommanderPresent and attackingUnitsToKill >= attackPower) then	
		result.AttackingArmiesKilled = WL.Armies.Create(math.min(attackingUnitsToKill, result.ActualArmies.NumArmies), {result.ActualArmies.SpecialUnits[1]});
	else
		result.AttackingArmiesKilled = WL.Armies.Create(math.min(attackingUnitsToKill, result.ActualArmies.NumArmies))
	end;

	if (defendingCommanderPresent and defendingUnitsToKill >= defensePower) then
		result.DefendingArmiesKilled = WL.Armies.Create(math.min(defendingUnitsToKill, defendingTerritory.NumArmies.NumArmies), {defendingTerritory.NumArmies.SpecialUnits[1]});
	else
		result.DefendingArmiesKilled = WL.Armies.Create(math.min(defendingUnitsToKill, defendingTerritory.NumArmies.NumArmies))
	end;

end

function createCommanderFleeOrder(game, order)
	local defendingTerritory = game.ServerGame.LatestTurnStanding.Territories[order.To]
	local potentialDestinations = FindNeighbourhood(game,defendingTerritory, 1, defendingTerritory.OwnerPlayerID);		
	if tablelength(potentialDestinations[1]) > 0 then
		local commanderAlone = WL.Armies.Create(0, {defendingTerritory.NumArmies.SpecialUnits[1]});
		-- todo: najsilniejszy sąsiad, nie pierwszy 
		local fleeOrder = WL.GameOrderAttackTransfer.Create(
			defendingTerritory.OwnerPlayerID,
			defendingTerritory.ID,
			potentialDestinations[1][1],
			order.AttackTransfer,
			false,
			commanderAlone,
			false);
		return fleeOrder;
	else
		return nil;
	end
end

function Server_AdvanceTurn_Order(game, order, result, skipThisOrder, addNewOrder)
	SetOrderExecutionFlags(order)
	if order.proxyType == 'GameOrderCustom' and order.Message == "" then 
		skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
		return 
	end;

	if order.proxyType ~= 'GameOrderAttackTransfer' then return end;
	
	if UseCopiedActualArmies then
		result.ActualArmies = CopiedActualArmies;
		recalculateOrder(game, order, result);
		CopiedActualArmies = nil;
		UseCopiedActualArmies = false;
	end;
	if ForceTransferAll then
		result.ActualArmies = order.NumArmies;
		ForceTransferAll = false;		
	end;

	local defendingTerritory = game.ServerGame.LatestTurnStanding.Territories[order.To]
	if (defendingTerritory.OwnerPlayerID == order.PlayerID) then 
		return 
	end; -- transferów nie ma co przeliczać

	local attackingCommanderPresent = result.ActualArmies.NumArmies ~= result.ActualArmies.AttackPower;
	local defendingCommanderPresent = defendingTerritory.NumArmies.DefensePower ~= defendingTerritory.NumArmies.NumArmies;
	
	if (not attackingCommanderPresent and not defendingCommanderPresent) then return end; --nie ma żadnych commanderów, spadamy

	recalculateOrder(game, order, result);
	local attackingCommanderDies = tablelength(result.AttackingArmiesKilled.SpecialUnits) > 0;
	local defendingCommanderDies = tablelength(result.DefendingArmiesKilled.SpecialUnits) > 0;
	
	if attackingCommanderDies then
		local commanderName = game.Game.Players[order.PlayerID].DisplayName(nil, false) .. ' (commander)'
		result.ActualArmies = WL.Armies.Create(result.ActualArmies.NumArmies); -- idą jeszcze raz, ale  bez commandera
		if (result.ActualArmies.NumArmies > 0) then 
			recalculateOrder(game, order, result)
			addNewOrder(WL.GameOrderCustom.Create(order.PlayerID, commanderName .. " send his army for certain death, staying himself safely in base", "")) 	
			if not defendingTerritory.IsNeutral then 
				addNewOrder(WL.GameOrderCustom.Create(defendingTerritory.OwnerPlayerID, commanderName .. " send his army for certain death, staying himself safely in base", "")) 	
			end
		else
			addNewOrder(WL.GameOrderCustom.Create(order.PlayerID, commanderName .. " refuses to attack overwhelming enemy and die", "")) 	
			if not defendingTerritory.IsNeutral then 
				addNewOrder(WL.GameOrderCustom.Create(defendingTerritory.OwnerPlayerID, commanderName .. " refuses to attack overwhelming enemy and die", "")) 		
			end
		end
	end
	if defendingCommanderDies then
		local fleeOrder = createCommanderFleeOrder(game, order);
		if (fleeOrder ~= nil) then
			skipThisOrder(WL.ModOrderControl.SkipAndSupressSkippedMessage);
			local commanderName = game.Game.Players[defendingTerritory.OwnerPlayerID].DisplayName(nil, false) .. ' (commander)'
			addNewOrder(WL.GameOrderCustom.Create(defendingTerritory.OwnerPlayerID, commanderName .. " cowardly flees before battle", "FORCE_TRANSFER_ALL")) 	
			addNewOrder(WL.GameOrderCustom.Create(order.PlayerID, commanderName .. " run from our superior forces", "")) 	
			addNewOrder(fleeOrder);
			CopiedActualArmies = result.ActualArmies;
			addNewOrder(WL.GameOrderCustom.Create(defendingTerritory.OwnerPlayerID, "", "USE_COPIED_ACTUAL_ARMIES")) 	
			addNewOrder(order);
		end;
	end

end;

function SetOrderExecutionFlags(order)
	if order.proxyType == 'GameOrderCustom' then 
		if order.Payload == 'FORCE_TRANSFER_ALL' then
			ForceTransferAll = true;
			return;
		end
		if order.Payload == 'USE_COPIED_ACTUAL_ARMIES' then
			UseCopiedActualArmies = true;
			return;
		end
	end
end

-- BFS or at least i hope so
function FindNeighbourhood (game, sourceTerritory, maxDistance, playerID)
	local result = {}
	local visited = {}
	local map = game.Map;
	local territoryStanding = game.ServerGame.LatestTurnStanding.Territories;
	-- sourceTerritoryId as starting point with distance = 0;
	result[0] = {sourceTerritory.ID}
	visited[sourceTerritory.ID] = true;
	local distance = 0
	while distance < maxDistance do
		result[distance + 1] = {}
		for i, territoryID in ipairs(result[distance]) do
			local mapTerritory = map.Territories[territoryID]
			-- check connection and visit territory not yet visited (optionally use only player territories)
			for _, neighbour in pairs(mapTerritory.ConnectedTo) do
				if (not visited[neighbour.ID] and(playerID == nil or territoryStanding[neighbour.ID].OwnerPlayerID == playerID)) then
					table.insert(result[distance + 1], neighbour.ID)
					visited[neighbour.ID] = true
				end
			end
		end
		distance = distance + 1;
	end
	return result;
end 

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end
