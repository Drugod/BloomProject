/*
 * Copyright (c) 2021 AFADoomer, Ozymandias81
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
**/

class Buoyancy : Actor
{
	// Modified from AActor::UpdateWaterLevel in p_mobj.cpp (waterlevel variable setting function)
	// Updated to return actual water height value
	static double, bool, Sector GetWaterHeight(Actor mo)
	{
		if (mo.curSector.MoreFlags & Sector.SECMF_UNDERWATER)
		{
			return mo.ceilingz, true, mo.curSector;
		}
		else
		{
			Sector hsec = mo.curSector.GetHeightSec();

			if (hsec)
			{
				if (hsec.MoreFlags & Sector.SECMF_UNDERWATERMASK)
				{
					double fh = hsec.floorplane.ZatPoint(mo.pos.xy);
					double ch = hsec.ceilingplane.ZatPoint(mo.pos.xy);

					if (mo.pos.z < fh)
					{
						return fh, true, hsec;
					}
					else if (!(hsec.MoreFlags & Sector.SECMF_FAKEFLOORONLY) && (mo.pos.z + mo.height > ch))
					{
						return ch, true, hsec;
					}
				}
			}
			else
			{
				for (int i = 0; i < mo.curSector.Get3DFloorCount(); i++)
				{
					F3DFloor f = mo.curSector.Get3DFloor(i);

					if (!(f.flags & F3DFloor.FF_EXISTS)) { continue; }
					if (f.flags & F3DFloor.FF_SOLID) { continue; }
					if (!(f.flags & F3DFloor.FF_SWIMMABLE)) { continue; }

					double ff_bottom = f.bottom.ZatPoint(mo.pos.xy);
					double ff_top = f.top.ZatPoint(mo.pos.xy);

					if (ff_bottom > mo.pos.z + mo.height) continue;

					return ff_top, true, f.model;
				}
			}
		}

		return 0, false, null;
	}
}

mixin class GiveBuoyancy
{
	bool inwater;
	int offset;
	double user_buoyancy;

	Property Buoyancy:user_buoyancy;

	void DoBuoyancy()
	{
		if (!user_buoyancy) { return; }

		if (offset == 0) { offset = Random(-64, 64); }

		bool iswater;
		double waterheight;
		[waterheight, iswater] = Buoyancy.GetWaterHeight(self);

		if (iswater && waterheight > floorz && pos.z < waterheight)
		{
			inwater = true;

			bNoGravity = true;
			bPushable = false;

			double heightoffset = min(abs(user_buoyancy) - 0.05, 0.1) * sin(level.time + offset);
			double waterclip = Default.height * ((1.0 - user_buoyancy) + heightoffset);

			if (waterheight > pos.z + waterclip + 1)
			{
				vel.z = 2.0 * abs(user_buoyancy);
			}
			else
			{
				SetOrigin((pos.xy, max(waterheight - waterclip, floorz)), true);
			}
		}
		else if (inwater)
		{
			inwater = false;

			bNoGravity = Default.bNoGravity;
			bPushable = Default.bPushable;
		}
	}
}

class FloatingModel : Actor
{
	mixin GiveBuoyancy;

	Default
	{
		Height 56;
		+FLOORCLIP
		+DONTSPLASH
		+NOGRAVITY
		FloatingModel.Buoyancy 0.0;
	}

	States
	{
		Spawn:
			UNKN A -1;
			Stop;
	}

	override void Tick()
	{
		Super.Tick();
		DoBuoyancy();
	}
}

class BlooMBase : Actor
{
	bool bird;
	bool fish;
	bool spider;
	int user_count;			//attacks counters
	int user_count2;		//attacks counters
	int user_count3;		//attacks counters
	int user_count4;		//attacks counters

	Property Bird:bird;
	Property Fish:fish;
	Property Spider:spider;

	Default
	{
		-CASTSPRITESHADOW
	}

	States
	{
		Death.Fade:
			"####" # 1 A_FadeOut(0.1);
			Loop;
	}
	
	override void Tick()
	{
	if (fish) // fishes can swim
		{
			double waterheight = Buoyancy.GetWaterHeight(self);
			if (waterheight < pos.z + height + 8)
			{
				bFloat = false;
				vel.z = min(vel.z, -Speed);
			}
			else { bFloat = Default.bFloat; }
		}
		
	if (Default.bFloat && bird) // birds should float but not swim
		{
			if (waterlevel > 0 && health >0) 
			{
				bFloat = false;
				//something must be added here to prevent corpses to continuosly jump
				vel.z = max(vel.z, Speed);
			}
		else { bFloat = Default.bFloat; }
		}
		
	if (Default.Species == "Spiders" && spider) // spiders should not float neither swim
		{
			if (waterlevel > 0 && health >0) 
			{
				//something must be added here to prevent corpses to continuosly jump
				vel.z = max(vel.z, Speed);
			}
		else { Species = Default.Species; }
		}
	
	if (health <= 0 || !bShootable)
		{
			ACS_NamedExecuteAlways("SkyTextureCheck", 0,tid);
		}
		
	Super.Tick();
	}
}