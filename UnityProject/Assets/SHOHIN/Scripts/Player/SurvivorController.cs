using UnityEngine;

namespace Shohin.Survival
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class SurvivorController : MonoBehaviour
    {
        [Header("Movement")]
        public float walkSpeed = 3.8f;
        public float sprintSpeed = 6.4f;
        public float rotationSharpness = 13f;
        public float jumpHeight = 1.35f;
        public float gravity = -24f;
        public Transform cameraTransform;

        CharacterController controller;
        Vector3 verticalSpeed;
        Vector2 mobileMove;
        bool sprintHeld;
        bool jumpQueued;

        void Awake() => controller = GetComponent<CharacterController>();

        public void SetMoveInput(Vector2 value) => mobileMove = Vector2.ClampMagnitude(value, 1f);
        public void SetSprint(bool value) => sprintHeld = value;
        public void QueueJump() => jumpQueued = true;

        void Update()
        {
            Vector2 input = mobileMove;
#if ENABLE_LEGACY_INPUT_MANAGER
            if (input.sqrMagnitude < 0.001f)
                input = new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));
            sprintHeld |= Input.GetKey(KeyCode.LeftShift);
            jumpQueued |= Input.GetButtonDown("Jump");
#endif
            Transform cam = cameraTransform != null ? cameraTransform : Camera.main?.transform;
            Vector3 forward = cam ? Vector3.ProjectOnPlane(cam.forward, Vector3.up).normalized : Vector3.forward;
            Vector3 right = cam ? Vector3.ProjectOnPlane(cam.right, Vector3.up).normalized : Vector3.right;
            Vector3 move = Vector3.ClampMagnitude(forward * input.y + right * input.x, 1f);

            if (move.sqrMagnitude > 0.001f)
            {
                Quaternion target = Quaternion.LookRotation(move, Vector3.up);
                transform.rotation = Quaternion.Slerp(transform.rotation, target, rotationSharpness * Time.deltaTime);
            }

            if (controller.isGrounded && verticalSpeed.y < 0f) verticalSpeed.y = -2f;
            if (controller.isGrounded && jumpQueued)
                verticalSpeed.y = Mathf.Sqrt(jumpHeight * -2f * gravity);
            jumpQueued = false;
            verticalSpeed.y += gravity * Time.deltaTime;

            float speed = sprintHeld ? sprintSpeed : walkSpeed;
            controller.Move((move * speed + verticalSpeed) * Time.deltaTime);
            sprintHeld = false;
        }
    }
}
