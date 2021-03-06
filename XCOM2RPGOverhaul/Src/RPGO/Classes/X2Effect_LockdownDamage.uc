//--------------------------------------------------------------------------------------- 
//  FILE:    X2Effect_LockdownDamage
//  AUTHOR:  John Lumpkin (Pavonis Interactive)
//  PURPOSE: Sets up to hit bonuses for Lockdown
//---------------------------------------------------------------------------------------
class X2Effect_LockdownDamage extends X2Effect_ModifyReactionFire config (RPG);

var config int LOCKDOWN_TOHIT_BONUS;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
    local XComGameState_Item SourceWeapon;
    local ShotModifierInfo ShotInfo;

	if(	AbilityState.GetMyTemplateName() == 'SuppressionShot' ||
		AbilityState.GetMyTemplateName() == 'AreaSuppressionShot_LW')
	{
		SourceWeapon = AbilityState.GetSourceWeapon();    
		if (SourceWeapon != none && Target != none)
		{
			if (Attacker.HasSoldierAbility('Lockdown'))
			{
				ShotInfo.ModType = eHit_Success;
				ShotInfo.Reason = FriendlyName;
				ShotInfo.Value = class'RPGOAbilityConfigManager'.static.GetConfigIntValue("LOCKDOWN_TOHIT_BONUS") / (1-class'X2AbilityToHitCalc_StandardAim'.default.REACTION_FINALMOD);
				ShotModifiers.AddItem(ShotInfo);
			}
        }
    }    
}
