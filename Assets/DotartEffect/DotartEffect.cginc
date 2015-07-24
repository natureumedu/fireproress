#include "UnityCG.cginc"

//--------------------------------------------------------------------------------------------------------

#ifdef DOTART_DEPTH_ON
#if defined(DOTART_COLLECT_TONEONLY) || defined(DOTART_COLLECT_DARKONLY)
#define _OPTIMIZE_DEPTH_LOOKUP // for ToonBalance only.
#endif
#endif

#ifdef DOTART_COLLECT_ALL
#define _COLLECT_NORMAL
#define _COLLECT_DARK
#define _COLLECT_LIGHT
#define _COLLECT_TOONBALANCE
#endif

#ifdef DOTART_COLLECT_TONEONLY
#define _COLLECT_DARK
#define _COLLECT_LIGHT
#define _COLLECT_TOONBALANCE
#endif

#ifdef DOTART_COLLECT_DARKONLY
#define _COLLECT_DARK
#endif

#define _CLEAR_COLOR float4(0,0,0,0)
//#define _CLEAR_COLOR float4(1,0,0,0)

//--------------------------------------------------------------------------------------------------------

uniform sampler2D _MainTex;
#ifdef DOTART_DEPTH_ON
uniform sampler2D _CameraDepthTexture;
#endif

uniform float _DotLength;
uniform float _Contrast;
uniform float _ColorPrec;
uniform float _DepthBias;
uniform float _ToneMatch;
uniform float _ToneBalance;

#define DOT_LENGTH	_DotLength
#define LUM_TRUNC	_ColorPrec
#define COLOR_TRUNC	_ColorPrec

// Not YUV, YCbCr
#define TO_YUV_MATRIX \
	const float3x3 to_yuv_matrix = float3x3( \
		float3(0.299,       0.587,    0.114), \
		float3(-0.168736,  -0.331264, 0.5), \
		float3(0.5,        -0.418688, -0.081312) \
	);

#define TO_RGB_MATRIX \
	const float3x3 to_rgb_matrix = float3x3( \
		float3(1.0,   0.0,       1.402), \
		float3(1.0,  -0.344136, -0.714136), \
		float3(1.0,   1.772,     0.0) \
	);

// Not YUV, YCbCr
inline float4 to_yuv( float4 c )
{
	TO_YUV_MATRIX;
	c.rgb = mul(to_yuv_matrix, c.rgb);
	return c;
}

inline float4 to_rgb( float4 c )
{
	TO_RGB_MATRIX;
	c.rgb = mul(to_rgb_matrix, c.rgb);
	return c;
}

inline float4 get_baseCol(float2 uv)
{
	float4 col = tex2D(_MainTex, uv);
	#ifdef DOTART_CONTRAST_ON
	col.rgb = clamp((col.rgb - 0.5) * _Contrast, -1.0, 1.0) * 0.5 + 0.5;
	#endif
	return col;
}

#ifdef DOTART_TARGET_3_0
inline float2 step_uv_x(inout float2 uv, float ax)
{
	float2 n = uv;
	uv.x += ax;
	return n;
}

inline void step_uv_y(inout float2 uv, float bx, float ay)
{
	uv.x = bx;
	uv.y += ay;
}
#endif

#ifdef DOTART_DEPTH_ON
inline float get_depth(float2 uv)
{
	return Linear01Depth(tex2D(_CameraDepthTexture, float2(uv.x, 1.0 - uv.y)));
}
#endif

struct COLLECT_COL
{
	#ifdef DOTART_DEPTH_ON
	float	nearDepth;			// 100
	#endif

	#ifdef _COLLECT_TOONBALANCE
	float	toneBalance;		// 0
	#endif

	#ifdef _COLLECT_NORMAL
	float4	averageColor;		// 0,0,0,0
	float	averageCount;		// 0
	float4	normalColor;		// 0,0,0,0
	float	normalLength;		// 100
	#endif

	#ifdef _COLLECT_DARK
	float4	darkColor;			// 0,0,0,0
	float	darkLength;			// 100
	#if defined(DOTART_DEPTH_ON) && defined(_OPTIMIZE_DEPTH_LOOKUP)
	float	darkDepth;			// 100
	#endif
	#endif

	#ifdef _COLLECT_LIGHT
	float4	lightColor;			// 0,0,0,0
	float	lightLength;		// 100
	#if defined(DOTART_DEPTH_ON) && defined(_OPTIMIZE_DEPTH_LOOKUP)
	float	lightDepth;			// 100
	#endif
	#endif
};

#if defined(DOTART_DEPTH_ON) && !defined(_OPTIMIZE_DEPTH_LOOKUP)
inline void near_depth(inout COLLECT_COL collectCol, float2 uv)
{
	collectCol.nearDepth = min(collectCol.nearDepth, get_depth(uv));
}
#endif

