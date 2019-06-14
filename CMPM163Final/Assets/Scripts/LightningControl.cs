using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightningControl : MonoBehaviour
{
    private ParticleSystem lightning;

    public float branchRate;

    void Start()
    {
        lightning = GetComponent<ParticleSystem>();
    }

    void Update()
    {
        if(Random.value < branchRate)
        {
            lightning.TriggerSubEmitter(0);
        }
    }

    public void EmitLightning()
    {
        lightning.Emit(1);
    }
}
