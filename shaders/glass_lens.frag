#version 460 core
#include <flutter/runtime_effect.glsl>

// Set by the engine to the size of the backdrop texture (the whole screen).
uniform vec2 uSize;
// Physical screen size, then the lens top-left and size in physical pixels.
uniform vec2 uScreen;
uniform vec2 uOrigin;
uniform vec2 uLens;
uniform float uLift;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 frag = FlutterFragCoord().xy;
  // Usually the texture is the whole screen and the lens sits at its screen
  // position. If the engine cropped the backdrop to roughly the lens bounds,
  // fall back to lens-local coordinates centred in the texture.
  bool cropped = uSize.x < 0.75 * uScreen.x && uSize.y < 0.75 * uScreen.y;
  vec2 k = cropped ? vec2(1.0) : uSize / max(uScreen, vec2(1.0));
  vec2 lens = uLens * k;
  vec2 origin = cropped ? 0.5 * (uSize - lens) : uOrigin * k;
  vec2 hl = 0.5 * lens;
  vec2 center = origin + hl;
  vec2 p = frag - center;
  // Capsule distance: 0 along the centre line, 1 at the rim.
  float hh = max(hl.y, 1.0);
  vec2 q = max(abs(p) - vec2(max(hl.x - hh, 0.0), 0.0), vec2(0.0));
  float r = clamp(length(q) / hh, 0.0, 1.0);
  // Clear magnified centre, rim pulled toward the middle.
  float bend = uLift * (0.18 * (1.0 - r * r) + 0.12 * smoothstep(0.6, 1.0, r));
  vec2 samplePx = center + p * (1.0 - bend);
  // Chromatic dispersion grows toward the rim.
  vec2 off = p * (0.014 * uLift * r * r);
  vec2 uv = samplePx / uSize;
  vec2 duv = off / uSize;
  float rr = texture(uTexture, uv + duv).r;
  vec4 mid = texture(uTexture, uv);
  float bb = texture(uTexture, uv - duv).b;
  // Soft specular sheen toward the top-left of the lens.
  vec2 local = (frag - origin) / max(lens, vec2(1.0));
  float sheen = smoothstep(0.9, 0.0, distance(local, vec2(0.28, 0.12))) * 0.12 * uLift;
  fragColor = vec4(vec3(rr, mid.g, bb) + vec3(sheen) * mid.a, mid.a);
}
