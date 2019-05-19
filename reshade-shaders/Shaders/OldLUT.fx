/**
Created by supplient
2019/5/17
Migrate from TuningPalette.fx created by Ganossa for Reshade 2.x
 */

#include "ReShade.fxh"

// -----------------------------------------------

#ifndef TuningColorLUTDstTexture
	#define TuningColorLUTDstTexture "warm.png"
#endif
#ifndef TuningColorLUTTileAmountX
	#define TuningColorLUTTileAmountX 256
#endif
#ifndef TuningColorLUTTileAmountY
	#define TuningColorLUTTileAmountY 16
#endif
#ifndef TuningColorLUTTileAmountZ
	#define TuningColorLUTTileAmountZ 1
#endif

// -----------------------------------------------

uniform float TuningColorLUTIntensityChroma <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "LUT chroma amount";
	ui_tooltip = "Intensity of color/chroma change of the LUT.";
> = 1.00;

uniform float TuningColorLUTIntensityLuma <
	ui_type = "slider";
	ui_min = 0.00; ui_max = 1.00;
	ui_label = "LUT luma amount";
	ui_tooltip = "Intensity of luma change of the LUT.";
> = 1.00;

// -----------------------------------------------

texture ColorLUTDstTex	< source = TuningColorLUTDstTexture; > {Width = TuningColorLUTTileAmountX; Height = TuningColorLUTTileAmountY*TuningColorLUTTileAmountZ; Format = RGBA8;};
sampler	ColorLUTDstColor 	{ Texture = ColorLUTDstTex; };

#define TuningColorLUTNorm float3(1.0/float(TuningColorLUTTileAmountX),1.0/float(TuningColorLUTTileAmountY),1.0/float(TuningColorLUTTileAmountZ))

float4 PS_TuningPalette(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 original = tex2D(ReShade::BackBuffer, texcoord.xy);

	float low = 0;

	float lowLUT = low*8f;

	float4 ColorLUTDst = float4((original.rg*float(TuningColorLUTTileAmountY-1)+0.5f)*TuningColorLUTNorm.xy,original.b*float(TuningColorLUTTileAmountY-1),original.w);
	ColorLUTDst.x += trunc(ColorLUTDst.z)*TuningColorLUTNorm.y;

	ColorLUTDst.y *= TuningColorLUTNorm.z;
	ColorLUTDst.y += trunc(lowLUT* (TuningColorLUTTileAmountZ-1) )*TuningColorLUTNorm.z;
	ColorLUTDst = lerp(tex2D(ColorLUTDstColor, ColorLUTDst.xy),tex2D(ColorLUTDstColor, float2(ColorLUTDst.x+TuningColorLUTNorm.y,ColorLUTDst.y)),frac(ColorLUTDst.z));

	original.xyz = lerp(normalize(original.xyz), normalize(ColorLUTDst.xyz), TuningColorLUTIntensityChroma) *
		       lerp(length(original.xyz),    length(ColorLUTDst.xyz),    TuningColorLUTIntensityLuma);	

	return original;

}

technique OldLUT
{
	pass TuningPalettePass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_TuningPalette;
	}
}