varying highp vec2 textureCoordinate;
varying highp vec3 textureColor;

uniform sampler2D inputImageTexture;

void main()
{
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate) * vec4(textureColor, 1.0);
}
