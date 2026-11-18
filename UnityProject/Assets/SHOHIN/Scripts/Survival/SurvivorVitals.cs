using UnityEngine;

namespace Shohin.Survival
{
    public sealed class SurvivorVitals : MonoBehaviour
    {
        [Range(0, 100)] public float health = 100f;
        [Range(0, 100)] public float hunger = 100f;
        [Range(0, 100)] public float thirst = 100f;
        [Range(0, 100)] public float stamina = 100f;
        public float hungerLossPerGameHour = 0.65f;
        public float thirstLossPerGameHour = 1.05f;
        public GameClock clock;

        float lastHour;
        int lastDay = 1;

        void Start()
        {
            if (!clock) clock = FindFirstObjectByType<GameClock>();
            if (clock) { lastHour = clock.Hour; lastDay = clock.Day; }
        }

        void Update()
        {
            if (!clock) return;
            float elapsed = (clock.Day - lastDay) * 24f + clock.Hour - lastHour;
            if (elapsed < 0f) elapsed += 24f;
            if (elapsed <= 0f) return;
            hunger = Mathf.Max(0f, hunger - hungerLossPerGameHour * elapsed);
            thirst = Mathf.Max(0f, thirst - thirstLossPerGameHour * elapsed);
            if (hunger <= 0f || thirst <= 0f) health = Mathf.Max(0f, health - elapsed * 0.8f);
            lastHour = clock.Hour;
            lastDay = clock.Day;
        }

        public void Eat(float amount) => hunger = Mathf.Clamp(hunger + amount, 0f, 100f);
        public void Drink(float amount) => thirst = Mathf.Clamp(thirst + amount, 0f, 100f);
        public void Rest(float amount) => stamina = Mathf.Clamp(stamina + amount, 0f, 100f);
        public void Damage(float amount) => health = Mathf.Max(0f, health - amount);
    }
}
