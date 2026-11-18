#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace Shohin.EditorTools
{
    public static class WebGLBuild
    {
        public static void Build()
        {
            SHOHINProjectSetup.CreatePrototype();

            const string output = "Build/WebGL";
            Directory.CreateDirectory(output);

            var options = new BuildPlayerOptions
            {
                scenes = new[] { "Assets/Scenes/SHOHIN_Survival_Prototype.unity" },
                locationPathName = output + "/index.html",
                target = BuildTarget.WebGL,
                options = BuildOptions.None
            };

            var report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != BuildResult.Succeeded)
                throw new System.Exception("Unity WebGL build failed: " + report.summary.result);

            Debug.Log("SHOHIN WebGL build completed: " + report.summary.totalSize + " bytes");
        }
    }
}
#endif
