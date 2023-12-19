////////////////////////////////////////
// Complementary Reimagined by EminGT with Euphoria Patches by isuewo and SpacEagle17 //
////////////////////////////////////////

//Common//
#include "/lib/common.glsl"

//////////Fragment Shader//////////Fragment Shader//////////Fragment Shader//////////
#ifdef FRAGMENT_SHADER

in vec2 texCoord;

flat in vec4 glColor;

#ifdef OVERWORLD
    flat in vec3 upVec, sunVec;
#endif

//Pipeline Constants//

//Common Variables//
#ifdef OVERWORLD
    float SdotU = dot(sunVec, upVec);
    float sunVisibility = clamp(SdotU + 0.0625, 0.0, 0.125) / 0.125;
    float sunVisibility2 = sunVisibility * sunVisibility;
#endif

//Common Functions//

//Includes//
#include "/lib/colors/lightAndAmbientColors.glsl"
#ifdef END
    #include "/lib/colors/skyColors.glsl"
#endif

#ifdef CAVE_FOG
    #include "/lib/atmospherics/fog/caveFactor.glsl"
#endif

#ifdef COLOR_CODED_PROGRAMS
    #include "/lib/misc/colorCodedPrograms.glsl"
#endif

//Program//
void main() {
    #ifdef OVERWORLD
        vec2 tSize = textureSize(tex, 0);
        vec4 color = texture2D(tex, texCoord);
        color.rgb *= glColor.rgb;

        vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
        vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
        viewPos /= viewPos.w;
        vec3 nViewPos = normalize(viewPos.xyz);

        float VdotS = dot(nViewPos, sunVec);
        float VdotU = dot(nViewPos, upVec);

        if (abs(tSize.y - 264.0) < 248.5) { //tSize.y must range from 16 to 512
            #if SUN_MOON_STYLE >= 2
                discard;
            #endif

            if (VdotS > 0.0) { // Sun
                float sunBrightness = 3.2;
                #ifdef SPOOKY
                    sunBrightness = 0.5;
                #endif
                color.rgb *= dot(color.rgb, color.rgb) * normalize(lightColor) * sunBrightness;
                color.rgb *= 0.25 + (0.75 - 0.25 * rainFactor) * sunVisibility2;
            } else { // Moon
                color.rgb *= smoothstep1(min1(length(color.rgb))) * 1.3;
                #ifdef SPOOKY
                    color.rgb = mix(color.rgb, GetLuminance(color.rgb) * vec3(1.0, 0.0, 0.0) * 1.5, getBloodMoon(moonPhase, sunVisibility));
                #endif
            }

            color.rgb *= GetHorizonFactor(VdotU);

            #ifdef CAVE_FOG
                color.rgb *= 1.0 - 0.75 * GetCaveFactor();
            #endif
        } else { // Custom Sky
            #if MC_VERSION >= 11300
                color.rgb *= color.rgb * smoothstep1(sqrt1(max0(VdotU)));
            #else
                discard;
                // Old mc custom skyboxes are weirdly broken, so we discard.
            #endif
        }

        if (isEyeInWater == 1) color.rgb *= 0.25;

        #if defined CLEAR_SKY_WHEN_RAINING || defined NO_RAIN_ABOVE_CLOUDS
            color.a *= mix(1.0, 1.0 - 0.8 * rainFactor, heightRelativeToCloud);
        #elif defined SUN_MOON_DURING_RAIN
            color.a *= 1.0 - 0.8 * rainFactor;
        #else
            color.a *= 1.0 - rainFactor;
        #endif
    #endif

    #ifdef NETHER
        vec4 color = vec4(0.0);
    #endif

    #ifdef END
        vec4 color = vec4(endSkyColor, 1.0);
    #endif

    #if RETRO_LOOK == 1
        color.rgb = GetLuminance(color.rgb) * vec3(RETRO_LOOK_R, RETRO_LOOK_G, RETRO_LOOK_B) * 0.3 * RETRO_LOOK_I;
    #elif RETRO_LOOK == 2
        color.rgb = mix(color.rgb, GetLuminance(color.rgb) * vec3(RETRO_LOOK_R, RETRO_LOOK_G, RETRO_LOOK_B) * 0.3 * RETRO_LOOK_I, nightVision);
    #endif

    #ifdef COLOR_CODED_PROGRAMS
        ColorCodeProgram(color);
    #endif

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
}

#endif

//////////Vertex Shader//////////Vertex Shader//////////Vertex Shader//////////
#ifdef VERTEX_SHADER

out vec2 texCoord;

flat out vec4 glColor;

#ifdef OVERWORLD
    flat out vec3 upVec, sunVec;
#endif

//Uniforms//

//Attributes//

//Common Variables//

//Common Functions//

//Includes//

//Program//
void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    #ifdef ATLAS_ROTATION
        texCoord += texCoord * float(hash33(mod(cameraPosition * 0.5, vec3(100.0))));
    #endif

    glColor = gl_Color;

    #ifdef OVERWORLD
        upVec = normalize(gbufferModelView[1].xyz);
        sunVec = GetSunVector();
    #endif
}

#endif
