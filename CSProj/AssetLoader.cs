using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using UnityEngine;

namespace BetterSkybox
{
    class AssetLoader
    {
        public static AssetLoader instance = null;
        public static string skyboxAssetBundlesPath = Path.Combine(KSPUtil.ApplicationRootPath, "GameData", "BetterSkybox", "Assets", "avalonsky.ksp");
        private static string[] texNames = { "_pos_x", "_neg_x", "_pos_y", "_neg_y", "_pos_z", "_neg_z" };

        private static bool loaded = false;
        private Shader skyboxShader;
        public Material XP, XN, YP, YN, ZP, ZN;
        public bool shadersAvailable = false;

        public AssetLoader()
        {
        }

        public void Load()
        {
            if (loaded) return;

            if (LoadAssetBundle(skyboxAssetBundlesPath))
            {
                UrlDir.UrlConfig[] configFiles = GameDatabase.Instance.GetConfigs("BetterSkybox");
                if (configFiles.Length == 0)
                {
                    Debug.Log("[BetterSkybox] No config files found.");
                    return;
                }
                UrlDir.UrlConfig config = configFiles.Last();
                foreach(ConfigNode rootNode in config.config.GetNodes("Skybox"))
                {
                    float galaxyFadeBias = 0, starsFadeBias = 0, galaxyMinBrightness = 0, galaxyMaxBrightness = 1, starsMinBrightness = 0, starsMaxBrightness = 1;
                    float starsHaloThreshold = 1, starsMaxHalo = 10, starsScale = 2.5f, starsHaloBrightness = 0.1f;
                    if (rootNode.HasValue("GalaxyFadeBias")) galaxyFadeBias = float.Parse(rootNode.GetValue("GalaxyFadeBias"));
                    if (rootNode.HasValue("StarsFadeBias")) starsFadeBias = float.Parse(rootNode.GetValue("StarsFadeBias"));
                    if (rootNode.HasValue("GalaxyMinBrightness")) galaxyMinBrightness = float.Parse(rootNode.GetValue("GalaxyMinBrightness"));
                    if (rootNode.HasValue("GalaxyMaxBrightness")) galaxyMaxBrightness = float.Parse(rootNode.GetValue("GalaxyMaxBrightness"));
                    if (rootNode.HasValue("StarsMinBrightness")) starsMinBrightness = float.Parse(rootNode.GetValue("StarsMinBrightness"));
                    if (rootNode.HasValue("StarsMaxBrightness")) starsMaxBrightness = float.Parse(rootNode.GetValue("StarsMaxBrightness"));
                    float galaxyColorBias = 0, starsColorBias = 0;
                    if (rootNode.HasValue("GalaxyColorBias")) galaxyColorBias = float.Parse(rootNode.GetValue("GalaxyColorBias"));
                    if (rootNode.HasValue("StarsColorBias")) starsColorBias = float.Parse(rootNode.GetValue("StarsColorBias"));
                    float galaxyAtmoFadeMax = 1, starsAtmoFadeMax = 1;
                    if (rootNode.HasValue("GalaxyAtmoFadeMax")) galaxyAtmoFadeMax = float.Parse(rootNode.GetValue("GalaxyAtmoFadeMax"));
                    if (rootNode.HasValue("StarsAtmoFadeMax")) starsAtmoFadeMax = float.Parse(rootNode.GetValue("StarsAtmoFadeMax"));
                    if (rootNode.HasValue("StarsHaloThreshold")) starsHaloThreshold = float.Parse(rootNode.GetValue("StarsHaloThreshold"));
                    if (rootNode.HasValue("StarsMaxHalo")) starsMaxHalo = float.Parse(rootNode.GetValue("StarsMaxHalo"));
                    if (rootNode.HasValue("StarsScale")) starsScale = float.Parse(rootNode.GetValue("StarsScale"));
                    if (rootNode.HasValue("StarsHaloBrightness")) starsHaloBrightness = float.Parse(rootNode.GetValue("StarsHaloBrightness"));
                    float galaxyExposure = 1, starsExposure = 1;
                    if (rootNode.HasValue("GalaxyExposure")) galaxyExposure = float.Parse(rootNode.GetValue("GalaxyExposure"));
                    if (rootNode.HasValue("StarsExposure")) starsExposure = float.Parse(rootNode.GetValue("StarsExposure"));

                    Texture2D starsTex;
                    if(rootNode.HasValue("StarsTex")) starsTex = GameDatabase.Instance.GetTexture(rootNode.GetValue("StarsTex"), false);
                    else starsTex = Texture2D.blackTexture;
                    for (int i = 0; i < 6; i++)
                    {
                        Texture2D galaxyTex;
                        if (rootNode.HasValue("GalaxyTex")) galaxyTex = GameDatabase.Instance.GetTexture(rootNode.GetValue("GalaxyTex") + texNames[i], false);
                        else galaxyTex = Texture2D.blackTexture;

                        Material mat = new Material(skyboxShader);
                        mat.SetTexture("_GalaxyTex", galaxyTex);
                        mat.SetTexture("_StarsTex", starsTex);
                        mat.SetFloat("_GalaxyFadeBias", galaxyFadeBias);
                        mat.SetFloat("_StarsFadeBias", starsFadeBias);
                        mat.SetFloat("_GalaxyMinBrightness", galaxyMinBrightness);
                        mat.SetFloat("_GalaxyMaxBrightness", galaxyMaxBrightness);
                        mat.SetFloat("_StarsMinBrightness", starsMinBrightness);
                        mat.SetFloat("_StarsMaxBrightness", starsMaxBrightness);
                        mat.SetFloat("_GalaxyColorBias", galaxyColorBias);
                        mat.SetFloat("_StarColorBias", starsColorBias);
                        mat.SetFloat("_GalaxyAtmoFadeMax", galaxyAtmoFadeMax);
                        mat.SetFloat("_StarsAtmoFadeMax", starsAtmoFadeMax);
                        mat.SetFloat("_HaloThreshold", starsHaloThreshold);
                        mat.SetFloat("_MaxHalo", starsMaxHalo);
                        mat.SetFloat("_StarScale", starsScale);
                        mat.SetFloat("_HaloBrightness", starsHaloBrightness);
                        mat.SetFloat("_GalaxyExposure", galaxyExposure);
                        mat.SetFloat("_StarsExposure", starsExposure);

                        switch (i)
                        {
                            case 0:
                                XP = mat;
                                break;
                            case 1:
                                XN = mat;
                                break;
                            case 2:
                                YP = mat;
                                break;
                            case 3:
                                YN = mat;
                                YN.SetInt("_NegYFix", 1);
                                break;
                            case 4:
                                ZP = mat;
                                break;
                            case 5:
                                ZN = mat;
                                break;
                        }
                    }
                }
                shadersAvailable = true;
            }
        }

        private bool LoadAssetBundle(string path)
        {
            AssetBundle bundle = AssetBundle.LoadFromFile(path);
            Debug.Log("[BetterSkybox] Dump asset names");
            foreach(String s in bundle.GetAllAssetNames()) Debug.Log(s);
            Debug.Log("[BetterSkybox] Load skybox shader");
            Shader[] shaders = bundle.LoadAllAssets<Shader>();
            skyboxShader = null;
            foreach(Shader s in shaders)
            {
                if (s.name.EndsWith("BetterSky"))
                {
                    skyboxShader = s;
                    break;
                }
            }
            if(skyboxShader == null)
            {
                Debug.Log("[BetterSkybox] Skybox shader not found in asset bundle");
                return false;
            }
            return true;
        }
    }
}
