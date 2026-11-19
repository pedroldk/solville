#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uDayProgress;
uniform float uTime;
uniform float uRain;

out vec4 fragColor;

void main() {
  vec2 res = max(uResolution, vec2(1.0));
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / res;

  float p = clamp(uDayProgress, 0.0, 1.0);
  float rain = clamp(uRain, 0.0, 1.0);

  // Diagonal volumetric sunbeams streaming from top-left toward bottom-right
  float diag = uv.x * 0.85 - uv.y * 0.55;
  float beam1 = pow(0.5 + 0.5 * sin(diag * 11.0 + uTime * 0.14), 3.0);
  float beam2 = pow(0.5 + 0.5 * sin(diag * 19.0 - uTime * 0.09 + 1.4), 4.0);
  float rayMask = (beam1 * 0.65 + beam2 * 0.35)
    * (1.0 - smoothstep(0.15, 0.95, uv.y))
    * (1.0 - smoothstep(0.20, 0.98, uv.x));

  float sunStrength = (1.0 - smoothstep(0.74, 0.90, p)) * (1.0 - rain * 0.90);
  float goldenPeak = smoothstep(0.52, 0.72, p) * (1.0 - smoothstep(0.78, 0.92, p));

  vec3 rayColor = mix(vec3(1.0, 0.96, 0.82), vec3(1.0, 0.78, 0.45), goldenPeak);
  float rayAlpha = rayMask * sunStrength * (0.085 + 0.060 * goldenPeak);

  // Golden hour warm wash, twilight indigo grading, and cozy rainy mist veil
  float twilightFactor = smoothstep(0.72, 0.98, p) * (1.0 - rain * 0.35);
  vec3 tintRgb = vec3(0.0);
  float tintAlpha = 0.0;

  if (goldenPeak > 0.005) {
    float shimmer = 0.90 + 0.10 * sin(uTime * 0.9 + uv.x * 5.0);
    tintRgb += vec3(1.0, 0.74, 0.38) * (goldenPeak * 0.09 * shimmer * (1.0 - rain * 0.7));
    tintAlpha += goldenPeak * 0.09 * shimmer * (1.0 - rain * 0.7);
  }
  if (twilightFactor > 0.005) {
    tintRgb += vec3(0.12, 0.17, 0.42) * (twilightFactor * 0.18);
    tintAlpha += twilightFactor * 0.18;
  }
  if (rain > 0.005) {
    float mistGrad = mix(0.08, 0.16, smoothstep(0.2, 1.0, uv.y));
    tintRgb += vec3(0.38, 0.50, 0.59) * (rain * mistGrad);
    tintAlpha += rain * mistGrad;
  }

  // Ultra-subtle storybook framing vignette (kept very gentle to preserve bright cozy feel)
  vec2 centered = uv - 0.5;
  float edgeDist = dot(centered, centered);
  float vignette = smoothstep(0.24, 0.68, edgeDist) * (0.09 + twilightFactor * 0.09 + rain * 0.04);
  vec3 vignetteColor = mix(vec3(0.26, 0.18, 0.12), vec3(0.08, 0.10, 0.28), twilightFactor);

  vec3 finalRgb = rayColor * rayAlpha + tintRgb + vignetteColor * vignette;
  float finalAlpha = clamp(rayAlpha + tintAlpha + vignette, 0.0, 0.44);

  // Flutter FragmentShader expects premultiplied alpha output
  fragColor = vec4(clamp(finalRgb, 0.0, finalAlpha), finalAlpha);
}
