//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_WOTC_SkullJackFeedBackFix.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_WOTC_SkullJackFeedBackFix extends X2DownloadableContentInfo;

var config bool bLogTheSKULLOuchFix, bSKULLOuch_IgnoresShields, bSKULLOuch_IgnoresArmor, bSKULLOuch_IgnoresSustain, bSKULLOuch_Disorients;
var config WeaponDamageValue SKULLOuch_FeedbackDamage;

static event OnLoadedSavedGame(){}

static event InstallNewCampaign(XComGameState StartState){}

///////////////////////////////////////////////////////////////////////////////
//	OPTC
///////////////////////////////////////////////////////////////////////////////
static event OnPostTemplatesCreated()
{
	FixupSkullJackMining();
}

static function FixupSkullJackMining()
{
	local X2AbilityTemplateManager			AbilityMgr;		//holder for all abilities
	local X2AbilityTemplate					Template;		//current things to focus on

	local X2Effect							TempEffect;				//placeholder for Effects
	local X2Effect_ApplyWeaponDamage        WeaponDamageEffect;
	local X2Effect_PersistentStatChange		DisorientedEffect;

	//Karen !! Calling the manager
	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Template = AbilityMgr.FindAbilityTemplate('SKULLOuch');
	if (Template != none)
	{
		foreach Template.AbilityTargetEffects( TempEffect ) 
		{
			if (X2Effect_ApplyWeaponDamage  (TempEffect) != none )
			{
				WeaponDamageEffect = X2Effect_ApplyWeaponDamage(TempEffect);
				WeaponDamageEffect.EffectDamageValue = default.SKULLOuch_FeedbackDamage;
				WeaponDamageEffect.bBypassShields = default.bSKULLOuch_IgnoresShields;
				WeaponDamageEffect.bIgnoreArmor = default.bSKULLOuch_IgnoresArmor;
				WeaponDamageEffect.bBypassSustainEffects = default.bSKULLOuch_IgnoresSustain;
			}
		}

		if (default.bSKULLOuch_Disorients)
		{
			DisorientedEffect = class'X2StatusEffects'.static.CreateDisorientedStatusEffect(false,0.0f,false);
			DisorientedEffect.iNumTurns = 2;
			Template.AddTargetEffect(DisorientedEffect);
		}

		Template.BuildNewGameStateFn = SkulljackFeedback_BuildGameState;

		`log("Skullmining feedback ability patched!", default.bLogTheSKULLOuchFix, 'WOTC_SkulljackFix');

	}
}

static function XComGameState SkulljackFeedback_BuildGameState(XComGameStateContext Context)
{
	local XComGameState NewGameState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;

	//build the gamestate like any normal ability
	NewGameState = class'X2Ability'.static.TypicalAbility_BuildGameState(Context);
	
	//ensure we have the correct context
	AbilityContext = XComGameStateContext_Ability(Context);
	
	//get the correct unit
	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	if (UnitState == none)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', AbilityContext.InputContext.SourceObject.ObjectID));
	}

	//remove the ability context from the unit, and thus removes the repeating damage effect
	UnitState.Abilities.RemoveItem(AbilityContext.InputContext.AbilityRef);
	
	//NotRequired using newer 'modify' instead of this older method
	//NewGameState.AddStateObject(UnitState);

	return NewGameState;
}
