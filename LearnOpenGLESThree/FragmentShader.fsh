varying highp vec2 textureCoordinate;
varying highp vec3 textureColor;

uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
    gl_FragColor = mix(texture2D(inputImageTexture, textureCoordinate), texture2D(inputImageTexture2, textureCoordinate), 0.2);
}
