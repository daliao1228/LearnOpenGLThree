attribute vec4 position;
attribute vec4 inputTextureCoordinate;
attribute vec3 inputTextureColor;

varying vec2 textureCoordinate;
varying highp vec3 textureColor;

void main()
{
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
    textureColor = inputTextureColor;
}
