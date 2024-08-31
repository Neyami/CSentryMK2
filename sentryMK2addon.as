//include custom weapon scripts here
#include "../custom_weapons/cso/csobaseweapon"
#include "../custom_weapons/cso/csocommon"
#include "../custom_weapons/weapon_redeemer"
#include "../custom_weapons/cso/weapon_m95tiger"
#include "../custom_weapons/cso/weapon_plasmagun"

namespace SentryMK2
{

bool g_bEnableCustomWeaponsForMK2Sentry = true;

enum e_customweapons
{
	W_REDEEMER = 27,
	W_M95TIGER,
	W_PLASMAGUN
};

void CustomWeaponFire( int iWeapon, EHandle &in hSentry, Vector vecSrc, Vector vecDirToEnemy, float &out flNextFire )
{
	if( !hSentry.IsValid() )
	{
		flNextFire = g_Engine.time + 0.5;

		return;
	}

	CSentryMK2@ pSentry = cast<CSentryMK2@>(CastToScriptClass(hSentry.GetEntity()));

	switch( iWeapon )
	{
		case W_REDEEMER:
		{
			Redeemer::ShootNuke( pSentry.pev, vecSrc + g_Engine.v_forward * 32 + g_Engine.v_up * 2 + g_Engine.v_right * -2, g_Engine.v_forward * 1500, false );
			g_SoundSystem.EmitSound( pSentry.self.edict(), CHAN_WEAPON, Redeemer::REDEEMER_SOUND_FIRE, VOL_NORM, ATTN_NORM );

			flNextFire = g_Engine.time + 3.6;

			break;
		}

		case W_M95TIGER:
		{
			pSentry.MyFireBullets( pSentry.self, 1, vecSrc, vecDirToEnemy, VECTOR_CONE_1DEGREES, pSentry.GetRange(), BULLET_PLAYER_SNIPER, cso_m95tiger::CSOW_DAMAGE );
			g_SoundSystem.EmitSoundDyn( pSentry.self.edict(), CHAN_WEAPON, cso_m95tiger::pCSOWSounds[cso_m95tiger::SND_SHOOT], VOL_NORM, ATTN_NORM, 0, 94 + Math.RandomLong(0, 15) );

			flNextFire = g_Engine.time + cso_m95tiger::CSOW_TIME_DELAY1;

			break;
		}

		case W_PLASMAGUN:
		{
			vecSrc.z += 16.0;
			CBaseEntity@ pPlasma = g_EntityFuncs.Create( "plasmaball", vecSrc, vecDirToEnemy, false, pSentry.self.edict() );
			pPlasma.pev.velocity = g_Engine.v_forward * cso_plasmagun::CSOW_PLASMA_SPEED;

			g_SoundSystem.EmitSound( pSentry.self.edict(), CHAN_WEAPON, cso_plasmagun::pCSOWSounds[cso_plasmagun::SND_SHOOT], 1, ATTN_NORM );

			flNextFire = g_Engine.time + cso_plasmagun::CSOW_TIME_DELAY;

			break;
		}
	}
}

void CheckForCustomWeaponName( int iWeapon, string &out weaponClassname )
{
	switch( iWeapon )
	{
		case W_REDEEMER:
		{
			weaponClassname = "weapon_redeemer";
			break;
		}

		case W_M95TIGER:
		{
			weaponClassname = "weapon_m95tiger";
			break;
		}

		case W_PLASMAGUN:
		{
			weaponClassname = "weapon_plasmagun";
			break;
		}
	}
}

int CheckForCustomWeapon( CBaseEntity@ pSentry, CBasePlayerWeapon@ pWeapon, Vector vecOrigin, Vector vecAngles )
{
	if( pWeapon.GetClassname() == "weapon_redeemer" )
		return W_REDEEMER;
	if( pWeapon.GetClassname() == "weapon_m95tiger" )
	{
		CreateWeaponModel( pSentry, W_M95TIGER, vecOrigin, vecAngles );
		return W_M95TIGER;
	}
	if( pWeapon.GetClassname() == "weapon_plasmagun" )
	{
		CreateWeaponModel( pSentry, W_PLASMAGUN, vecOrigin, vecAngles );
		return W_PLASMAGUN;
	}
	else
		return W_NONE;
}

void CreateWeaponModel( CBaseEntity@ pSentry, int iWeapon, Vector vecOrigin, Vector vecAngles )
{
		CBaseEntity@ cbeWeaponModel = g_EntityFuncs.Create( "mk2_wmodel", vecOrigin, vecAngles, true, pSentry.edict() );
		mk2_wmodel@ pWeaponModel = cast<mk2_wmodel@>(CastToScriptClass(cbeWeaponModel));
		pWeaponModel.m_hSentry = EHandle( pSentry );
		pWeaponModel.m_iWeapon = iWeapon;
		g_EntityFuncs.DispatchSpawn( pWeaponModel.self.edict() );
}

class mk2_wmodel : ScriptBaseEntity
{
	EHandle m_hSentry;
	int m_iWeapon;

	void Spawn()
	{
		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_NONE;

		switch( m_iWeapon )
		{
			case W_M95TIGER:
			{
				g_EntityFuncs.SetOrigin( self, pev.origin );
				g_EntityFuncs.SetModel( self, cso_m95tiger::MODEL_WORLD );

				pev.origin.z += 48.0;
				pev.angles = Vector( 48.0, 20.0, 63.0 );

				break;
			}

			case W_PLASMAGUN:
			{
				g_EntityFuncs.SetOrigin( self, pev.origin );
				g_EntityFuncs.SetModel( self, cso_plasmagun::MODEL_WORLD );

				pev.origin.z += 48.0;
				pev.angles = Vector( 0.0, 0.0, -90.0 );

				break;
			}
		}
//Itemplacer testing
//g_EntityFuncs.SetModel( self, cso_plasmagun::MODEL_WORLD );
//pev.origin.z += 48.0;

		SetThink( ThinkFunction(this.ModelThink) );
		pev.nextthink = g_Engine.time;
	}

	void ModelThink()
	{
		if( !m_hSentry.IsValid() or m_hSentry.GetEntity().pev.flags & (DEAD_DYING|DEAD_DEAD) != 0 )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		CBaseEntity@ cbeSentry = m_hSentry.GetEntity();
		CSentryMK2@ pSentry = cast<CSentryMK2@>(CastToScriptClass(cbeSentry));

		switch( m_iWeapon )
		{
			case W_M95TIGER:
			{
				pev.angles.y = pSentry.m_vecCurAngles.y + 20.0;

				break;
			}

			case W_PLASMAGUN:
			{
				pev.angles.y = pSentry.m_vecCurAngles.y;

				break;
			}
		}

		pev.nextthink = g_Engine.time;
	}
}

void RegisterCustomWeapons()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "SentryMK2::mk2_wmodel", "mk2_wmodel" );
	g_Game.PrecacheOther( "mk2_wmodel" );
	Redeemer::Register();
	//g_Game.PrecacheOther( "weapon_redeemer" );
	cso_plasmagun::Register();
}

} //namespace SentryMK2 END