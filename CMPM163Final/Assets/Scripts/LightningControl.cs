using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightningControl : MonoBehaviour
{
    private ParticleSystem lightning;
    private Color originalColor;
    private float originalIntensity;

    public Light light;
    public float rate;
    public float branchRate;
    public float flashIntensity;
    public float fadeSpeed;
    public AudioSource thunderSource;

    void Start()
    {
        lightning = GetComponent<ParticleSystem>();
        originalColor = light.color;
        originalIntensity = light.intensity;
    }

    void Update()
    {
        // randomly emit lightning strikes
        if(Random.value < rate)
        {
            EmitLightning();
        }

        // random chance of creating a lightning branch from subemitter
        if(Random.value < branchRate)
        {
            lightning.TriggerSubEmitter(0);
        }
    }

    public void EmitLightning()
    {
        lightning.Emit(1);
        if(!thunderSource.isPlaying)
            thunderSource.Play();
        StartCoroutine(Flash());
    }

    // simulate lightning flash by changing point light color
    private IEnumerator Flash()
    {
        yield return new WaitForSeconds(0.025f);
        light.intensity = flashIntensity;
        light.color = Color.white;
        yield return new WaitForSeconds(0.1f);
        while(light.intensity > originalIntensity)
        {
            light.intensity -= Time.deltaTime * fadeSpeed;
            yield return new WaitForEndOfFrame();
        }
        light.color = originalColor;
        light.intensity = originalIntensity;
    }
}
