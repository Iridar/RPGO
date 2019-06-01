class UIChooseSpecializations extends UIChooseCommodity;

var UIStartingAbilitiesIconList StartingAbilities;
var array<SoldierSpecialization> SpecializationsPool;
var array<SoldierSpecialization> SpecializationsChosen;
var array<int> SelectedItems;

var localized string m_strComplementarySpecializationInfo;

simulated function InitChooseSpecialization(StateObjectReference UnitRef, int MaxSpecs, array<SoldierSpecialization> OwnedSpecs, optional delegate<AcceptAbilities> OnAccept)
{
	super.InitChooseCommoditiesScreen(
		UnitRef,
		MaxSpecs,
		ConvertToCommodities(OwnedSpecs),
		OnAccept
	);

	SpecializationsPool.Length = 0;
	SpecializationsPool = class'X2SoldierClassTemplatePlugin'.static.GetSpecializations();
	CommodityPool = ConvertToCommodities(SpecializationsPool);

	SpecializationsChosen.Length = 0;
	SpecializationsChosen = OwnedSpecs;
	CommoditiesChosen = ConvertToCommodities(SpecializationsChosen);

	PopulateData();

	StartingAbilities = Spawn(class'UIStartingAbilitiesIconList', `HQPRES.m_kAvengerHUD);
	StartingAbilities.InitStartingAbilitiesIconList('SoldierStartingAbilities',, GetUnit());
	StartingAbilities.SetX((Movie.UI_RES_X - StartingAbilities.StartingAbiltiesBG.Width) / 2);
	StartingAbilities.SetY(Movie.UI_RES_Y - 225);
	StartingAbilities.CenterIcons();
	
}

simulated function CloseScreen()
{
	StartingAbilities.Remove();
	super.CloseScreen();
}


simulated function OnContinueButtonClick()
{
	local UIArmory_PromotionHero HeroScreen;

	if (CommoditiesChosen.Length - OwnedItems.Length >= MaxChooseItem)
	{
		OnAllSpecSelected();
		
		CloseScreen();
		HeroScreen = UIArmory_PromotionHero(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory_PromotionHero'));
		if (HeroScreen != none)
		{
			HeroScreen.CycleToSoldier(UnitReference);
		}
	}
	else
	{
		PlayNegativeSound();
	}
}

function bool OnAllSpecSelected()
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	
	UnitState = GetUnit();

	NewGameState=class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Ranking up Unit in chosen specs");

	class'X2SecondWaveConfigOptions'.static.BuildSpecAbilityTree(UnitState, SelectedItems, !`SecondWaveEnabled('RPGOSpecRoulette'), `SecondWaveEnabled('RPGOTrainingRoulette'));
	
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
	UnitState.SetUnitFloatValue('SecondWaveCommandersChoiceSpecChosen', 1, eCleanup_Never);
	
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);

	if (AcceptAbilities != none)
	{
		AcceptAbilities(self);
	}

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Recruit_Soldier");
	
	return true;
}

simulated function array<Commodity> ConvertToCommodities(array<SoldierSpecialization> Specializations)
{
	local SoldierSpecialization Spec;
	local int i;
	local array<Commodity> Commodities;
	local Commodity Comm;
	local X2UniversalSoldierClassInfo Template;

	for (i = 0; i < Specializations.Length; i++)
	{
		Spec = Specializations[i];
		
		Template = class'X2SoldierClassTemplatePlugin'.static.GetSpecializationTemplate(Spec);
		
		Comm.Title = Template.ClassSpecializationTitle;
		Comm.Image = Template.ClassSpecializationIcon;
		Comm.Desc = GetComplementarySpecializationInfo(Template) $ "\n" $
			Template.ClassSpecializationSummary;
		Comm.OrderHours = -1;
		
		//Comm.OrderHours = class'SpecialTrainingUtilities'.static.GetSpecialTrainingDays() * 24;

		Commodities.AddItem(Comm);
	}

	return Commodities;
}

simulated function string GetComplementarySpecializationInfo(X2UniversalSoldierClassInfo Template)
{
	local string Info;
	Info = Template.GetComplementarySpecializationInfo();

	if (Info != "")
	{
		Info = m_strComplementarySpecializationInfo $ "\n" $ Info;
	}

	return Info;
}

simulated function AddToChosenList(int Index)
{
	local array<SoldierSpecialization> ComplementarySpecializations;
	local SoldierSpecialization ComplementarySpecialization;
	
	SelectedItems.AddItem(Index);
	SpecializationsChosen.AddItem(SpecializationsPool[Index]);
	
	ComplementarySpecializations = class'X2SoldierClassTemplatePlugin'.static.GetComplementarySpecializations(
		SpecializationsPool[Index]
	);

	if (ComplementarySpecializations.Length > 0)
	{
		foreach ComplementarySpecializations(ComplementarySpecialization)
		{
			SelectedItems.AddItem(GetSpecIndex(ComplementarySpecialization));
			SpecializationsChosen.AddItem(ComplementarySpecialization);
		}
	}

	CommoditiesChosen = ConvertToCommodities(SpecializationsChosen);
}

simulated function RemoveFromChosenList(int ChosenIndex, int PoolIndex)
{
	local array<SoldierSpecialization> ComplementarySpecializations;
	local SoldierSpecialization ComplementarySpecialization;

	SelectedItems.RemoveItem(PoolIndex);
	SpecializationsChosen.RemoveItem(SpecializationsChosen[ChosenIndex]);

	ComplementarySpecializations = class'X2SoldierClassTemplatePlugin'.static.GetComplementarySpecializations(
		SpecializationsPool[PoolIndex]
	);

	if (ComplementarySpecializations.Length > 0)
	{
		foreach ComplementarySpecializations(ComplementarySpecialization)
		{
			SelectedItems.RemoveItem(GetSpecIndex(ComplementarySpecialization));
			SpecializationsChosen.RemoveItem(ComplementarySpecialization);
		}
	}

	CommoditiesChosen = ConvertToCommodities(SpecializationsChosen);
}

simulated function int GetSpecIndex(SoldierSpecialization Spec)
{
	return SpecializationsPool.Find('TemplateName', Spec.TemplateName);
}

defaultproperties
{
	ListItemClass = class'UIInventory_SpecializationListItem'
	ConfirmButtonOffset = 146
}