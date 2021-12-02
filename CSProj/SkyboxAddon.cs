using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEngine;

namespace BetterSkybox
{
    [KSPAddon(KSPAddon.Startup.MainMenu, true)]
    public class SkyboxAddon : MonoBehaviour 
    {
        private bool isInitialized = false;

        public void Start()
        {
            AssetLoader.instance = new AssetLoader();
            GameEvents.onGameStateCreated.Add(SetSkyboxShader);
            DontDestroyOnLoad(this);
        }

        public void Update()
        {
            if (AssetLoader.instance.shadersAvailable && GalaxyCubeControl.Instance != null)
            {
                float f = GalaxyCubeControl.Instance.airPressureFade;
                float atmoFade = 0;
                if (FlightGlobals.ActiveVessel != null) atmoFade = FlightGlobals.ActiveVessel.directSunlight ? (float)FlightGlobals.ActiveVessel.staticPressurekPa / 100.0f / f : 0;
                Renderer[] renderers = GalaxyCubeControl.Instance.gameObject.GetComponentsInChildren<Renderer>();
                foreach (Renderer r in renderers)
                {
                    r.material.SetFloat("_AtmoFade", atmoFade);
                }
            }
        }

        public void LateUpdate()
        {
            if(!isInitialized && PartLoader.Instance.IsReady())
            {
                isInitialized = true;
                AssetLoader.instance.Load();
            }
        }

        private void SetSkyboxShader(Game g)
        {
            Debug.Log("[BetterSkybox] Replacing skybox");
            if(GalaxyCubeControl.Instance == null)
            {
                return;
            }
            GameObject galaxyCube = GalaxyCubeControl.Instance.gameObject;
            if(galaxyCube == null)
            {
                return;
            }
            Renderer[] renderers = galaxyCube.GetComponentsInChildren<Renderer>();
            if(renderers == null || renderers.Length == 0)
            {
                Debug.Log("[BetterSkybox] GameObject found, but no renderers?");
                return;
            }
            if (!AssetLoader.instance.shadersAvailable)
            {
                Debug.Log("[BetterSkybox] Skybox materials incomplete or missing.");
                return;
            }
            foreach(Renderer r in renderers)
            {
                string matName = r.material.name;
                Debug.Log("[BetterSkybox] Attempting to replace material " + matName);
                if (matName.Equals("XP (Instance)")) r.material = AssetLoader.instance.XP;
                else if (matName.Equals("XN (Instance)")) r.material = AssetLoader.instance.XN;
                else if (matName.Equals("YP (Instance)")) r.material = AssetLoader.instance.YP;
                else if (matName.Equals("YN (Instance)")) r.material = AssetLoader.instance.YN;
                else if (matName.Equals("ZP (Instance)")) r.material = AssetLoader.instance.ZP;
                else if (matName.Equals("ZN (Instance)")) r.material = AssetLoader.instance.ZN;
                else continue;
                Debug.Log("[BetterSkybox] Success");
            }
            GalaxyCubeControl.Instance.glareFadeLimit = 1;
        }
    }
}
