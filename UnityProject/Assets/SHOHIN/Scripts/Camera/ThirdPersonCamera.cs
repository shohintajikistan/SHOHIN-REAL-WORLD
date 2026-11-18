using UnityEngine;

namespace Shohin.Survival
{
    public sealed class ThirdPersonCamera : MonoBehaviour
    {
        public Transform target;
        public Vector3 pivotOffset = new Vector3(0f, 1.55f, 0f);
        public float distance = 5.4f;
        public float sensitivity = 0.14f;
        public float minPitch = -18f;
        public float maxPitch = 66f;
        public float followSharpness = 14f;
        float yaw;
        float pitch = 18f;
        Vector2 lookDelta;

        public void AddLookInput(Vector2 delta) => lookDelta += delta;

        void LateUpdate()
        {
            if (!target) return;
#if ENABLE_LEGACY_INPUT_MANAGER
            if (Input.GetMouseButton(1))
                lookDelta += new Vector2(Input.GetAxis("Mouse X"), Input.GetAxis("Mouse Y")) * 5f;
#endif
            yaw += lookDelta.x * sensitivity;
            pitch = Mathf.Clamp(pitch - lookDelta.y * sensitivity, minPitch, maxPitch);
            lookDelta = Vector2.zero;

            Quaternion orbit = Quaternion.Euler(pitch, yaw, 0f);
            Vector3 focus = target.position + pivotOffset;
            Vector3 desired = focus + orbit * new Vector3(0f, 0f, -distance);
            transform.position = Vector3.Lerp(transform.position, desired, followSharpness * Time.deltaTime);
            transform.rotation = Quaternion.Slerp(transform.rotation,
                Quaternion.LookRotation(focus - transform.position, Vector3.up), followSharpness * Time.deltaTime);
        }
    }
}
