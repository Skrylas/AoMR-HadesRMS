include "lib2/rm_core.xs";
include "lib2/rm_connections.xs";

mutable void applySuddenDeath()
{
   // Override and do nothing here for Sudden Death.
}

// TODO Have this as a library function that we can override so we don't have to call it.
void generateTriggers()
{
   rmTriggerAddScriptLine("const string cGPCeaseFire = \"CeaseFire3Minutes\";");
   rmTriggerAddScriptLine("const string cSettlement = \"Settlement\";");
   rmTriggerAddScriptLine("const string cTownCenter = \"TownCenter\";");

   rmTriggerAddScriptLine("");

   rmTriggerAddScriptLine("rule _ceasefire");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trGodPowerInvoke(0, cGPCeaseFire, vector(" + rmXFractionToMeters(0.5) + ", 0.0, " + rmZFractionToMeters(0.5) + "), vector(0.0, 0.0, 0.0));");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");
   
   rmTriggerAddScriptLine("rule _town_center_build_rate");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   for(int i = 1; i <= cNumberPlayers; i++)");
   rmTriggerAddScriptLine("   {");
   rmTriggerAddScriptLine("      trModifyProtounitData(cSettlement, i, 4, 0.25, 3);");
   rmTriggerAddScriptLine("      trModifyProtounitData(cTownCenter, i, 4, 0.25, 3);");
   rmTriggerAddScriptLine("   }");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");

   rmTriggerAddScriptLine("rule _town_center_restore_rate");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   if (((xsGetTime() - (cActivationTime / 1000)) >= 180))");
   rmTriggerAddScriptLine("   {");
   rmTriggerAddScriptLine("      for(int i = 1; i <= cNumberPlayers; i++)");
   rmTriggerAddScriptLine("      {");
   rmTriggerAddScriptLine("         trModifyProtounitData(cSettlement, i, 4, 1.75, 3);");
   rmTriggerAddScriptLine("         trModifyProtounitData(cTownCenter, i, 4, 1.75, 3);");
   rmTriggerAddScriptLine("      }");
   rmTriggerAddScriptLine("      xsDisableSelf();");
   rmTriggerAddScriptLine("   }");
   rmTriggerAddScriptLine("}");

   rmTriggerAddScriptLine("rule _lightset");
   rmTriggerAddScriptLine("highFrequency");
   rmTriggerAddScriptLine("active");
   rmTriggerAddScriptLine("{");
   rmTriggerAddScriptLine("   trSetLighting(\"" + cLightingSetErebus + "\", 180.0);");
   rmTriggerAddScriptLine("   xsDisableSelf();");
   rmTriggerAddScriptLine("}");
}

void generate()
{
   rmSetProgress(0.0);

   // Define mixes.
   int baseMixID = rmCustomMixCreate();
   rmCustomMixSetPaintParams(baseMixID, cNoiseFractalSum, 0.075, 5, 0.5);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirt1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirt2, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirtRocks1, 2.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainHadesDirtRocks2, 3.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseHellDirt, 1.0);
   rmCustomMixAddPaintEntry(baseMixID, cTerrainChineseHellDirtRocks, 2.0);

   // Custom forest.
   int forestTypeID = rmCustomForestCreate();
   rmCustomForestSetTerrain(forestTypeID, cTerrainHadesForestDirt);
   rmCustomForestAddTreeType(forestTypeID, cUnitTypeTreeHades, 4.0);
   rmCustomForestAddTreeType(forestTypeID, cUnitTypeTreePineDead, 2.0);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypePlantDeadWeeds, 0.2);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypePlantDeadGrass, 0.2);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypePlantDeadBush, 0.2);
   rmCustomForestAddUnderbrushType(forestTypeID, cUnitTypeRockHadesTiny, 0.2);

   // Map size and terrain init.
   int axisTiles = getScaledAxisTiles(160);
   rmSetMapSize(axisTiles);
   rmInitializeLand(cTerrainDefaultBlack);

   // Player placement - Nomad edit (shouldn't matter)
