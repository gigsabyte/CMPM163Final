using System.Collections;
using System.Collections.Generic;
using MathUtils;
using UnityEngine;
[RequireComponent(typeof(WindController))]
public class WeatherRain : MonoBehaviour
{
    [Range(0, 1)]
    [SerializeField]
    private float _intensity = 0;
    public float Intensity { get => _intensity; set => SetIntensity(value); }
    private AudioSource _ambient;
    public AudioSource AmbientSound { get => _ambient; }
    [SerializeField]
    private FloatRange _windRange = new FloatRange(0, 40);
    public FloatRange WindRange { get => _windRange; }
    public float DestroyTime => 1;

    public FloatRange emissionMinMax = new FloatRange(10, 20);
    public FloatRange gravityMinMax = new FloatRange(5, 9);

    //#region Customization fields
    private ParticleSystem[] emitters;
    private ParticleSystem[] splashers;
    //#endregion

    // Start is called before the first frame update
    void Awake()
    {
        _ambient = GetComponent<AudioSource>();
        var emitterPairs = GetComponentsInChildren<ParticleSystem>();
        emitters = new ParticleSystem[emitterPairs.Length / 2];
        splashers = new ParticleSystem[emitterPairs.Length / 2];
        for (int i = 0; i < emitterPairs.Length /2; ++i)
        {
            emitters[i] = emitterPairs[2 * i];
            splashers[i] = emitterPairs[(2 * i) + 1];
        }
    }
    public Vector2 noiseScroll = new Vector2();
    private float noiseX = 0f;
    private float noiseY = 0f;
    // Update is called once per frame
    void Update()
    {
        noiseX += noiseScroll.x;
        noiseY += noiseScroll.y;
        SetIntensity(Mathf.PerlinNoise(noiseX, noiseY));
    }

    private void SetIntensity(float intensity)
    {
        _intensity = intensity;
        for(int i = 0; i < emitters.Length; ++i)
        {
            var ps = emitters[i];
            var m = ps.main;
            m.gravityModifier = gravityMinMax.Lerp(intensity);
            var e = ps.emission;
            var rot = e.rateOverTime;
            rot.constantMin = emissionMinMax.Lerp(intensity);
            rot.constantMax = rot.constantMin + 5 * Intensity;
            e.rateOverTime = rot;
        }
    }
}
