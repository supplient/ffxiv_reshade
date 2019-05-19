/**
Created by supplient
2019/5/17
Migrate from Shared.fx created by CeeJay for Reshade 2.x
 */

#include "ReShade.fxh"

float4 DitherPass( float4 colorInput, float2 tex )
{
  /*-------------.
  | :: Dither :: |
  '-------------*/
/*
  Dither version 1.3.1
  by Christian Cann Schuldt Jensen ~ CeeJay.dk

  Does dithering of the greater than 8-bit per channel precision used in shaders.
  Note that the input from the framebuffer is 8-bit and cannot be dithered down to 8-bit.
  Dithering therefore only works on the effects that SweetFX applies afterwards.
*/
    float3 color = colorInput.rgb;

    float dither_bit  = 8.0;  //Number of bits per channel. Should be 8 for most monitors.

    /*------------------------.
    | :: Ordered Dithering :: |
    '------------------------*/
    //Calculate grid position
    float grid_position = frac( dot(tex,(ReShade::ScreenSize * float2(1.0/16.0,10.0/36.0))) + 0.25 );

    //Calculate how big the shift should be
    float dither_shift = (0.25) * (1.0 / (pow(2,dither_bit) - 1.0));

    //Shift the individual colors differently, thus making it even harder to see the dithering pattern
    float3 dither_shift_RGB = float3(dither_shift, -dither_shift, dither_shift); //subpixel dithering

    //modify shift acording to grid position.
    dither_shift_RGB = lerp(2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position); //shift acording to grid position.

    //shift the color by dither_shift
    color.rgb += dither_shift_RGB;

    colorInput.rgb = color.rgb;

    return colorInput;
}

float4 SharedPass(float2 tex, float4 FinalColor)
{
	FinalColor = DitherPass(FinalColor,tex);

	return FinalColor;
}

float4 SharedWrap(in float4 position : SV_Position, in float2 texcoord : TEXCOORD0) : SV_Target
{
	float3 color = tex2D(ReShade::BackBuffer, texcoord).rgb;

	return SharedPass(texcoord, color.rgbb);
}

technique Dither
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = SharedWrap;
    }
}