//   rmSetTeamSpacingModifier(0.85);
   rmPlacePlayersOnCircle(0.3);

   // Finalize player placement and do post-init things.
   postPlayerPlacement();

   // Mother Nature's civ.
   rmSetNatureCiv(cCivHades);

   // Lighting.
   rmSetLighting(cLightingSetBaseErebus);

   // Random Spots to create a more varied looking nomad.
   int randomSpotsClassID = rmClassCreate();

   int avoidRandomSpots = rmCreateClassDistanceConstraint(randomSpotsClassID, 20.0);
   int numRandomSpots = cNumberPlayers * getMapAreaSizeFactor();
   
   for(int i = 0; i < cNumberPlayers; i++)
   {
      int randomSpotsID = rmAreaCreate("random spots " + i);

      rmAreaSetSize(randomSpotsID, xsRandFloat(0.01, 0.015));
      rmAreaSetCoherence(randomSpotsID, 0.25);
      rmAreaAddToClass(randomSpotsID, randomSpotsClassID);

      rmAreaAddConstraint(randomSpotsID, vDefaultAvoidEdge);
      rmAreaAddConstraint(randomSpotsID, avoidRandomSpots);
      rmAreaAddConstraint(randomSpotsID, rmCreateLocDistanceConstraint(cCenterLoc, rmXFractionToMeters(0.3)));

      rmAreaBuild(randomSpotsID);
   }   
   // Used for Nomad Generation
   float continentRadiusMeters = cSqrtTwo * rmXFractionToMeters(0.5);

   // Set up the global (impassable) cliff area.
   int globalCliffID = rmAreaCreate("global cliff");
   rmAreaSetLoc(globalCliffID, cCenterLoc);
   rmAreaSetSize(globalCliffID, 1.0);
   rmAreaSetTerrainType(globalCliffID, cTerrainHadesLava2);

   rmAreaSetCoherence(globalCliffID, 1.0);

   rmAreaSetHeightNoise(globalCliffID, cNoiseFractalSum, 15.0, 0.05, 2, 0.5);
   rmAreaSetHeightNoiseBias(globalCliffID, 1.0); // Only grow upwards.

   rmAreaBuild(globalCliffID);

   rmSetProgress(0.1);

   // Create continent.
   int continentID = rmAreaCreate("continent");
   rmAreaSetLoc(continentID, cCenterLoc);
   rmAreaSetSize(continentID, 0.6);
   rmAreaSetMix(continentID, baseMixID);

   rmAreaSetHeight(continentID, 20.0);
   rmAreaSetHeightNoise(continentID, cNoiseFractalSum, 5.0, 0.1, 2, 0.5);
   rmAreaSetHeightNoiseBias(continentID, 1.0); // Only grow upwards.
   rmAreaAddHeightBlend(continentID, cBlendEdge, cFilter5x5Gaussian, 5, 3);

   rmAreaSetCliffType(continentID, cCliffHadesDirt);
   rmAreaSetCliffSideRadius(continentID, 0, 2);
   rmAreaSetCliffEmbellishmentDensity(continentID, 0.0);
   rmAreaSetCliffLayerPaint(continentID, cCliffLayerOuterSideClose, false);
   rmAreaSetCliffLayerPaint(continentID, cCliffLayerOuterSideFar, false);

   rmAreaBuild(continentID);

   // Create center.
   int centerID = rmAreaCreate("center");
   rmAreaSetLoc(centerID, cCenterLoc);
   rmAreaSetSize(centerID, rmRadiusToAreaFraction(32.0));
   rmAreaSetMix(centerID, baseMixID);

   rmAreaSetHeightRelative(centerID, 5.0);
   rmAreaAddHeightBlend(centerID, cBlendEdge, cFilter3x3Gaussian);
   rmAreaSetCoherence(centerID, 0.75);

   rmAreaSetCliffRamps(centerID, 4, 0.1);
   rmAreaSetCliffRampSteepness(centerID, 1.0);
   rmAreaSetCliffType(centerID, cCliffHadesDirt);
   rmAreaSetCliffSideRadius(centerID, 0, 1);
   rmAreaSetCliffEmbellishmentDensity(centerID, 0.0);

   rmAreaBuild(centerID);

   if (gameIsKotH() == false)
   {
      // Add some embellishment to the center.
      int centerTempleID = rmObjectDefCreate("center temple");
      rmObjectDefAddItem(centerTempleID, cUnitTypeTempleOfTheGods, 1);
      rmObjectDefPlaceAtLoc(centerTempleID, 0, cCenterLoc);
   }

   int centerTorchID = rmObjectDefCreate("center torch");
   rmObjectDefAddItem(centerTorchID, cUnitTypeTorch, 1);
   rmObjectDefSetItemVariation(centerTorchID, 0, 0);
   placeObjectDefInCircle(centerTorchID, 0, 6, 16.0);
   
   // KotH.
   placeKotHObjects();

   rmSetProgress(0.2);

   // Unlike most other maps, this one places stuff randomly on the continent.
   // Settlements.
   int numSettlementsPerPlayer = 2 + (1 * getMapSizeBonusFactor());

   int settlementID = rmObjectDefCreate("settlement");
   rmObjectDefAddItem(settlementID, cUnitTypeSettlement, 1);
   rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidImpassableLand);
   rmObjectDefAddConstraint(settlementID, vDefaultSettlementAvoidSiegeShipRange);
   rmObjectDefAddConstraint(settlementID, vDefaultAvoidKotH);
   addObjectLocsAtOrigin(settlementID, numSettlementsPerPlayer * cNumberPlayers, cCenterLoc,
                         0.0, continentRadiusMeters, 60.0);

   generateLocs("settlement locs");

   // Relics.
   float avoidRelicMeters = 60.0;

   int relicNumPerPlayer = 3 * getMapAreaSizeFactor();
   
   int numRelicsPerPlayer = min(relicNumPerPlayer * cNumberPlayers, cMaxRelics) / cNumberPlayers;

   int relicID = rmObjectDefCreate("relic");
   rmObjectDefAddItem(relicID, cUnitTypeRelic, 1);
   rmObjectDefAddItem(relicID, cUnitTypeStatueMajorGod, 1, 4.0);
   rmObjectDefAddItem(relicID, cUnitTypeShadePredator, 1, 4.0);
   rmObjectDefAddItemRange(relicID, cUnitTypeTorch, 0, 2, 4.0);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidEdge);
   rmObjectDefAddConstraint(relicID, vDefaultRelicAvoidAll);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(relicID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(relicID, rmCreateAreaDistanceConstraint(continentID, 1.0));
   rmObjectDefAddConstraint(relicID, rmCreateAreaEdgeMaxDistanceConstraint(continentID, 10.0));
   addObjectDefPlayerLocConstraint(relicID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(relicID, false, numRelicsPerPlayer, 60.0, -1.0, avoidRelicMeters);
   }
   else
   {
      addObjectLocsPerPlayer(relicID, false, numRelicsPerPlayer, 60.0, -1.0, avoidRelicMeters);
   }

   // This one has to blend into the others seamlessly.
   int relicPathClassID = rmClassCreate();
   int relicAreaClassID = rmClassCreate();
   int cliffBlendClassID = rmClassCreate();
   rmAreaAddToClass(continentID, cliffBlendClassID);

   int relicAreaAvoidContinentCliff = rmCreateClassMaxDistanceConstraint(cliffBlendClassID, 0.0, cClassAreaCliffInsideDistance);

   int relicAreaDefID = rmAreaDefCreate("relic area def");
   rmAreaDefSetHeight(relicAreaDefID, 20.0);
   rmAreaDefSetHeightNoise(relicAreaDefID, cNoiseFractalSum, 7.5, 0.1, 1, 0.5);
   rmAreaDefAddHeightBlend(relicAreaDefID, cBlendEdge, cFilter3x3Gaussian);

   rmAreaDefSetCliffType(relicAreaDefID, cCliffHadesDirt);
   rmAreaDefSetCliffSideRadius(relicAreaDefID, 0, 2);
   rmAreaDefSetCliffEmbellishmentDensity(relicAreaDefID, 0.0);
   rmAreaDefSetCliffLayerPaint(relicAreaDefID, cCliffLayerOuterSideClose, false);
   rmAreaDefSetCliffLayerPaint(relicAreaDefID, cCliffLayerOuterSideFar, false);

   rmAreaDefAddToClass(relicAreaDefID, cliffBlendClassID);

   rmAreaDefAddCliffEdgeConstraint(relicAreaDefID, cCliffEdgeIgnored, relicAreaAvoidContinentCliff);
   
   float relicAreaMinSize = rmTilesToAreaFraction(250);
   float relicAreaMaxSize = rmTilesToAreaFraction(300);

   if(generateLocs("relic locs", true, false, false, false) == true)
   {
      rmAddClosestLocConstraint(vDefaultAvoidImpassableLand16);
      rmAddClosestLocConstraint(rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0));

      // Build small relic areas.
      int numLocs = rmLocGenGetNumberLocs();
      for(int i = 0; i < numLocs; i++)
      {
         vector loc = rmLocGenGetLoc(i);

         vector pathEndPoint = rmGetClosestLoc(loc, rmXFractionToMeters(1.0));

         int relicPathID = rmPathCreate("relic path " + i);
         rmPathAddWaypoint(relicPathID, loc);
         rmPathAddWaypoint(relicPathID, pathEndPoint);
         rmPathSetCostNoise(relicPathID, 0.0, 4.0);
         rmPathAddToClass(relicPathID, relicPathClassID);
         rmPathBuild(relicPathID);

         int relicPathAreaID = rmAreaDefCreateArea(relicAreaDefID, "relic path area " + i);
         rmAreaSetPath(relicPathAreaID, relicPathID, 20.0);
         // rmAreaSetTerrainType(relicPathAreaID, cTerrainDefaultBlack);
         rmAreaAddHeightBlend(relicPathAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaAddToClass(relicPathAreaID, relicAreaClassID);
         rmAreaBuild(relicPathAreaID);

         // The actual relic area.
         int relicAreaID = rmAreaDefCreateArea(relicAreaDefID, "relic area " + i);
         rmAreaSetLoc(relicAreaID, loc);
         rmAreaSetSize(relicAreaID, xsRandFloat(relicAreaMinSize, relicAreaMaxSize));
         rmAreaSetHeight(relicAreaID, 25.0);
         rmAreaAddHeightBlend(relicAreaID, cBlendAll, cFilter5x5Box, 10);
         rmAreaSetCoherence(relicAreaID, 0.25);
         rmAreaAddToClass(relicAreaID, relicAreaClassID);
         rmAreaBuild(relicAreaID);
      }

      rmClearClosestLocConstraints();

      applyGeneratedLocs();
   }

   resetLocGen();

   rmSetProgress(0.3);

   // Create small cliffs.
   int cliffClassID = rmClassCreate();
   int innerCliffID = rmClassCreate();

   int numCliffsPerPlayer = 3 * getMapAreaSizeFactor();
   int cliffAvoidSelf = rmCreateClassDistanceConstraint(cliffClassID, 25.0);
   int cliffAvoidCenter = rmCreateAreaDistanceConstraint(centerID, 15.0);
   int cliffAvoidBuildings = rmCreateTypeDistanceConstraint(cUnitTypeBuilding, 20.0);
   int cliffForceOnContinent = rmCreateAreaConstraint(continentID);
   int cliffAvoidContinentEdge = rmCreateAreaEdgeDistanceConstraint(continentID, 30.0);
   int cliffAvoidRelicPathArea = rmCreateClassDistanceConstraint(relicPathClassID, 1.0);

   float minCliffSize = rmTilesToAreaFraction(75);
   float maxCliffSize = rmTilesToAreaFraction(175);
   
   for(int t = 1; t <= cNumberTeams; t++)
   {
      int cliffForceInTeamArea = rmCreateAreaConstraint(vTeamAreaIDs[t]);
      int numCliffs = numCliffsPerPlayer * rmGetNumberPlayersOnTeam(t);

      for(int i = 0; i < numCliffs; i++)
      {
         int cliffID = rmAreaCreate("cliff " + t + " " + i);
         rmAreaSetSize(cliffID, xsRandFloat(minCliffSize, maxCliffSize));

         rmAreaSetCliffType(cliffID, cCliffHadesDirt);
         // TODO Height blend could also be randomized for some variance.
         if(xsRandBool(0.5) == true)
         {
            rmAreaSetHeightRelative(cliffID, xsRandFloat(5.0, 10.0));
            rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter3x3Gaussian);
         }
         else
         {
            rmAreaSetHeightRelative(cliffID, -15.0);
            rmAreaAddHeightBlend(cliffID, cBlendAll, cFilter5x5Box, 2);
         }
         rmAreaSetCliffPaintInsideAsSide(cliffID, true);
         rmAreaSetCliffSideRadius(cliffID, 0, 1);
         rmAreaSetCliffEmbellishmentDensity(cliffID, 0.0);

         rmAreaSetHeightNoise(cliffID, cNoiseFractalSum, 10.0, 0.2, 2, 0.5);

         rmAreaAddConstraint(cliffID, cliffForceOnContinent);
         rmAreaAddConstraint(cliffID, cliffAvoidContinentEdge);
         rmAreaAddConstraint(cliffID, cliffAvoidSelf);
         rmAreaAddConstraint(cliffID, cliffAvoidCenter);
         rmAreaAddConstraint(cliffID, cliffAvoidBuildings);
         rmAreaAddConstraint(cliffID, cliffAvoidRelicPathArea);
         rmAreaAddOriginConstraint(cliffID, cliffForceInTeamArea);
         rmAreaSetOriginConstraintBuffer(cliffID, 10.0);
         rmAreaAddToClass(cliffID, cliffClassID);
         rmAreaAddToClass(cliffID, innerCliffID);

         rmAreaBuild(cliffID);
      }
   }

   // Create some outside embellishment mountains.
   int sideMountainClassID = rmClassCreate();
   int sideMountainAvoidSelf = rmCreateClassDistanceConstraint(sideMountainClassID, 1.0);
   int sideMountainAvoidContinent = rmCreateClassDistanceConstraint(cliffBlendClassID, 10.0);

   for(int i = 0; i < 2; i++)
   {
      for(int j = 0; j < 2; j++)
      {
         int sideMountainID = rmAreaCreate("side mountain " + i + " " + j);
         rmAreaSetLoc(sideMountainID, vectorXZ(i, j));
         rmAreaSetSize(sideMountainID, 1.0);

         rmAreaSetHeight(sideMountainID, xsRandFloat(15.0, 25.0));
         rmAreaSetHeightNoise(sideMountainID, cNoiseFractalSum, 60.0, 0.05, 5, 0.5);
         rmAreaAddHeightBlend(sideMountainID, cBlendAll, cFilter5x5Box, 2, 2);

         rmAreaSetCliffType(sideMountainID, cCliffHadesDirt);
         rmAreaSetCliffPaintInsideAsSide(sideMountainID, true);
         rmAreaSetCliffLayerPaint(sideMountainID, cCliffLayerOuterSideClose, false);
         rmAreaSetCliffLayerPaint(sideMountainID, cCliffLayerOuterSideFar, false);

         rmAreaAddToClass(sideMountainID, sideMountainClassID);
         rmAreaAddConstraint(sideMountainID, sideMountainAvoidSelf);
         rmAreaAddConstraint(sideMountainID, sideMountainAvoidContinent, 0.0, 20.0);
      }
   }

   rmAreaBuildAll();

   rmSetProgress(0.4);

   // Let everything avoid the center.
   int resAvoidCenter = rmCreateAreaDistanceConstraint(centerID, 10.0);

   rmSetProgress(0.5);

   // Gold.
   float avoidGoldMeters = 50.0;
   
   int avoidRelicArea = rmCreateClassDistanceConstraint(relicAreaClassID, 1.0);

   int goldID = rmObjectDefCreate("gold");
   rmObjectDefAddItem(goldID, cUnitTypeMineGoldLarge, 1);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidAll);
   rmObjectDefAddConstraint(goldID, vDefaultGoldAvoidImpassableLand);
   rmObjectDefAddConstraint(goldID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeGoldID, vDefaultAvoidCorner40);   
   rmObjectDefAddConstraint(closeGoldID, resAvoidCenter);  
   rmObjectDefAddConstraint(goldID, avoidRelicArea);
   addObjectLocsAtOrigin(goldID, xsRandInt(4, 5) * getMapAreaSizeFactor() * cNumberPlayers , cCenterLoc,
                         0.0, continentRadiusMeters, avoidGoldMeters);

   generateLocs("gold locs");

   // Hunt.
   float avoidHuntMeters = 30.0;

   // Close hunt.
   int closeHuntID = rmObjectDefCreate("close hunt");
   rmObjectDefAddItem(closeHuntID, cUnitTypeDeer, xsRandInt(5, 9));
   rmObjectDefAddConstraint(closeHuntID, resAvoidCenter);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(closeHuntID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHuntID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(closeHuntID, avoidRelicArea);
   addObjectDefPlayerLocConstraint(closeHuntID, 60.0);
   if(gameIs1v1() == true)
   {
      addSimObjectLocsPerPlayerPair(closeHuntID, false, 2, 60.0, 90.0, avoidHuntMeters);
   }
   else
   {
      addObjectLocsPerPlayer(closeHuntID, false, 2, 60.0, 90.0, avoidHuntMeters);
   }

   generateLocs("hunt locs");

   rmSetProgress(0.6);
   
   // Berries.
   float avoidBerriesMeters = 50.0;

   int bonusBerriesID = rmObjectDefCreate("bonus berries");
   rmObjectDefAddItem(bonusBerriesID, cUnitTypeBerryBush, xsRandInt(7, 9), cBerryClusterRadius);
   rmObjectDefAddConstraint(bonusBerriesID, resAvoidCenter);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultBerriesAvoidAll);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultBerriesAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusBerriesID, vDefaultAvoidSettlementRange);
   rmObjectDefAddConstraint(bonusBerriesID, avoidRelicArea);
   addObjectDefPlayerLocConstraint(bonusBerriesID, 70.0);
   addObjectLocsPerPlayer(bonusBerriesID, false, 2 * getMapAreaSizeFactor(), 70.0, -1.0, avoidBerriesMeters);

   generateLocs("berries locs");

   // Herdables.
   float avoidHerdMeters = 50.0;

   int closeHerdID = rmObjectDefCreate("close herd");
   rmObjectDefAddItem(closeHerdID, cUnitTypeGoat, xsRandInt(2, 3));
   rmObjectDefAddConstraint(closeHerdID, resAvoidCenter);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(closeHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(closeHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(closeHerdID, avoidRelicArea);
   addObjectLocsPerPlayer(closeHerdID, false, 1, 50.0, 70.0, avoidHerdMeters);

   int bonusHerdID = rmObjectDefCreate("bonus herd");
   rmObjectDefAddItem(bonusHerdID, cUnitTypeGoat, xsRandInt(1, 2));
   rmObjectDefAddConstraint(bonusHerdID, resAvoidCenter);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidAll);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultHerdAvoidImpassableLand);
   rmObjectDefAddConstraint(bonusHerdID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(bonusHerdID, avoidRelicArea);
   addObjectLocsPerPlayer(bonusHerdID, false, xsRandInt(1, 2) * getMapSizeBonusFactor(), 70.0, -1.0, avoidHerdMeters);

   generateLocs("herd locs");

   // Predators.
   float avoidPredatorMeters = 50.0;

   int predatorID = rmObjectDefCreate("predator");
   if(xsRandBool(0.5) == true)
   {
      rmObjectDefAddItem(predatorID, cUnitTypeAurochs, xsRandInt(2, 3));
   }
   else
   {
      rmObjectDefAddItem(predatorID, cUnitTypeBoar, xsRandInt(1, 2));
   }
   rmObjectDefAddConstraint(predatorID, resAvoidCenter);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidAll);
   rmObjectDefAddConstraint(predatorID, vDefaultFoodAvoidImpassableLand);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidTowerLOS);
   rmObjectDefAddConstraint(predatorID, vDefaultAvoidSettlementRange);
   addObjectDefPlayerLocConstraint(predatorID, 80.0);
   addObjectLocsPerPlayer(predatorID, false, xsRandInt(1, 2) * getMapAreaSizeFactor(), 80.0, -1.0, avoidPredatorMeters);

   generateLocs("predator locs");

   // Stragglers.
   placeStartingStragglers(cUnitTypeTreeHades);

   rmSetProgress(0.6);

   // Forests.
   int forestClassID = rmClassCreate();
   int forestAvoidCenter = rmCreateAreaDistanceConstraint(centerID, 1.0);
   int forestAvoidForest = rmCreateClassDistanceConstraint(forestClassID, 24.0);

   float avoidForestMeters = 25.0;

   // Starting forests.
   // Edge forests.
   int edgeForestDefID = rmAreaDefCreate("edge forest");
   rmAreaDefSetSizeRange(edgeForestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(100));
   rmAreaDefSetForestType(edgeForestDefID, forestTypeID);
   rmAreaDefSetBlobs(edgeForestDefID, 2, 5);
   rmAreaDefSetBlobDistance(edgeForestDefID, 10.0);
   rmAreaDefAddToClass(edgeForestDefID, forestClassID);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultAvoidAll8);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultForestAvoidTownCenter);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultAvoidSettlementWithFarm);
   rmAreaDefAddConstraint(edgeForestDefID, vDefaultAvoidImpassableLand);
   rmAreaDefAddConstraint(edgeForestDefID, forestAvoidCenter);
   rmAreaDefAddConstraint(edgeForestDefID, forestAvoidForest);
   rmAreaDefAddConstraint(edgeForestDefID, rmCreateClassDistanceConstraint(relicAreaClassID, 1.0));
   rmAreaDefAddConstraint(edgeForestDefID, rmCreateClassDistanceConstraint(innerCliffID, 15.0));
   rmAreaDefAddConstraint(edgeForestDefID, rmCreatePassabilityMaxDistanceConstraint(cPassabilityLand, false, 8.0));
   addAreaLocsPerPlayer(edgeForestDefID, 8 * getMapAreaSizeFactor(), 0.0, -1.0, avoidForestMeters);

   // Main forests.
   float avoidForestMeters = 35.0;

   int forestDefID = rmAreaDefCreate("forest");
   rmAreaDefSetSizeRange(forestDefID, rmTilesToAreaFraction(50), rmTilesToAreaFraction(80));
   rmAreaDefSetForestType(forestDefID, forestTypeID);
   rmAreaDefSetAvoidSelfDistance(forestDefID, avoidForestMeters);
   rmAreaDefAddConstraint(forestDefID, vDefaultForestAvoidAll);
   rmAreaDefAddConstraint(forestDefID, forestAvoidCenter);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidImpassableLand8);
   rmAreaDefAddConstraint(forestDefID, vDefaultAvoidSettlementWithFarm);

   rmAreaDefCreateAndBuildAreas(forestDefID, 8 * cNumberPlayers * getMapAreaSizeFactor());

   // Outer forests.

   generateLocs("forest locs");

   rmSetProgress(0.8);

