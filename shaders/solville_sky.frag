#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uDayProgress;
uniform float uTime;
uniform float uRain;

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

void main() {
  vec2 res = max(uResolution, vec2(1.0));
  vec2 fragCoord = FlutterFragCoord().xy;
  vec2 uv = fragCoord / res;
  float minDim = min(res.x, res.y);

  float p = clamp(uDayProgress, 0.0, 1.0);
  float rain = clamp(uRain, 0.0, 1.0);

  // 4-phase sky palette: Dawn -> Mediterranean Midday -> Golden Sunset -> Indigo Twilight
  vec3 topMorning = vec3(0.18, 0.67, 0.96);
  vec3 midMorning = vec3(0.47, 0.84, 0.98);
  vec3 horMorning = vec3(1.00, 0.89, 0.72);

  vec3 topNoon = vec3(0.12, 0.57, 0.92);
  vec3 midNoon = vec3(0.40, 0.80, 0.98);
  vec3 horNoon = vec3(0.89, 0.97, 1.00);

  vec3 topSunset = vec3(0.24, 0.31, 0.68);
  vec3 midSunset = vec3(0.98, 0.56, 0.41);
  vec3 horSunset = vec3(1.00, 0.84, 0.52);

  vec3 topNight = vec3(0.08, 0.12, 0.34);
  vec3 midNight = vec3(0.19, 0.27, 0.58);
  vec3 horNight = vec3(0.45, 0.48, 0.76);

  vec3 cTop;
  vec3 cMid;
  vec3 cHor;

  if (p < 0.25) {
    float t = smoothstep(0.0, 0.25, p);
    cTop = mix(topMorning, topNoon, t);
    cMid = mix(midMorning, midNoon, t);
    cHor = mix(horMorning, horNoon, t);
  } else if (p < 0.60) {
    float t = smoothstep(0.25, 0.60, p);
    cTop = mix(topNoon, topSunset, t * 0.18);
    cMid = mix(midNoon, midSunset, t * 0.15);
    cHor = mix(horNoon, vec3(1.0, 0.95, 0.85), t);
  } else if (p < 0.82) {
    float t = smoothstep(0.60, 0.82, p);
    vec3 noonTailTop = mix(topNoon, topSunset, 0.18);
    vec3 noonTailMid = mix(midNoon, midSunset, 0.15);
    vec3 noonTailHor = vec3(1.0, 0.95, 0.85);
    cTop = mix(noonTailTop, topSunset, t);
    cMid = mix(noonTailMid, midSunset, t);
    cHor = mix(noonTailHor, horSunset, t);
  } else {
    float t = smoothstep(0.82, 1.0, p);
    cTop = mix(topSunset, topNight, t);
    cMid = mix(midSunset, midNight, t);
    cHor = mix(horSunset, horNight, t);
  }

  // Softly blend toward cozy misty slate during gentle rain
  vec3 rainTop = vec3(0.32, 0.43, 0.49);
  vec3 rainMid = vec3(0.47, 0.57, 0.63);
  vec3 rainHor = vec3(0.71, 0.78, 0.82);
  cTop = mix(cTop, rainTop, rain * 0.82);
  cMid = mix(cMid, rainMid, rain * 0.82);
  cHor = mix(cHor, rainHor, rain * 0.82);

  // Smooth vertical Rayleigh sky gradient
  float yMid = smoothstep(0.0, 0.56, uv.y);
  float yLow = smoothstep(0.50, 1.0, uv.y);
  vec3 sky = mix(cTop, cMid, yMid);
  sky = mix(sky, cHor, yLow);

  // Arcing sunlit Mediterranean Sun (sets cleanly before crescent moon rises)
  float sunVis = (1.0 - smoothstep(0.70, 0.81, p)) * (1.0 - rain * 0.85);
  if (sunVis > 0.005) {
    float sunArc = clamp(p / 0.82, 0.0, 1.0);
    vec2 sunPx = vec2(
      res.x * mix(0.18, 0.82, sunArc),
      res.y * (0.14 + 0.18 * pow((sunArc - 0.35) * 1.35, 2.0))
    );
    vec2 dSun = (fragCoord - sunPx) / minDim;
    float dist = length(dSun);

    // Wide warm Mie corona glow + compact glowing solar disc
    float coronaWide = exp(-dist * 3.2) * 0.28;
    float coronaInner = exp(-dist * 11.5) * 0.52;
    float disc = 1.0 - smoothstep(0.030, 0.038, dist);

    // Subtle rotating sunbeams around disc
    float angle = atan(dSun.y, dSun.x);
    float rays = 0.5 + 0.5 * sin(angle * 8.0 + uTime * 0.25);
    float rays2 = 0.5 + 0.5 * cos(angle * 5.0 - uTime * 0.18);
    float rayGlow = (rays * 0.6 + rays2 * 0.4) * exp(-dist * 4.8) * 0.14;

    vec3 sunColor = mix(vec3(1.0, 0.97, 0.80), vec3(1.0, 0.72, 0.38), smoothstep(0.55, 0.80, p));
    sky += sunColor * (coronaWide + rayGlow) * sunVis;
    sky = mix(sky, vec3(1.0, 0.98, 0.88), clamp((coronaInner + disc) * sunVis, 0.0, 1.0));
  }

  // Soft twinkling dusk stars & crescent moon rising after sunset
  float starVis = smoothstep(0.72, 0.92, p) * (1.0 - rain * 0.95);
  if (starVis > 0.01) {
    vec2 starGrid = (fragCoord / minDim) * 18.0;
    vec2 cellId = floor(starGrid);
    vec2 cellUv = fract(starGrid) - 0.5;
    float rnd = hash21(cellId);
    if (rnd > 0.86 && uv.y < 0.68) {
      vec2 offset = vec2(hash21(cellId + 1.3), hash21(cellId + 7.1)) - 0.5;
      float dStar = length(cellUv - offset * 0.55);
      float twinkle = 0.55 + 0.45 * sin(uTime * (1.8 + rnd * 2.5) + rnd * 20.0);
      float starMask = smoothstep(0.10, 0.015, dStar) * (1.0 - smoothstep(0.42, 0.68, uv.y));
      sky += vec3(1.0, 0.96, 0.84) * starMask * twinkle * starVis * 0.80;
    }
  }

  float moonVis = smoothstep(0.81, 0.94, p) * (1.0 - rain * 0.95);
  if (moonVis > 0.01) {
    vec2 moonPx = vec2(res.x * 0.78, res.y * 0.18);
    vec2 dMoon = (fragCoord - moonPx) / minDim;
    float mDist = length(dMoon);
    float mDisc = 1.0 - smoothstep(0.028, 0.034, mDist);
    float mCut = 1.0 - smoothstep(0.025, 0.032, length(dMoon - vec2(0.014, -0.008)));
    float crescent = clamp(mDisc - mCut, 0.0, 1.0);
    float mHalo = exp(-mDist * 8.5) * 0.28;
    sky += vec3(0.88, 0.92, 1.0) * (mHalo + crescent * 0.92) * moonVis;
  }

  // Soft distant atmospheric cloud-bank haze near horizon
  float waveA = sin(uv.x * 7.0 + uTime * 0.05) * 0.025;
  float waveB = cos(uv.x * 13.0 - uTime * 0.035) * 0.015;
  float hazeBand = smoothstep(0.62, 0.98, uv.y + waveA + waveB);
  vec3 hazeColor = mix(cHor, vec3(1.0, 0.98, 0.94), 0.35 * (1.0 - rain));
  hazeColor = mix(hazeColor, vec3(0.55, 0.62, 0.78), smoothstep(0.75, 0.96, p) * 0.55);
  sky = mix(sky, hazeColor, hazeBand * 0.42);

  fragColor = vec4(clamp(sky, 0.0, 1.0), 1.0);
}
