Shader "Hidden/Dotart Effect" {
Properties {
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_DotLength("DotLength", Float) = 4
	_Contrast("Contrast", Float) = 2
	_ColorPrec("ColorPrec", Float) = 12
	_DepthBias("DepthBias", Float) = 0
	_ToneMatch("ToneMatch", Float) = 0
	_ToneBalance("ToneBalance", Float) = -0.5
}

SubShader {
	Pass {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }

		CGPROGRAM
		#pragma target 4.0
		#pragma vertex vert_img
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma multi_compile DOTART_DEPTH_ON DOTART_DEPTH_OFF
		#pragma multi_compile DOTART_CONTRAST_ON DOTART_CONTRAST_OFF
		#pragma multi_compile DOTART_COLLECT_ALL DOTART_COLLECT_TONEONLY DOTART_COLLECT_DARKONLY
		#define DOTART_TARGET_4_0
		#include "DotartEffect.cginc"
		ENDCG
	}
}

SubShader {
	Pass {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }

		CGPROGRAM
		#pragma target 3.0
		#pragma vertex vert_img
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma multi_compile DOTART_DEPTH_ON DOTART_DEPTH_OFF
		#pragma multi_compile DOTART_CONTRAST_ON DOTART_CONTRAST_OFF
		#pragma multi_compile DOTART_COLLECT_ALL DOTART_COLLECT_TONEONLY DOTART_COLLECT_DARKONLY
		#define DOTART_TARGET_3_0
		#include "DotartEffect.cginc"
		ENDCG
	}
}

SubShader {
	Pass {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }

		CGPROGRAM
		#pragma target 2.0
		#pragma vertex vert_img
		#pragma fragment frag
		#pragma fragmentoption ARB_precision_hint_fastest
		#pragma multi_compile DOTART_CONTRAST_ON DOTART_CONTRAST_OFF
		#pragma multi_compile DOTART_COLLECT_ALL DOTART_COLLECT_TONEONLY DOTART_COLLECT_DARKONLY
		#define DOTART_TARGET_2_0
		#define DOTART_DEPTH_OFF
		#include "DotartEffect.cginc"
		ENDCG
	}
}

Fallback off

}