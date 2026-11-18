using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using UnityEngine.Events;
using Shohin.Survival;

namespace Shohin.UI
{
    public sealed class MobileSurvivalHUD : MonoBehaviour
    {
        SurvivorController player;
        ThirdPersonCamera cameraRig;
        Joystick joystick;
        HoldButton sprint;
        LookArea lookArea;
        Text clockText, statsText;
        GameClock clock;
        SurvivorVitals vitals;

        public static void Create(Transform playerTransform, ThirdPersonCamera camera)
        {
            var player = playerTransform.GetComponent<SurvivorController>();
            var vitals = playerTransform.GetComponent<SurvivorVitals>();
            var clock = FindFirstObjectByType<GameClock>();

            var eventSystem = FindFirstObjectByType<EventSystem>();
            if (!eventSystem)
            {
                var es = new GameObject("EventSystem");
                eventSystem = es.AddComponent<EventSystem>();
                es.AddComponent<StandaloneInputModule>();
            }

            var canvasObject = new GameObject("SHOHIN_Mobile_HUD");
            var canvas = canvasObject.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvasObject.AddComponent<CanvasScaler>().uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            canvasObject.GetComponent<CanvasScaler>().referenceResolution = new Vector2(1920, 1080);
            canvasObject.GetComponent<CanvasScaler>().matchWidthOrHeight = 0.5f;
            canvasObject.AddComponent<GraphicRaycaster>();

            var hud = canvasObject.AddComponent<MobileSurvivalHUD>();
            hud.player = player;
            hud.cameraRig = camera;
            hud.clock = clock;
            hud.vitals = vitals;
            hud.Build();
        }

        void Build()
        {
            var look = Panel("Look_Area", transform, new Vector2(0.38f, 0.08f), new Vector2(1f, 0.88f), new Color(0, 0, 0, 0.015f));
            lookArea = look.AddComponent<LookArea>();
            lookArea.owner = this;

            var left = Panel("Movement_Zone", transform, new Vector2(0.035f, 0.08f), new Vector2(0.30f, 0.40f), new Color(0.02f, 0.12f, 0.09f, 0.30f));
            joystick = left.AddComponent<Joystick>();
            joystick.owner = this;
            var knob = Panel("Joystick_Knob", left.transform, new Vector2(0.28f, 0.28f), new Vector2(0.72f, 0.72f), new Color(0.55f, 0.92f, 0.42f, 0.78f));
            knob.transform.SetAsLastSibling();
            joystick.knob = knob.GetComponent<RectTransform>();

            var jump = MakeButton("JUMP", new Vector2(0.88f, 0.22f), new Vector2(0.105f, 0.15f));
            jump.onClick.AddListener(() => player.QueueJump());

            var sprintObject = MakeButton("RUN", new Vector2(0.75f, 0.12f), new Vector2(0.09f, 0.12f)).gameObject;
            sprint = sprintObject.AddComponent<HoldButton>();
            sprint.owner = this;

            clockText = MakeText("DAY 1  •  08:30", new Vector2(0.12f, 0.93f), new Vector2(0.22f, 0.045f), 25, TextAnchor.MiddleLeft);
            statsText = MakeText("HEALTH 100   FOOD 100   WATER 100", new Vector2(0.5f, 0.93f), new Vector2(0.38f, 0.045f), 22, TextAnchor.MiddleCenter);
            MakeText("SHOHIN SURVIVAL", new Vector2(0.88f, 0.94f), new Vector2(0.20f, 0.04f), 20, TextAnchor.MiddleRight);
        }

        void Update()
        {
            if (player) player.SetMoveInput(joystick ? joystick.Value : Vector2.zero);
            if (player) player.SetSprint(sprint && sprint.IsHeld);
            if (clock && clockText) clockText.text = $"DAY {clock.Day}  •  {clock.GetTimeString()}  •  {clock.GetSeason().ToUpper()}";
            if (vitals && statsText)
                statsText.text = $"HEALTH {Mathf.RoundToInt(vitals.health)}     FOOD {Mathf.RoundToInt(vitals.hunger)}     WATER {Mathf.RoundToInt(vitals.thirst)}";
        }

        public void Look(Vector2 delta) { if (cameraRig) cameraRig.AddLookInput(delta); }

        RectTransform Panel(string name, Transform parent, Vector2 min, Vector2 max, Color color)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = min; rect.anchorMax = max; rect.offsetMin = Vector2.zero; rect.offsetMax = Vector2.zero;
            go.GetComponent<Image>().color = color;
            return rect;
        }

        Button MakeButton(string label, Vector2 anchor, Vector2 size)
        {
            var rect = Panel(label + "_Button", transform, anchor - size * 0.5f, anchor + size * 0.5f, new Color(0.03f, 0.22f, 0.15f, 0.78f));
            var button = rect.gameObject.AddComponent<Button>();
            var text = MakeText(label, anchor, size, 27, TextAnchor.MiddleCenter);
            text.transform.SetParent(rect, false);
            var tr = text.rectTransform;
            tr.anchorMin = Vector2.zero; tr.anchorMax = Vector2.one; tr.offsetMin = Vector2.zero; tr.offsetMax = Vector2.zero;
            return button;
        }

        Text MakeText(string value, Vector2 anchor, Vector2 size, int fontSize, TextAnchor align)
        {
            var rect = Panel(value + "_Text", transform, anchor - size * 0.5f, anchor + size * 0.5f, new Color(0, 0, 0, 0));
            var text = rect.gameObject.AddComponent<Text>();
            text.text = value; text.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
            text.fontSize = fontSize; text.alignment = align; text.color = Color.white;
            text.fontStyle = FontStyle.Bold; text.raycastTarget = false;
            return text;
        }

        public sealed class Joystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
        {
            public MobileSurvivalHUD owner;
            public RectTransform knob;
            public Vector2 Value { get; private set; }
            public void OnPointerDown(PointerEventData e) => OnDrag(e);
            public void OnDrag(PointerEventData e)
            {
                var rect = (RectTransform)transform;
                if (RectTransformUtility.ScreenPointToLocalPointInRectangle(rect, e.position, e.pressEventCamera, out var local))
                {
                    var radius = Mathf.Min(rect.rect.width, rect.rect.height) * 0.34f;
                    Value = Vector2.ClampMagnitude(local / Mathf.Max(1f, radius), 1f);
                    if (knob) knob.anchoredPosition = Value * radius;
                }
            }
            public void OnPointerUp(PointerEventData e) { Value = Vector2.zero; if (knob) knob.anchoredPosition = Vector2.zero; }
        }

        public sealed class LookArea : MonoBehaviour, IDragHandler
        {
            public MobileSurvivalHUD owner;
            Vector2 previous;
            public void OnDrag(PointerEventData e) { owner.Look(e.delta); }
        }

        public sealed class HoldButton : MonoBehaviour, IPointerDownHandler, IPointerUpHandler
        {
            public MobileSurvivalHUD owner;
            public bool IsHeld { get; private set; }
            public void OnPointerDown(PointerEventData e) => IsHeld = true;
            public void OnPointerUp(PointerEventData e) => IsHeld = false;
            void OnDisable() => IsHeld = false;
        }
    }
}