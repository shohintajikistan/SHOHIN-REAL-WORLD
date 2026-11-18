using System;
using UnityEngine;

namespace Shohin.Survival
{
    public sealed class GameClock : MonoBehaviour
    {
        [Tooltip("Real-time minutes for one full 24-hour game day.")]
        [Min(5f)] public float realMinutesPerGameDay = 40f;
        [Range(0f, 24f)] public float startingHour = 8.5f;
        [Min(1)] public int daysPerSeason = 30;
        public int Day { get; private set; } = 1;
        public float Hour { get; private set; }
        public event Action<int, float> TimeChanged;
        public event Action<int> NewDay;

        void Start() => Hour = startingHour;

        void Update()
        {
            float oldHour = Hour;
            Hour += 24f * Time.deltaTime / (realMinutesPerGameDay * 60f);
            if (Hour >= 24f)
            {
                Hour %= 24f;
                Day++;
                NewDay?.Invoke(Day);
            }
            if (Mathf.FloorToInt(oldHour * 4f) != Mathf.FloorToInt(Hour * 4f))
                TimeChanged?.Invoke(Day, Hour);
        }

        public string GetSeason()
        {
            int season = ((Day - 1) / daysPerSeason) % 4;
            return new[] { "Summer", "Autumn", "Winter", "Spring" }[season];
        }

        public string GetTimeString()
        {
            int h = Mathf.FloorToInt(Hour);
            int m = Mathf.FloorToInt((Hour - h) * 60f);
            return $"{h:00}:{m:00}";
        }
    }
}
