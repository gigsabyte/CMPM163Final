using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(ParticleSystemForceField))]
public class WindController : MonoBehaviour
{
    [Range(0, 1)]
    [SerializeField]
    private float _intensity = 0;
    public float Intensity { get => _intensity; set => SetIntensity(value); }
    public MathUtils.FloatRange magnitude = new MathUtils.FloatRange(0, 40);

    private ParticleSystemForceField pf;
    // Start is called before the first frame update
    void Start()
    {
        pf = GetComponent<ParticleSystemForceField>();
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

    public void SetIntensity(float value)
    {
        _intensity = value;
        pf.directionX = Mathf.Sin(value) * magnitude.Lerp(value);
        pf.directionZ = Mathf.Cos(value) * magnitude.Lerp(value);
        if (Mathf.PerlinNoise(pf.directionX.constant, pf.directionZ.constant) > 0.5)
            pf.directionX = -pf.directionX.constant;
        if (Mathf.PerlinNoise(pf.directionZ.constant, pf.directionX.constant) > 0.5)
            pf.directionX = -pf.directionZ.constant;

        //pf.directionX = direction == Direction.East ? magnitude.Lerp(value) : -magnitude.Lerp(value);
    }
}
