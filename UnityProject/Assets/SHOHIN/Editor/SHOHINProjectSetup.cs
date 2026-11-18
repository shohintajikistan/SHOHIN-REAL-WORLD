#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using Shohin.Survival;
using Shohin.UI;

namespace Shohin.EditorTools
{
    public static class SHOHINProjectSetup
    {
        const string Root = "Assets/SHOHIN";
        [MenuItem("SHOHIN/Create Cinematic Survival Prototype")]
        public static void CreatePrototype()
        {
            EnsureFolder("Assets/Scenes");
            EnsureFolder(Root + "/Materials");
            EnsureFolder(Root + "/Settings");

            var terrainMat = MakeMaterial("Island_Terrain", new Color(0.18f, 0.30f, 0.16f));
            var oceanMat = MakeMaterial("Ocean_DeepBlue", new Color(0.025f, 0.19f, 0.25f));
            if (oceanMat.HasProperty("_Smoothness")) oceanMat.SetFloat("_Smoothness", 0.88f);
            if (oceanMat.HasProperty("_Metallic")) oceanMat.SetFloat("_Metallic", 0.18f);

            var scene = EditorSceneManager.NewScene(NewSceneSetup.DefaultGameObjects, NewSceneMode.Single);
            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.38f, 0.48f, 0.58f);
            RenderSettings.ambientEquatorColor = new Color(0.25f, 0.30f, 0.25f);
            RenderSettings.ambientGroundColor = new Color(0.10f, 0.12f, 0.10f);
            RenderSettings.ambientIntensity = 1.05f;
            RenderSettings.fog = true;
            RenderSettings.fogColor = new Color(0.56f, 0.65f, 0.68f);
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.00075f;

            var sun = FindDirectionalLight();
            if (sun != null)
            {
                sun.name = "SHOHIN_Sun";
                sun.transform.rotation = Quaternion.Euler(34f, -32f, 0f);
                sun.color = new Color(1f, 0.91f, 0.78f);
                sun.intensity = 1.25f;
                sun.shadows = LightShadows.Soft;
                sun.shadowStrength = 0.82f;
                sun.shadowBias = 0.045f;
                sun.shadowNormalBias = 0.35f;
                RenderSettings.sun = sun;
            }

            CreateIsland("Island_01_Shipwreck", new Vector3(-340, 0, 0), 520, 88, 31, terrainMat);
            CreateIsland("Island_02_Mystery", new Vector3(360, 0, 35), 450, 105, 97, terrainMat);

            var ocean = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ocean.name = "Ocean_Base";
            ocean.transform.position = new Vector3(0, 0.4f, 0);
            ocean.transform.localScale = new Vector3(240, 1, 240);
            ocean.GetComponent<Renderer>().sharedMaterial = oceanMat;
            ocean.GetComponent<Renderer>().shadowCastingMode = ShadowCastingMode.Off;
            var oceanCollider = ocean.GetComponent<Collider>();
            if (oceanCollider != null) Object.DestroyImmediate(oceanCollider);
            ocean.AddComponent<OceanWaves>();

            var player = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            player.name = "Player_Prototype";
            player.transform.position = new Vector3(-340, 130, 0);
            player.transform.localScale = new Vector3(0.85f, 1f, 0.85f);
            Object.DestroyImmediate(player.GetComponent<CapsuleCollider>());
            var cc = player.AddComponent<CharacterController>();
            cc.height = 1.9f; cc.radius = 0.38f; cc.center = new Vector3(0, 0.95f, 0);
            player.AddComponent<SurvivorController>();
            player.AddComponent<SurvivorVitals>();

            var camera = Camera.main;
            camera.name = "Main Camera";
            camera.farClipPlane = 1800f;
            camera.allowHDR = true;
            var cameraData = camera.GetComponent<UniversalAdditionalCameraData>();
            if (cameraData == null) cameraData = camera.gameObject.AddComponent<UniversalAdditionalCameraData>();
            cameraData.renderPostProcessing = true;
            var camRig = camera.gameObject.AddComponent<ThirdPersonCamera>();
            camRig.target = player.transform;
            player.GetComponent<SurvivorController>().cameraTransform = camera.transform;

            var clock = new GameObject("GameClock").AddComponent<GameClock>();
            player.GetComponent<SurvivorVitals>().clock = clock;
            MobileSurvivalHUD.Create(player.transform, camRig);

            var volumeObject = new GameObject("Cinematic_PostProcessing");
            var volume = volumeObject.AddComponent<Volume>();
            volume.isGlobal = true;
            var profile = ScriptableObject.CreateInstance<VolumeProfile>();
            profile.Add<Tonemapping>().mode.Override(TonemappingMode.ACES);
            profile.Add<Bloom>().intensity.Override(0.18f);
            var colorAdjustments = profile.Add<ColorAdjustments>();
            colorAdjustments.postExposure.Override(0.1f);
            colorAdjustments.contrast.Override(12f);
            profile.Add<Vignette>().intensity.Override(0.22f);
            volume.sharedProfile = profile;
            AssetDatabase.CreateAsset(profile, Root + "/Settings/CinematicVolumeProfile.asset");

            EditorSceneManager.SaveScene(scene, "Assets/Scenes/SHOHIN_Survival_Prototype.unity");
            EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/Scenes/SHOHIN_Survival_Prototype.unity", true) };
            Selection.activeGameObject = player;
            Debug.Log("SHOHIN cinematic environment created: two islands, animated ocean, warm sun, fog and ACES post-processing. Replace the prototype capsule and import final art assets for the next visual pass.");
        }

        static Light FindDirectionalLight()
        {
            foreach (var light in Object.FindObjectsByType<Light>(FindObjectsSortMode.None))
                if (light.type == LightType.Directional) return light;
            return null;
        }

        static void CreateIsland(string name, Vector3 position, float size, float height, int seed, Material material)
        {
            var go = new GameObject(name);
            go.transform.position = position;
            var gen = go.AddComponent<IslandMeshGenerator>();
            gen.islandSize = size; gen.maxHeight = height; gen.seed = seed; gen.terrainMaterial = material;
            gen.Generate();
        }

        static Material MakeMaterial(string name, Color color)
        {
            var shader = Shader.Find("Universal Render Pipeline/Lit");
            if (!shader) shader = Shader.Find("Standard");
            var mat = new Material(shader) { name = name, color = color };
            AssetDatabase.CreateAsset(mat, Root + "/Materials/" + name + ".mat");
            return mat;
        }

        static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path)) return;
            string parent = System.IO.Path.GetDirectoryName(path).Replace("\\", "/");
            string folder = System.IO.Path.GetFileName(path);
            if (!AssetDatabase.IsValidFolder(parent)) EnsureFolder(parent);
            AssetDatabase.CreateFolder(parent, folder);
        }
    }
}
#endif
