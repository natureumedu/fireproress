using UnityEngine;

[RequireComponent (typeof(Camera))]
[ExecuteInEditMode]
[AddComponentMenu("Image Effects/Dotart")]
public class DotartEffect : MonoBehaviour
{
	public Shader _shader;
	Material _material;
	Camera _camera;

	[Range(1.0f, 32.0f)]
	public float dotLength = 4.0f;
	[Range(-5.0f, 5.0f)]
	public float contrast = 0.0f;
	[Range(1.0f, 32.0f)]
	public float colorPrec = 12.0f;
	[Range(0.0f, 10.0f)]
	public float depthBias = 0.0f;
	[Range(0.0f, 1.0f)]
	public float toneMatch = 1.0f;
	[Range(-1.0f, 1.0f)]
	public float toneBalance = -1.0f;

	bool _initializedMaterial;
	float _cache_dotLength;
	float _cache_contrast;
	float _cache_colorPrec;
	float _cache_depthBias;
	float _cache_toneMatch;
	float _cache_toneBalance;

	Shader shader {
		get {
			if( _shader == null ) {
				_shader = Shader.Find("Hidden/Dotart Effect");
			}

			return _shader;
		}
	}

	void Start()
	{
		if( !SystemInfo.supportsImageEffects ) {
			enabled = false;
			return;
		}

		Shader s = this.shader;
		if( s == null || !s.isSupported ) {
			enabled = false;
		}
	}

	Material material {
		get {
			if( _material == null ) {
				Shader s = this.shader;
				if( s != null ) {
					_material = new Material( shader );
					_material.hideFlags = HideFlags.HideAndDontSave;
				}
			}

			return _material;
		} 
	}

	void OnEnable()
	{
		_initializedMaterial = false;
		_OverrideCameraSetting();
	}

	void OnDisable()
	{
		if( _material != null ) {
			DestroyImmediate( _material );
			_initializedMaterial = false;
		}
	}

	void _OverrideCameraSetting()
	{
		if( this.depthBias > Mathf.Epsilon ) {
			if( _camera == null ) {
				_camera = GetComponent<Camera>();
			}
			if( _camera != null ) {
				if( _camera.depthTextureMode != DepthTextureMode.Depth ) {
					_camera.depthTextureMode = DepthTextureMode.Depth;
				}
			}
		}
	}

	void OnPreRender()
	{
		if( !_initializedMaterial || _cache_depthBias != this.depthBias ) {
			_OverrideCameraSetting();
		}
	}

	void OnRenderImage( RenderTexture source, RenderTexture destination )
	{
		if( source != null ) {
			if( source.filterMode != FilterMode.Point ) {
				source.filterMode = FilterMode.Point;
			}
		}
		if( destination != null ) {
			if( destination.filterMode != FilterMode.Point ) {
				destination.filterMode = FilterMode.Point;
			}
		}

		Material mat = this.material;

		if( mat != null ) {
			if( !_initializedMaterial || _cache_dotLength != this.dotLength ) {
				mat.SetFloat( "_DotLength", this.dotLength );
			}

			if( !_initializedMaterial || _cache_contrast != this.contrast ) {
				mat.SetFloat( "_Contrast", this.contrast + 2.0f );
			}

			if( !_initializedMaterial || _cache_colorPrec != this.colorPrec ) {
				mat.SetFloat( "_ColorPrec", this.colorPrec );
			}

			if( !_initializedMaterial || _cache_toneMatch != this.toneMatch ) {
				mat.SetFloat( "_ToneMatch", (1.0f - this.toneMatch) );
			}

			if( !_initializedMaterial || _cache_toneBalance != this.toneBalance ) {
				mat.SetFloat( "_ToneBalance", this.toneBalance * 0.5f );
			}

			if( !_initializedMaterial || _cache_depthBias != this.depthBias ) {
				mat.SetFloat( "_DepthBias", Mathf.Pow( 0.1f, this.depthBias ) );
				if( this.depthBias > Mathf.Epsilon ) {
					mat.EnableKeyword( "DOTART_DEPTH_ON" );
					mat.DisableKeyword( "DOTART_DEPTH_OFF" );
				} else {
					mat.DisableKeyword( "DOTART_DEPTH_ON" );
					mat.EnableKeyword( "DOTART_DEPTH_OFF" );
				}
			}

			if( !_initializedMaterial || _cache_contrast != this.contrast ) {
				if( Mathf.Abs(this.contrast - 2.0f) > Mathf.Epsilon ) {
					mat.EnableKeyword( "DOTART_CONTRAST_ON" );
					mat.DisableKeyword( "DOTART_CONTRAST_OFF" );
				} else {
					mat.DisableKeyword( "DOTART_CONTRAST_ON" );
					mat.EnableKeyword( "DOTART_CONTRAST_OFF" );
				}
			}

			if( !_initializedMaterial || _cache_toneMatch != this.toneMatch || _cache_toneBalance != this.toneBalance ) {
				if( this.toneMatch >= 1.0f - Mathf.Epsilon ) {
					if( this.toneBalance <= -1.0f + Mathf.Epsilon ) {
						mat.DisableKeyword( "DOTART_COLLECT_ALL" );
						mat.DisableKeyword( "DOTART_COLLECT_TONEONLY" );
						mat.EnableKeyword( "DOTART_COLLECT_DARKONLY" );
					} else {
						mat.DisableKeyword( "DOTART_COLLECT_ALL" );
						mat.EnableKeyword( "DOTART_COLLECT_TONEONLY" );
						mat.DisableKeyword( "DOTART_COLLECT_DARKONLY" );
					}
				} else {
					mat.EnableKeyword( "DOTART_COLLECT_ALL" );
					mat.DisableKeyword( "DOTART_COLLECT_TONEONLY" );
					mat.DisableKeyword( "DOTART_COLLECT_DARKONLY" );
				}
			}

			_initializedMaterial = true;
			_cache_dotLength = this.dotLength;
			_cache_contrast = this.contrast;
			_cache_colorPrec = this.colorPrec;
			_cache_depthBias = this.depthBias;
			_cache_toneMatch = this.toneMatch;
			_cache_toneBalance = this.toneBalance;
		}

		Graphics.Blit(source, destination, mat);
	}
}