#ifdef _COLLECT_NORMAL
inline void average_col(inout COLLECT_COL collectCol, float2 uv)
{
	float4 baseCol = get_baseCol(uv);
	#if defined(DOTART_DEPTH_ON) && !defined(_OPTIMIZE_DEPTH_LOOKUP)
	float newDepth = get_depth(uv);
	float newDepthSign = step(newDepth - collectCol.nearDepth, _DepthBias);
	collectCol.averageColor += baseCol * newDepthSign;
	collectCol.averageCount += newDepthSign;
	#else
	collectCol.averageColor += baseCol;
	collectCol.averageCount += 1;
	#endif
}
#endif

inline void collect_col(inout COLLECT_COL collectCol, float2 uv)
{
	// Collect depth.
	#ifdef DOTART_DEPTH_ON
	float newDepth = get_depth(uv);
	#ifdef _OPTIMIZE_DEPTH_LOOKUP
	collectCol.nearDepth = min(collectCol.nearDepth, newDepth);
	#endif
	float newDepthSign = step(newDepth - collectCol.nearDepth, _DepthBias);
	#endif

	// Color reduction.
	float4 baseCol = get_baseCol(uv);
	float4 newCol = to_yuv(baseCol);
	// 1st pass: Reduction Y in YCbCr.
	newCol.r = round(newCol.r * LUM_TRUNC) / LUM_TRUNC;
	float newColY = newCol.r;
	newCol = to_rgb(newCol);
	// 2nd pass: Reduction RGB.
	newCol = round(newCol * COLOR_TRUNC) / COLOR_TRUNC;

	#ifdef _COLLECT_TOONBALANCE
	#ifdef DOTART_DEPTH_ON
	collectCol.toneBalance += (newColY - 0.5 + _ToneBalance) * newDepthSign;
	#else
	collectCol.toneBalance += newColY - 0.5 + _ToneBalance;
	#endif
	#endif

	// Compute darkLength / lightLength	

	// Re compare darkDepth / lightDepth
	// 1 ... Range out. / 0 ... Range in.

	#ifdef _COLLECT_DARK
	float newDarkLength		= newColY;
	float newDarkSign		= step(newDarkLength, collectCol.darkLength);
	#ifdef DOTART_DEPTH_ON
	#ifdef _OPTIMIZE_DEPTH_LOOKUP
	float darkDepthSign		= step(_DepthBias, collectCol.darkDepth - collectCol.nearDepth);
	float newDarkRate		= sign(newDarkSign + darkDepthSign) * newDepthSign;
	collectCol.darkDepth	= lerp(collectCol.darkDepth,	newDepth,		newDarkRate);
	#else
	float newDarkRate		= newDarkSign * newDepthSign;
	#endif
	#else
	float newDarkRate		= newDarkSign;
	#endif
	collectCol.darkColor	= lerp(collectCol.darkColor,	newCol,			newDarkRate);
	collectCol.darkLength	= lerp(collectCol.darkLength,	newDarkLength,	newDarkRate);
	#endif

	#ifdef _COLLECT_LIGHT
	float newLightLength	= -newColY;
	float newLightSign		= step(newLightLength, collectCol.lightLength);
	#ifdef DOTART_DEPTH_ON
	#ifdef _OPTIMIZE_DEPTH_LOOKUP
	float lightDepthSign	= step(_DepthBias, collectCol.lightDepth - collectCol.nearDepth);
	float newLightRate		= sign(newLightSign + lightDepthSign) * newDepthSign;
	collectCol.lightDepth	= lerp(collectCol.lightDepth,	newDepth,		newLightRate);
	#else
	float newLightRate		= newLightSign * newDepthSign;
	#endif
	#else
	float newLightRate		= newLightSign;
	#endif
	collectCol.lightColor	= lerp(collectCol.lightColor,	newCol,			newLightRate);
	collectCol.lightLength	= lerp(collectCol.lightLength,	newLightLength,	newLightRate);
	#endif

	#ifdef _COLLECT_NORMAL
	float3 t				= abs(collectCol.averageColor.rgb - newCol.rgb);
	float newNormalLength	= t.r + t.g + t.b;
	float newNormalSign		= step(newNormalLength, collectCol.normalLength);
	#if defined(DOTART_DEPTH_ON) && !defined(_OPTIMIZE_DEPTH_LOOKUP)
	float newNormalRate		= newNormalSign * newDepthSign;
	#else
	float newNormalRate		= newNormalSign;
	#endif
	collectCol.normalColor	= lerp(collectCol.normalColor,	newCol,			newNormalRate);
	collectCol.normalLength	= lerp(collectCol.normalLength,	newNormalLength,newNormalRate);
	#endif
}

