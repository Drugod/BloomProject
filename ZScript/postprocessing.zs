/*
 * Copyright (c) 2018-2020 AFADoomer
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

class BloomPPShaderHandler : StaticEventHandler
{
	
	//===========================================================================
	// HEAT EFFECT EVENTHANDLERS
	//===========================================================================
	
	override void RenderOverlay(RenderEvent e)
	{
		PlayerInfo p = players[consoleplayer];
		ThinkerIterator shaderIter = ThinkerIterator.Create("ShaderControl");

		ShaderControl shaderControl;

		while (shaderControl = ShaderControl(shaderIter.Next()))
		{
			if (shaderControl.Owner && shaderControl.Owner == p.mo) {
				//Console.Printf("Shader: %s", shaderControl.ShaderToControl);
				if (shaderControl.amount >= 2)
				{
					Shader.SetUniform1f(p, shaderControl.ShaderToControl, "timer", gametic + e.FracTic);
					Shader.SetUniform1f(p, shaderControl.ShaderToControl, "amount", shaderControl.amount - 1);
					Shader.SetUniform1f(p, shaderControl.ShaderToControl, "alpha", shaderControl.alpha);
					shaderControl.SetUniforms(p, e);
					Shader.SetEnabled(p, shaderControl.ShaderToControl, true);
				}
				else
				{
					Shader.SetEnabled(p, shaderControl.ShaderToControl, false);
				}
			}
		}
	}

	//===========================================================================
	// PIXEL EATER MOTIONBLUR EVENTHANDLERS
	//===========================================================================
	
	int			pitch, yaw ;
	double		xtravel, ytravel ;
	
	override void PlayerEntered( PlayerEvent e )
	{
		PlayerInfo plr = players[ consoleplayer ];
		if( plr )
		{	
			xtravel = 0 ;
			ytravel = 0 ;
		}
	}
	
	override void WorldTick()
	{
		PlayerInfo	plr = players[ consoleplayer ];
		if( plr && plr.health > 0 && plr.mo && Cvar.GetCVar( "blm_mblur", plr ).GetBool() )
		{
			yaw		= plr.mo.GetPlayerInput( ModInput_Yaw );
			pitch	= -plr.mo.GetPlayerInput( ModInput_Pitch );
		}
	}
	
	override void NetworkProcess( ConsoleEvent e )
	{
		PlayerInfo	plr = players[ consoleplayer ];
		if( plr && plr.mo && e.Name == "liveupdate" )
		{
			double pitchdimin	= 1. - abs( plr.mo.pitch * 1. / 90 );
			double decay		= 1. - Cvar.GetCVar( "blm_mblur_recovery", plr ).GetFloat() * .01 ;
			double amount		= Cvar.GetCVar( "blm_mblur_strength", plr ).GetFloat() * 10. / 32767 * sqrt( pitchdimin );
			xtravel				= xtravel * decay + yaw * amount * .625 ;
			ytravel				= ytravel * decay + pitch * amount ;
			
			if( Cvar.GetCVar( "blm_mblur_autostop", plr ).GetBool() )
			{
				double threshold = Cvar.GetCVar( "blm_mblur_threshold", plr ).GetFloat() * 30 ;
				double recovery2 = 1 - Cvar.GetCVar( "blm_mblur_recovery2", plr ).GetFloat() * .01 ;
				if( abs( yaw )		<= threshold ) xtravel *= recovery2 ;
				if( abs( pitch )	<= threshold ) ytravel *= recovery2 ;
			}
		}
	}
	
	override void UiTick()
	{
		PlayerInfo	plr = players[ consoleplayer ];
		if( plr && plr.mo )
		{
			if( plr.health > 0 && Cvar.GetCVar( "blm_mblur", plr ).GetBool() && !plr.mo.FindInventory("isIntro") )//&& yaw && pitch )
			{
				EventHandler.SendNetworkEvent( "liveupdate" );
				
				int copies			= 1 + Cvar.GetCVar( "blm_mblur_samples", plr ).GetInt() ;
				double increment	= 1. / copies ;
				vector2 travel		= ( xtravel, ytravel ) / screen.getheight() ;
				
				Shader.SetUniform2f( plr, "blm_mblur", "steps", travel * increment );
				Shader.SetUniform1f( plr, "blm_mblur", "samples", copies );
				Shader.SetUniform1f( plr, "blm_mblur", "increment", increment );
				Shader.SetUniform1f( plr, "blm_mblur", "blendmode", Cvar.GetCVar( "blm_mblur_blendmode", plr ).GetInt() );
					
				Shader.SetEnabled( plr, "blm_mblur", true );
			}
			else
			{
				Shader.SetEnabled( plr, "blm_mblur", false );
			}
		}
	}
}