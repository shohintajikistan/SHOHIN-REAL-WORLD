using UnityEngine;
using UnityEngine.Rendering;

namespace Shohin.Survival
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
    public sealed class OceanWaves : MonoBehaviour
    {
        [Range(16, 128)] public int gridResolution = 64;
        [Min(0f)] public float waveHeight = 0.22f;
        [Min(0.001f)] public float waveFrequency = 0.035f;
        [Min(0f)] public float waveSpeed = 0.75f;
        [Range(0f, 1f)] public float smoothness = 0.88f;

        Mesh waterMesh;
        Vector3[] baseVertices;
        Vector3[] animatedVertices;
        Material runtimeMaterial;

        void Awake()
        {
            waterMesh = BuildGrid(gridResolution);
            waterMesh.name = "SHOHIN Animated Ocean Mesh";
            waterMesh.MarkDynamic();
            GetComponent<MeshFilter>().sharedMesh = waterMesh;

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

        Mesh BuildGrid(int resolution)
        {
            int side = resolution + 1;
            var vertices = new Vector3[side * side];
            var uv = new Vector2[vertices.Length];
            var triangles = new int[resolution * resolution * 6];
            for (int z = 0; z <= resolution; z++)
            for (int x = 0; x <= resolution; x++)
            {
                int index = z * side + x;
                vertices[index] = new Vector3((x / (float)resolution - 0.5f) * 10f, 0f,
                                              (z / (float)resolution - 0.5f) * 10f);
                uv[index] = new Vector2(x / (float)resolution, z / (float)resolution);
            }

            int t = 0;
            for (int z = 0; z < resolution; z++)
            for (int x = 0; x < resolution; x++)
            {
                int i = z * side + x;
                triangles[t++] = i;
                triangles[t++] = i + side;
                triangles[t++] = i + 1;
                triangles[t++] = i + 1;
                triangles[t++] = i + side;
                triangles[t++] = i + side + 1;
            }

            var mesh = new Mesh { indexFormat = IndexFormat.UInt32 };
            mesh.vertices = vertices;
            mesh.triangles = triangles;
            mesh.uv = uv;
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }

        void Update()
        {
            if (waterMesh == null) return;
            float time = Time.time * waveSpeed;
            for (int i = 0; i < baseVertices.Length; i++)
            {
                Vector3 p = baseVertices[i];
                Vector3 world = transform.TransformPoint(p);
                float a = Mathf.Sin((world.x + time) * waveFrequency);
                float b = Mathf.Cos((world.z - time * 0.82f) * waveFrequency * 1.31f);
                float c = Mathf.Sin((world.x + world.z + time * 0.55f) * waveFrequency * 0.72f);
                p.y = (a * 0.48f + b * 0.34f + c * 0.18f) * waveHeight;
                animatedVertices[i] = p;
            }
            waterMesh.vertices = animatedVertices;
            waterMesh.RecalculateNormals();
            waterMesh.RecalculateBounds();
        }

        void OnDestroy()
        {
            if (waterMesh != null)
            {
                if (Application.isPlaying) Destroy(waterMesh);
                else DestroyImmediate(waterMesh);
            }
            if (runtimeMaterial != null)
            {
                if (Application.isPlaying) Destroy(runtimeMaterial);
                else DestroyImmediate(runtimeMaterial);
            }
        }
    }
}