using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightningControl : MonoBehaviour
{
    private ParticleSystem lightning;
    public Light light;
    public float branchRate;

    void Start()
    {
        lightning = GetComponent<ParticleSystem>();
    }

    void Update()
    {
        // random chance of creating a lightning branch from subemitter
        if(Random.value < branchRate)
        {
            lightning.TriggerSubEmitter(0);
        }
    }

    public void EmitLightning()
    {
        lightning.Emit(1);
        StartCoroutine(Flash());
    }

    // simulate lightning flash by changing point light color
    private IEnumerator Flash()
    {
        Color originalColor = light.color;
        yield return new WaitForSeconds(0.025f);
        light.color = Color.white;
        yield return new WaitForSeconds(0.1f);
        light.color = originalColor;
    }
}
