using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class BuildingLightController : MonoBehaviour
{
    [Tooltip("Color used when windows are on (night)")]
    public Color emissionColor = new Color(1f, 0.85f, 0.6f);
    [Tooltip("Emission intensity multiplier")]
    public float emissionIntensity = 2.0f;
    [Tooltip("Use material instance per renderer (recommended)")]
    public bool useMaterialInstance = true;

    private Renderer rend;
    private Material matInstance;
    private Color baseEmission = Color.black;
    private DayNightCycle cycle;

    void Awake()
    {
        rend = GetComponent<Renderer>();
        if (useMaterialInstance)
        {
            matInstance = rend.material;
        }
        else
        {
            matInstance = rend.sharedMaterial;
        }

        if (matInstance.HasProperty("_EmissionColor"))
            baseEmission = matInstance.GetColor("_EmissionColor");
        cycle = DayNightCycle.Instance;
    }

    void Start()
    {
        // initial state
        UpdateEmission(cycle != null ? cycle.IsDay() : true);
        if (cycle != null)
        {
            cycle.OnTimeChanged += OnTimeChanged;
        }
    }

    void OnDestroy()
    {
        if (cycle != null)
            cycle.OnTimeChanged -= OnTimeChanged;
    }

    void OnTimeChanged(float time)
    {
        UpdateEmission(DayNightCycle.Instance.IsDay());
    }

    void UpdateEmission(bool isDay)
    {
        if (matInstance == null) return;

        if (isDay)
        {
            if (matInstance.HasProperty("_EmissionColor"))
            {
                matInstance.SetColor("_EmissionColor", Color.black);
                matInstance.DisableKeyword("_EMISSION");
            }
        }
        else
        {
            if (matInstance.HasProperty("_EmissionColor"))
            {
                Color em = emissionColor * emissionIntensity;
                matInstance.SetColor("_EmissionColor", em);
                matInstance.EnableKeyword("_EMISSION");
            }
        }
    }
}
