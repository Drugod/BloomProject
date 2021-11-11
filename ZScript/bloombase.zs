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

class BlooMBase : Actor
{
	bool skydeath;
	bool bird;
	bool fish;
	bool spider;
	int user_count;			//attacks counters
	int user_count2;		//attacks counters
	int user_count3;		//attacks counters
	int user_count4;		//attacks counters

	Property SkyDeath:skydeath;
	Property Bird:bird;
	Property Fish:fish;
	Property Spider:spider;

	Default
	{
		-CASTSPRITESHADOW
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
		
		else if (Default.bFloat && bird) // birds should float but not swim
		{
			if (waterlevel > 0) 
			{
				bFloat = false;
				//something must be added here to prevent corpses to continuosly jump
				vel.z = max(vel.z, Speed);
			}
		else { bFloat = Default.bFloat; }
		}
		
		else if (Default.Species == "Spiders" && spider) // spiders should not float neither swim
		{
			if (waterlevel > 0) 
			{
				//something must be added here to prevent corpses to continuosly jump
				vel.z = max(vel.z, Speed);
			}
		else { Species = Default.Species; }
		}
		
	Super.Tick();
	}
	
	state A_SkyCheck() //needs to be worked on --ozy81
	{
		if (skydeath == TRUE) { return ResolveState("Death.Fade"); }
		return ResolveState(null);
	}
	
}