fixed4 frag (v2f_img i) : COLOR
{
	//fixed4 original = tex2D(_MainTex, i.uv);
	
	float4 screenParamsInv = 1.0 / _ScreenParams;
	float2 screenScale = _ScreenParams.xy / DOT_LENGTH;
	float2 baseUV = round(i.uv * screenScale) / screenScale;

	COLLECT_COL collectCol;
	#ifdef DOTART_DEPTH_ON
	collectCol.nearDepth = 100;
	#endif
	#ifdef _COLLECT_TOONBALANCE
	collectCol.toneBalance = 0;
	#endif
	#ifdef _COLLECT_NORMAL
	collectCol.averageColor = float4(0,0,0,0);
	collectCol.averageCount = 0;
	collectCol.normalColor = _CLEAR_COLOR;
	collectCol.normalLength = 100;
	#endif
	#ifdef _COLLECT_DARK
	collectCol.darkColor = _CLEAR_COLOR;
	collectCol.darkLength = 100;
	#if defined(DOTART_DEPTH_ON) && defined(_OPTIMIZE_DEPTH_LOOKUP)
	collectCol.darkDepth = 100;
	#endif
	#endif
	#ifdef _COLLECT_LIGHT
	collectCol.lightColor = _CLEAR_COLOR;
	collectCol.lightLength = 100;
	#if defined(DOTART_DEPTH_ON) && defined(_OPTIMIZE_DEPTH_LOOKUP)
	collectCol.lightDepth = 100;
	#endif
	#endif

	#ifdef DOTART_TARGET_4_0
	float2 newUV;
	#if defined(DOTART_DEPTH_ON) && !defined(_OPTIMIZE_DEPTH_LOOKUP)
	newUV = baseUV;
	for(int x = 0; x < DOT_LENGTH; ++x) {
		newUV.x = baseUV.x;
		for(int y = 0; y < DOT_LENGTH; ++y) {
			near_depth(collectCol, newUV);
			newUV.x += screenParamsInv.x;
		}
		newUV.y += screenParamsInv.y;
	}
	#endif

	#ifdef _COLLECT_NORMAL
	newUV = baseUV;
	for(int x = 0; x < DOT_LENGTH; ++x) {
		newUV.x = baseUV.x;
		for(int y = 0; y < DOT_LENGTH; ++y) {
			average_col(collectCol, newUV);
			newUV.x += screenParamsInv.x;
		}
		newUV.y += screenParamsInv.y;
	}
	collectCol.averageColor *= (1.0 / collectCol.averageCount);
	#endif
	
	newUV = baseUV;
	for(int x = 0; x < DOT_LENGTH; ++x) {
		newUV.x = baseUV.x;
		for(int y = 0; y < DOT_LENGTH; ++y) {
			collect_col(collectCol, newUV);
			newUV.x += screenParamsInv.x;
		}
		newUV.y += screenParamsInv.y;
	}
	#endif
	
	#ifdef DOTART_TARGET_3_0
	float2 addUV = screenParamsInv * _DotLength * 0.5;
	float2 newUV;
	
	#if defined(DOTART_DEPTH_ON) && !defined(_OPTIMIZE_DEPTH_LOOKUP)
	newUV = baseUV;
	near_depth(collectCol, step_uv_x(newUV, addUV.x));
	near_depth(collectCol, step_uv_x(newUV, addUV.x));
	step_uv_y(newUV, baseUV.x, addUV.y);
	near_depth(collectCol, step_uv_x(newUV, addUV.x));
	near_depth(collectCol, step_uv_x(newUV, addUV.x));
	#endif
	
	#ifdef _COLLECT_NORMAL
	newUV = baseUV;
	average_col(collectCol, step_uv_x(newUV, addUV.x));
	average_col(collectCol, step_uv_x(newUV, addUV.x));
	step_uv_y(newUV, baseUV.x, addUV.y);
	average_col(collectCol, step_uv_x(newUV, addUV.x));
	average_col(collectCol, step_uv_x(newUV, addUV.x));
	#endif
	
	newUV = baseUV;
	collect_col(collectCol, step_uv_x(newUV, addUV.x));
	collect_col(collectCol, step_uv_x(newUV, addUV.x));
	step_uv_y(newUV, baseUV.x, addUV.y);
	collect_col(collectCol, step_uv_x(newUV, addUV.x));
	collect_col(collectCol, step_uv_x(newUV, addUV.x));
	#endif

	#ifdef DOTART_TARGET_2_0
	collect_col(collectCol, baseUV);
	#endif

	#if defined(_COLLECT_DARK) && defined(_COLLECT_LIGHT)
	float4 toneCol = lerp(collectCol.darkColor, collectCol.lightColor, step(0, collectCol.toneBalance));
	#elif defined(_COLLECT_DARK)
	float4 toneCol = collectCol.darkColor;
	#elif defined(_COLLECT_LIGHT)
	float4 toneCol = collectCol.lightColor;
	#endif

	#ifdef _COLLECT_NORMAL
	#if defined(_COLLECT_DARK) || defined(_COLLECT_LIGHT)
	return lerp(collectCol.normalColor, toneCol, step(_ToneMatch,
		abs(collectCol.toneBalance) / collectCol.averageCount));
	#else
	return collectCol.normalColor;
	#endif
	#elif defined(_COLLECT_DARK) || defined(_COLLECT_LIGHT)
	return toneCol;
	#else
	return 0;
	#endif
}
