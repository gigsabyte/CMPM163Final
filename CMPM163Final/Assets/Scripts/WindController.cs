using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(ParticleSystemForceField))]
public class WindController : MonoBehaviour
{
    [SerializeField]
    private Vector3 intensity = new Vector3();
    public float magCap = 200;
    public MathUtils.FloatRange magnitude = new MathUtils.FloatRange(0, 40);

    private ParticleSystemForceField pf;
    // Start is called before the first frame update
    void Start()
    {
        pf = GetComponent<ParticleSystemForceField>();
    }

    public Vector2 noiseScrollX = new Vector2();
    private Vector2 noiseX = new Vector2();
    public Vector2 noiseScrollZ = new Vector2();
    private Vector2 noiseZ = new Vector2();
    // Update is called once per frame
    void Update()
    {
        noiseX += noiseScrollX;
        noiseZ += noiseScrollZ;
        SetXIntensity(Mathf.PerlinNoise(noiseX.x, noiseX.y));
        SetZIntensity(Mathf.PerlinNoise(noiseZ.x, noiseZ.y));
    }

    public void SetXIntensity(float value)
    {
        intensity.x = value;
        pf.directionX = Mathf.Sin(value) * ((value - 0.5f) * 2) * Mathf.Min(magCap, magnitude.Lerp(value));
    }

    public void SetZIntensity(float value)
    {
        intensity.z = value;
        pf.directionZ = Mathf.Cos(value) * ((value - 0.5f) * 2) * Mathf.Min(magCap, magnitude.Lerp(value));
    }
}
