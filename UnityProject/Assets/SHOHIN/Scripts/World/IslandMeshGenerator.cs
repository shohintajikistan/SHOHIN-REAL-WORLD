using UnityEngine;
using UnityEngine.Rendering;

namespace Shohin.Survival
{
    [RequireComponent(typeof(MeshFilter), typeof(MeshRenderer), typeof(MeshCollider))]
    public sealed class IslandMeshGenerator : MonoBehaviour
    {
        [Min(32)] public int resolution = 180;
        [Min(100f)] public float islandSize = 520f;
        [Min(5f)] public float maxHeight = 92f;
        [Range(0.005f, 0.08f)] public float detailScale = 0.025f;
        [Range(0f, 1f)] public float mountainStrength = 0.62f;
        public int seed = 17;
        public AnimationCurve coastProfile = AnimationCurve.EaseInOut(0, 0, 1, 1);
        public Material terrainMaterial;

        [ContextMenu("Generate Island Mesh")]
        public void Generate()
        {
            int side = resolution + 1;
            var vertices = new Vector3[side * side];
            var uv = new Vector2[vertices.Length];
            var triangles = new int[resolution * resolution * 6];
            float half = islandSize * 0.5f;
            var randomOffset = new Vector2(seed * 13.17f, seed * -7.31f);

            for (int z = 0; z < side; z++)
            for (int x = 0; x < side; x++)
            {
                float nx = x / (float)resolution * 2f - 1f;
                float nz = z / (float)resolution * 2f - 1f;
                float distance = Mathf.Sqrt(nx * nx * 0.92f + nz * nz * 1.08f);
                float coast = coastProfile.Evaluate(Mathf.Clamp01(1f - distance));
                float broad = Mathf.PerlinNoise(nx * 2.1f + randomOffset.x, nz * 2.1f + randomOffset.y);
                float detail = Mathf.PerlinNoise(nx / detailScale + randomOffset.y, nz / detailScale + randomOffset.x);
                float ridge = 1f - Mathf.Abs(detail * 2f - 1f);
                float land = Mathf.Max(0f, coast - 0.08f);
                float elevation = (0.18f + broad * 0.34f + detail * 0.18f + ridge * mountainStrength * 0.30f);
                float y = Mathf.Pow(land, 1.22f) * elevation * maxHeight;
                int i = z * side + x;
                vertices[i] = new Vector3(nx * half, y, nz * half);
                uv[i] = new Vector2(x / (float)resolution, z / (float)resolution);
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

            var mesh = new Mesh { name = $"SHOHIN Island {seed}", indexFormat = IndexFormat.UInt32 };
            mesh.vertices = vertices;
            mesh.triangles = triangles;
            mesh.uv = uv;
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();

            var filter = GetComponent<MeshFilter>();
            var collider = GetComponent<MeshCollider>();
            filter.sharedMesh = mesh;
            collider.sharedMesh = null;
            collider.sharedMesh = mesh;
            if (terrainMaterial != null) GetComponent<MeshRenderer>().sharedMaterial = terrainMaterial;
        }
    }
}
