using UnityEngine;
using System;

[ExecuteAlways]
public class DayNightCycle : MonoBehaviour
{
    [Tooltip("Duration of a full cycle in seconds")]
    public float cycleDuration = 60f;

    [Range(0f, 1f)]
    public float timeOfDay = 0f; // 0..1

    [Tooltip("Directional light used as sun/moon")]
    public Light directionalLight;

    [Tooltip("Color at day (sun)")]
    public Color dayLightColor = Color.white;
    [Tooltip("Color at night (moon)")]
    public Color nightLightColor = new Color(0.2f, 0.25f, 0.45f);

    [Tooltip("Intensity at day")]
    public float dayIntensity = 1.0f;
    [Tooltip("Intensity at night")]
    public float nightIntensity = 0.15f;

    public static DayNightCycle Instance { get; private set; }

    public event Action<float> OnTimeChanged; // optional event

    void Awake()
    {
        Instance = this;
        if (directionalLight == null)
        {
            // try to find main directional light
            directionalLight = RenderSettings.sun;
        }
    }

    void Update()
    {
        // advance time
        if (cycleDuration > 0f && Application.isPlaying)
        {
            timeOfDay += Time.deltaTime / cycleDuration;
            timeOfDay %= 1f;
            ApplyLighting();
            OnTimeChanged?.Invoke(timeOfDay);
        }
    }

    void ApplyLighting()
    {
        // rotate sun: map timeOfDay (0..1) to angle (-90 -> 270) so sunrise at 0, midday ~0.25, sunset ~0.5, midnight ~0.75
        float sunAngle = Mathf.Lerp(-90f, 270f, timeOfDay);
        if (directionalLight != null)
        {
            directionalLight.transform.rotation = Quaternion.Euler(new Vector3(sunAngle, -30f, 0f));

            // determine day/night factor
            bool isDay = IsDay();
            // Smooth intensity interpolation: use curve around day range
            float t = Mathf.InverseLerp(0.25f, 0.75f, timeOfDay); // 0..1 across day range, clamps outside
            t = Mathf.Clamp01(t);
            // Lerp color and intensity
            Color lightColor = Color.Lerp(nightLightColor, dayLightColor, t);
            float intensity = Mathf.Lerp(nightIntensity, dayIntensity, t);

            directionalLight.color = lightColor;
            directionalLight.intensity = intensity;

            // Optionally change ambient intensity
            RenderSettings.ambientIntensity = Mathf.Lerp(0.2f, 1.0f, t);
            RenderSettings.ambientLight = Color.Lerp(nightLightColor * 0.2f, dayLightColor * 0.5f, t);
        }
    }

    public bool IsDay()
    {
        return timeOfDay >= 0.25f && timeOfDay <= 0.75f;
    }

    public void SetTimeOfDay(float value)
    {
        timeOfDay = Mathf.Repeat(value, 1f);
        ApplyLighting();
        OnTimeChanged?.Invoke(timeOfDay);
    }
}
