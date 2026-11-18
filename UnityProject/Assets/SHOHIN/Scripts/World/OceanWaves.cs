using UnityEngine;
using UnityEngine.Rendering;

namespace Shohin.Survival
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public sealed class OceanWaves : MonoBehaviour
    {
        [Min(0f)] public float waveHeight = 0.22f;
        [Min(0.01f)] public float waveFrequency = 0.035f;
        [Min(0f)] public float waveSpeed = 0.75f;
        [Range(0f, 1f)] public float smoothness = 0.88f;

        Mesh waterMesh;
        Vector3[] baseVertices;
        Vector3[] animatedVertices;
        Material runtimeMaterial;

        void Awake()
        {
            var filter = GetComponent<MeshFilter>();
            waterMesh = Instantiate(filter.sharedMesh);
            waterMesh.name = "SHOHIN Animated Ocean Mesh";
            waterMesh.MarkDynamic();
            filter.sharedMesh = waterMesh;
            baseVertices = waterMesh.vertices;
            animatedVertices = new Vector3[baseVertices.Length];

            var renderer = GetComponent<MeshRenderer>();
            renderer.shadowCastingMode = ShadowCastingMode.Off;
            renderer.receiveShadows = false;
            if (renderer.sharedMaterial != null)
            {
                runtimeMaterial = new Material(renderer.sharedMaterial);
                runtimeMaterial.name = "SHOHIN Ocean Runtime";
                if (runtimeMaterial.HasProperty("_Smoothness"))
                    runtimeMaterial.SetFloat("_Smoothness", smoothness);
                if (runtimeMaterial.HasProperty("_Metallic"))
                    runtimeMaterial.SetFloat("_Metallic", 0.18f);
                renderer.material = runtimeMaterial;
            }
        }

        void Update()
        {
            if (waterMesh == null) return;
            float time = Time.time * waveSpeed;
            for (int i = 0; i < baseVertices.Length; i++)
            {
                Vector3 p = baseVertices[i];
                float a = Mathf.Sin((p.x + time) * waveFrequency);
                float b = Mathf.Cos((p.z - time * 0.82f) * waveFrequency * 1.31f);
                float c = Mathf.Sin((p.x + p.z + time * 0.55f) * waveFrequency * 0.72f);
                p.y = (a * 0.48f + b * 0.34f + c * 0.18f) * waveHeight;
                animatedVertices[i] = p;
            }
            waterMesh.vertices = animatedVertices;
            waterMesh.RecalculateNormals();
            waterMesh.RecalculateBounds();
        }

        void OnDestroy()
        {
            if (Application.isPlaying && waterMesh != null) Destroy(waterMesh);
            if (Application.isPlaying && runtimeMaterial != null) Destroy(runtimeMaterial);
        }
    }
}