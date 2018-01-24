//
//  LearnView.m
//  LearnOpenGLES
//
//  Created by lsy.
//

#import "LearnView.h"
#import <OpenGLES/ES3/gl.h>

@interface LearnView()

@property (nonatomic, strong) EAGLContext *myContext;
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
@property (nonatomic, assign) GLuint myColorRenderBuffer;
@property (nonatomic, assign) GLuint myColorFrameBuffer;
@property (nonatomic, assign) GLuint shaderProgram;
@property (nonatomic, assign) GLuint position;
@property (nonatomic, assign) GLuint inputTextureCoordinate;
@property (nonatomic, assign) GLuint inputTextureColor;
@property (nonatomic, assign) GLuint inputImageTexture;
@property (nonatomic, assign) GLuint inputImageTexture2;

@end

@implementation LearnView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)dealloc {
    [self destoryRenderAndFrameBuffer];
}

- (void)layoutSubviews {
    
    [self setupLayer];
    
    [self setupContext];
    
    [self destoryRenderAndFrameBuffer];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self setupViewPort];
    
    [self render];
    
}

- (void)setupLayer {
    self.myEagLayer = (CAEAGLLayer*) self.layer;
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.opaque = YES;
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}


- (void)setupContext {
    EAGLContext* context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set current OpenGL context");
    }
    self.myContext = context;
}

- (void)setupRenderBuffer {
    GLuint buffer;
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}


- (void)setupFrameBuffer {
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, self.myColorRenderBuffer);
}

- (void)setupViewPort {
    
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);
}

- (void)render {
    
    float vertices[] = {
//          位置              渐变颜色         纹理坐标
        -1.0f, 1.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,   // 右上
        1.0f, 1.0f,    0.0f, 1.0f, 0.0f,   1.0f, 0.0f,   // 右下
        1.0f, -1.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,   // 左下
        -1.0f, -1.0f,  1.0f, 1.0f, 0.0f,   0.0f, 1.0f    // 左上
    };
    
    unsigned int indices[] = {
        0, 1, 2, 0, 2, 3
    };
    
    GLuint VBO, EBO;
    glGenBuffers(1, &VBO);
    glGenBuffers(1, &EBO);
    
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    NSString *vertexShaderPath = [[NSBundle mainBundle] pathForResource:@"VertexShader" ofType:@"vsh"];
    NSString *fragmentShaderPath = [[NSBundle mainBundle] pathForResource:@"FragmentShader" ofType:@"fsh"];
    
    self.shaderProgram = [self loadVertexShaders:vertexShaderPath fragmentShaders:fragmentShaderPath];
    
    glLinkProgram(self.shaderProgram);
    glUseProgram(self.shaderProgram);
    
    self.position = glGetAttribLocation(self.shaderProgram, "position");
    glEnableVertexAttribArray(self.position);
    glVertexAttribPointer(self.position, 2, GL_FLOAT, GL_FALSE, 7 * sizeof(float), NULL);
    
    self.inputTextureColor = glGetAttribLocation(self.shaderProgram, "inputTextureColor");
    glEnableVertexAttribArray(self.inputTextureColor);
    glVertexAttribPointer(self.inputTextureColor, 3, GL_FLOAT, GL_FALSE, 7 * sizeof(float), (void *)(2 * sizeof(float)));
    
    self.inputTextureCoordinate = glGetAttribLocation(self.shaderProgram, "inputTextureCoordinate");
    glEnableVertexAttribArray(self.inputTextureCoordinate);
    glVertexAttribPointer(self.inputTextureCoordinate, 2, GL_FLOAT, GL_FALSE, 7 * sizeof(float), (void *)(5 * sizeof(float))); //

    self.inputImageTexture = glGetUniformLocation(self.shaderProgram, "inputImageTexture");
    glUniform1i(self.inputImageTexture, 0);
    
    self.inputImageTexture2 = glGetUniformLocation(self.shaderProgram, "inputImageTexture2");
    glUniform1i(self.inputImageTexture2, 1);
    
    UIImage *image = [UIImage imageNamed:@"boat"];

    CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider([image CGImage]));
    NSData *pixelNSData = (__bridge NSData *)pixelData;

    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); // 采用s轴重复
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); // 采用t轴重复
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // 线性的，就是一个点取周围9个点的平均值，如果超出
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // 同理，如果低于

    if (pixelNSData) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [pixelNSData bytes]);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    glBindTexture(GL_TEXTURE_2D, 0);

    UIImage *image2 = [UIImage imageNamed:@"wall"];
    CFDataRef pixelData2 = CGDataProviderCopyData(CGImageGetDataProvider([image2 CGImage]));
    NSData *pixelNSData2 = (__bridge NSData *)pixelData;
    
    GLuint texture2;
    glGenTextures(1, &texture2);
    glBindTexture(GL_TEXTURE_2D, texture2);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT); // 采用s轴重复
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT); // 采用t轴重复
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); // 线性的，就是一个点取周围9个点的平均值，如果超出
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR); // 同理，如果低于
    
    if (pixelData2) {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, image.size.width, image.size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, [pixelNSData2 bytes]);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    glBindTexture(GL_TEXTURE_2D, 0);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, texture);
    
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, texture2);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, 0); // 注意，我才发现这个坑，glDrawglDrawElements和drawArray都只能画出三角形，也就是说，支持三个点的输入，如果话方形，至少六个点！！
    
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)destoryRenderAndFrameBuffer {
    glDeleteFramebuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
    glDeleteRenderbuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
}

- (GLuint)loadVertexShaders:(NSString *)vertexShaderPath fragmentShaders:(NSString *)fragmentShaderPath {
    
    GLuint shaderProgram = glCreateProgram();
    
    GLuint vertexShader = [self compileShaderWithFilePath:vertexShaderPath shaderType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithFilePath:fragmentShaderPath shaderType:GL_FRAGMENT_SHADER];
    
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
    
    return shaderProgram;
}

- (GLuint)compileShaderWithFilePath:(NSString *)filePath shaderType:(GLenum)type {
    GLuint shader = glCreateShader(type);
    const GLchar *source = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (source == NULL) {
        NSLog(@"shader file is not exist");
        return 0;
    }
    glShaderSource(shader, 1, &source, NULL);
    glCompileShader(shader);
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[512];
        glGetShaderInfoLog(shader, 512, NULL, messages);
        NSString *errorMessage = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", errorMessage);
    }
    return shader;
}

- (void)checkGLError {
    GLenum glError = glGetError();
    if (glError != GL_NO_ERROR) {
        NSLog(@"GL error: 0x%x", glError);
    }
}

@end
