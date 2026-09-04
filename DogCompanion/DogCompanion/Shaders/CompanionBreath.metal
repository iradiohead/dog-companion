#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 uv [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

struct BreathUniforms {
    float time;
    float breathAmp;
    float swayAmp;
    float enabled;
    float breathFrequency;
    float swayFrequency;
    float pad0;
    float pad1;
};

static float mesh_smoothstep(float edge0, float edge1, float x) {
    float t = saturate((x - edge0) / (edge1 - edge0));
    return t * t * (3.0 - 2.0 * t);
}

static float mesh_band(float value, float a, float b, float c, float d) {
    return mesh_smoothstep(a, b, value) * (1.0 - mesh_smoothstep(c, d, value));
}

vertex VertexOut breath_vertex(VertexIn in [[stage_in]],
                               constant BreathUniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    float2 point = in.position;
    float2 uv = in.uv;

    float belly = mesh_band(uv.y, 0.42, 0.52, 0.72, 0.88)
                * mesh_band(uv.x, 0.22, 0.36, 0.64, 0.80);
    float tail = mesh_band(uv.y, 0.48, 0.62, 0.88, 1.0)
               * (mesh_band(uv.x, 0.0, 0.02, 0.18, 0.32)
                  + mesh_band(uv.x, 0.68, 0.82, 0.98, 1.0));
    tail = min(tail, 1.0);

    float breath = sin(uniforms.time * uniforms.breathFrequency) * uniforms.breathAmp * uniforms.enabled;
    float sway = sin(uniforms.time * uniforms.swayFrequency + 0.6) * uniforms.swayAmp * uniforms.enabled;

    point.y -= belly * breath;
    point.x += (uv.x - 0.5) * belly * breath * 0.85;
    point.x += tail * sway;

    out.position = float4(point, 0.0, 1.0);
    out.uv = uv;
    return out;
}

fragment float4 breath_fragment(VertexOut in [[stage_in]],
                                texture2d<float> colorTexture [[texture(0)]],
                                sampler colorSampler [[sampler(0)]]) {
    float4 color = colorTexture.sample(colorSampler, in.uv);
    color.rgb *= color.a;
    return color;
}