// Starting units.
   // Greek.
   int greekVillagerID = rmObjectDefCreate("greek villager");
   rmObjectDefAddItem(greekVillagerID, cUnitTypeVillagerGreek, 1);
   rmObjectDefAddConstraint(greekVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(greekVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(greekVillagerID, vDefaultAvoidWater8);

   // Egyptian.
   int eggyVillagerID = rmObjectDefCreate("egyptian villager");
   rmObjectDefAddItem(eggyVillagerID, cUnitTypeVillagerEgyptian, 1);
   rmObjectDefAddConstraint(eggyVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(eggyVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(eggyVillagerID, vDefaultAvoidWater8);

   // Norse.
   int norseBerserkID = rmObjectDefCreate("norse berserk");
   rmObjectDefAddItem(norseBerserkID, cUnitTypeBerserk, 1);
   rmObjectDefAddConstraint(norseBerserkID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseBerserkID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseBerserkID, vDefaultAvoidWater8);

   int norseVillagerID = rmObjectDefCreate("norse gatherer");
   rmObjectDefAddItem(norseVillagerID, cUnitTypeVillagerNorse, 1);
   rmObjectDefAddConstraint(norseVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseVillagerID, vDefaultAvoidWater8);

   int norseDwarfID = rmObjectDefCreate("norse dwarf");
   rmObjectDefAddItem(norseDwarfID, cUnitTypeVillagerDwarf, 1);
   rmObjectDefAddConstraint(norseDwarfID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseDwarfID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseDwarfID, vDefaultAvoidWater8);

   int norseOxCartID = rmObjectDefCreate("norse oxcart");
   rmObjectDefAddItem(norseOxCartID, cUnitTypeOxCart, 1);
   rmObjectDefAddConstraint(norseOxCartID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(norseOxCartID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(norseOxCartID, vDefaultAvoidWater8);

   // Atty.
   int attyVillagerID = rmObjectDefCreate("atlantean villager");
   rmObjectDefAddItem(attyVillagerID, cUnitTypeVillagerAtlantean, 1);
   rmObjectDefAddConstraint(attyVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(attyVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(attyVillagerID, vDefaultAvoidWater8);

   // Gaia.
   int attyVillagerHeroID = rmObjectDefCreate("atlantean villager hero");
   rmObjectDefAddItem(attyVillagerHeroID, cUnitTypeVillagerAtlanteanHero, 1);
   rmObjectDefAddConstraint(attyVillagerHeroID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(attyVillagerHeroID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(attyVillagerHeroID, vDefaultAvoidWater8);

   // Chinese.
   int chineseVillagerID = rmObjectDefCreate("chinese villager");
   rmObjectDefAddItem(chineseVillagerID, cUnitTypeVillagerChinese, 1);
   rmObjectDefAddConstraint(chineseVillagerID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(chineseVillagerID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(chineseVillagerID, vDefaultAvoidWater8);

   int chineseKuafuID = rmObjectDefCreate("chinese kuafu");
   rmObjectDefAddItem(chineseKuafuID, cUnitTypeKuafu, 1);
   rmObjectDefAddConstraint(chineseKuafuID, vDefaultAvoidAll8);
   rmObjectDefAddConstraint(chineseKuafuID, vDefaultAvoidImpassableLand4);
   rmObjectDefAddConstraint(chineseKuafuID, vDefaultAvoidWater8);

   // Placement radius.
   float startingUnitPlacementRadiusMeters = 65.0;
   float startingUnitDist = 40.0;

   // Place and adjust starting res.
   for(int i = 1; i <= cNumberPlayers; i++)
   {
      int p = vDefaultTeamPlayerOrder[i];
      int culture = rmGetPlayerCulture(p);

      if(culture == cCultureGreek)
      {
         addObjectLocsForPlayer(greekVillagerID, true, p, 4, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         rmAddPlayerResource(p, cResourceWood, 350);
         rmAddPlayerResource(p, cResourceGold, 350);
      }
      else if(culture == cCultureEgyptian)
      {
         addObjectLocsForPlayer(eggyVillagerID, true, p, 3, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         rmAddPlayerResource(p, cResourceGold, 550);
      }
      else if(culture == cCultureNorse)
      {
         addObjectLocsForPlayer(norseBerserkID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         addObjectLocsForPlayer(norseOxCartID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         if(rmGetPlayerCiv(p) == cCivThor)
         {
            addObjectLocsForPlayer(norseDwarfID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
         }
         else
         {
            addObjectLocsForPlayer(norseVillagerID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
         }
         rmAddPlayerResource(p, cResourceWood, 350);
         rmAddPlayerResource(p, cResourceGold, 350);
      }
      else if(culture == cCultureAtlantean)
      {
         if(rmGetPlayerCiv(p) == cCivGaia)
         {
            addObjectLocsForPlayer(attyVillagerHeroID, true, p, 2, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
            rmAddPlayerResource(p, cResourceWood, 350);
            rmAddPlayerResource(p, cResourceGold, 350);
         }
         else
         {
            addObjectLocsForPlayer(attyVillagerID, true, p, 2, 0.0, startingUnitPlacementRadiusMeters,
                                   startingUnitDist, cBiasNone, cInAreaNone);
            rmAddPlayerResource(p, cResourceWood, 350);
            rmAddPlayerResource(p, cResourceGold, 350);
         }
      }
      else if(culture == cCultureChinese)
      {
         addObjectLocsForPlayer(chineseVillagerID, true, p, 2, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         addObjectLocsForPlayer(chineseKuafuID, true, p, 1, 0.0, startingUnitPlacementRadiusMeters,
                                startingUnitDist, cBiasNone, cInAreaNone);
         rmAddPlayerResource(p, cResourceWood, 350);
         rmAddPlayerResource(p, cResourceGold, 350);
      }
      else
      {
         rmEchoError("Invalid culture!");
      }
   }

   generateLocs("starting units");

   // Embellishment.
   // Gold areas.
//   buildAreaUnderObjectDef(startingGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 8.0);
//   buildAreaUnderObjectDef(closeGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 8.0);
//   buildAreaUnderObjectDef(bonusGoldID, cTerrainHadesDirtRocks2, cTerrainHadesDirtRocks1, 8.0);

   // Berries areas.
//   buildAreaUnderObjectDef(startingBerriesID, cTerrainHadesDirt1, cTerrainHadesDirt1, 10.0);
//   buildAreaUnderObjectDef(bonusBerriesID, cTerrainHadesDirt1, cTerrainHadesDirt1, 10.0);

   // Torches.
   buildAreaUnderObjectDef(centerTorchID, cTerrainHadesRoad1, cTerrainHadesRoad2, 2.0);

   rmSetProgress(0.9);

   // Random trees.
   int randomTreeID = rmObjectDefCreate("random tree");
   rmObjectDefAddItem(randomTreeID, cUnitTypeTreePineDead, 1);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidAll);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidCollideable);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidImpassableLand);
   rmObjectDefAddConstraint(randomTreeID, vDefaultTreeAvoidTree);
   rmObjectDefAddConstraint(randomTreeID, vDefaultAvoidSettlementWithFarm);
   rmObjectDefPlaceAnywhere(randomTreeID, 0, 5 * cNumberPlayers * getMapAreaSizeFactor());

   // Rocks.
   int rockTinyID = rmObjectDefCreate("rock tiny");
   rmObjectDefAddItem(rockTinyID, cUnitTypeRockHadesTiny, 1);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockTinyID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockTinyID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   int rockSmallID = rmObjectDefCreate("rock small");
   rmObjectDefAddItem(rockSmallID, cUnitTypeRockHadesSmall, 1);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(rockSmallID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(rockSmallID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   int stalagmiteID = rmObjectDefCreate("stalagmite");
   rmObjectDefAddItem(stalagmiteID, cUnitTypeStalagmite, 1);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(stalagmiteID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(stalagmiteID, 0, 30 * cNumberPlayers * getMapAreaSizeFactor());

   // Plants.
   int plantBushID = rmObjectDefCreate("plant bush");
   rmObjectDefAddItem(plantBushID, cUnitTypePlantHadesBush, 1);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantBushID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantBushID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantFernID = rmObjectDefCreate("plant fern");
   rmObjectDefAddItem(plantFernID, cUnitTypePlantHadesFern, 1);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantFernID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantFernID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());
   
   int plantWeedsID = rmObjectDefCreate("plant weeds");
   rmObjectDefAddItem(plantWeedsID, cUnitTypePlantHadesWeeds, 1);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidAll);
   rmObjectDefAddConstraint(plantWeedsID, vDefaultEmbellishmentAvoidImpassableLand);
   rmObjectDefPlaceAnywhere(plantWeedsID, 0, 15 * cNumberPlayers * getMapAreaSizeFactor());

   // Birbs.
   int birdID = rmObjectDefCreate("bird");
   rmObjectDefAddItem(birdID, cUnitTypeHarpy, 1);
   rmObjectDefPlaceAnywhere(birdID, 0, 2 * cNumberPlayers * getMapAreaSizeFactor());

   rmSetProgress(1.0);

   generateTriggers();
}
