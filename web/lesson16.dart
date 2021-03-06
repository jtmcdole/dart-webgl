// Copyright (c) 2013, John Thomas McDole.
/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
part of learn_gl;

class Lesson16 extends Lesson {
  bool get isLoaded => laptop != null;

  late GlProgram currentProgram;

  JsonObject? laptop;
  JsonObject? laptopScreen;

  double laptopAngle = 0.0;

  late Lesson13 lesson13;

  Lesson16() {
    lesson13 = Lesson13();

    // There is no HTML, so we're going to override these options.
    lesson13._lighting = InputElement()..checked = true;
    lesson13._aR = InputElement()..value = '0.2';
    lesson13._aG = InputElement()..value = '0.2';
    lesson13._aB = InputElement()..value = '0.2';
    lesson13._lpX = InputElement()..value = '0.0';
    lesson13._lpY = InputElement()..value = '0.0';
    lesson13._lpZ = InputElement()..value = '-5.0';
    lesson13._pR = InputElement()..value = '0.8';
    lesson13._pG = InputElement()..value = '0.8';
    lesson13._pB = InputElement()..value = '0.8';
    lesson13._perFragment = InputElement()..checked = true;
    lesson13._textures = InputElement()..checked = true;

    JsonObject.fromUrl('macbook.json').then((JsonObject obj) {
      print('macbook: $obj');
      laptop = obj;
    });

    final laptopScreenJson = '''
      {
        "vertexPositions": [
           0.580687, 0.659, 0.813106,
          -0.580687, 0.659, 0.813107,
           0.580687, 0.472, 0.113121,
          -0.580687, 0.472, 0.113121
        ],
        "vertexTextureCoords": [
          1.0, 1.0,
          0.0, 1.0,
          1.0, 0.0,
          0.0, 0.0
        ],
        "vertexNormals": [
          0.000000, -0.965926, 0.258819,
          0.000000, -0.965926, 0.258819,
          0.000000, -0.965926, 0.258819,
          0.000000, -0.965926, 0.258819
        ]
      }
    ''';
    laptopScreen = JsonObject(laptopScreenJson)..strip = true;

    final attributes = ['aVertexPosition', 'aVertexNormal', 'aTextureCoord'];
    final uniforms = [
      'uPMatrix',
      'uMVMatrix',
      'uNMatrix',
      'uUseTextures',
      'uMaterialAmbientColor',
      'uMaterialDiffuseColor',
      'uMaterialSpecularColor',
      'uMaterialShininess',
      'uMaterialEmissiveColor',
      'uPointLightingDiffuseColor',
      'uPointLightingLocation',
      'uPointLightingSpecularColor',
      'uShowSpecularHighlights',
      'uSampler',
      'uAmbientLightingColor'
    ];

    currentProgram = GlProgram(
      '''
          precision mediump float;
      
          varying vec2 vTextureCoord;
          varying vec3 vTransformedNormal;
          varying vec4 vPosition;
      
          uniform vec3 uMaterialAmbientColor;
          uniform vec3 uMaterialDiffuseColor;
          uniform vec3 uMaterialSpecularColor;
          uniform float uMaterialShininess;
          uniform vec3 uMaterialEmissiveColor;
      
          uniform bool uShowSpecularHighlights;
          uniform bool uUseTextures;
      
          uniform vec3 uAmbientLightingColor;
      
          uniform vec3 uPointLightingLocation;
          uniform vec3 uPointLightingDiffuseColor;
          uniform vec3 uPointLightingSpecularColor;
      
          uniform sampler2D uSampler;
      
      
          void main(void) {
              vec3 ambientLightWeighting = uAmbientLightingColor;
      
              vec3 lightDirection = normalize(uPointLightingLocation - vPosition.xyz);
              vec3 normal = normalize(vTransformedNormal);
      
              vec3 specularLightWeighting = vec3(0.0, 0.0, 0.0);
              if (uShowSpecularHighlights) {
                  vec3 eyeDirection = normalize(-vPosition.xyz);
                  vec3 reflectionDirection = reflect(-lightDirection, normal);
      
                  float specularLightBrightness = pow(max(dot(reflectionDirection, eyeDirection), 0.0), uMaterialShininess);
                  specularLightWeighting = uPointLightingSpecularColor * specularLightBrightness;
              }
      
              float diffuseLightBrightness = max(dot(normal, lightDirection), 0.0);
              vec3 diffuseLightWeighting = uPointLightingDiffuseColor * diffuseLightBrightness;
      
              vec3 materialAmbientColor = uMaterialAmbientColor;
              vec3 materialDiffuseColor = uMaterialDiffuseColor;
              vec3 materialSpecularColor = uMaterialSpecularColor;
              vec3 materialEmissiveColor = uMaterialEmissiveColor;
              float alpha = 1.0;
              if (uUseTextures) {
                  vec4 textureColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
                  materialAmbientColor = materialAmbientColor * textureColor.rgb;
                  materialDiffuseColor = materialDiffuseColor * textureColor.rgb;
                  materialEmissiveColor = materialEmissiveColor * textureColor.rgb;
                  alpha = textureColor.a;
              }
              gl_FragColor = vec4(
                  materialAmbientColor * ambientLightWeighting
                  + materialDiffuseColor * diffuseLightWeighting
                  + materialSpecularColor * specularLightWeighting
                  + materialEmissiveColor,
                  alpha
              );
          }
        ''',
      '''
          attribute vec3 aVertexPosition;
          attribute vec3 aVertexNormal;
          attribute vec2 aTextureCoord;
      
          uniform mat4 uMVMatrix;
          uniform mat4 uPMatrix;
          uniform mat3 uNMatrix;
      
          varying vec2 vTextureCoord;
          varying vec3 vTransformedNormal;
          varying vec4 vPosition;
      
          void main(void) {
              vPosition = uMVMatrix * vec4(aVertexPosition, 1.0);
              gl_Position = uPMatrix * vPosition;
              vTextureCoord = aTextureCoord;
              vTransformedNormal = uNMatrix * aVertexNormal;
          }
        ''',
      attributes,
      uniforms,
    );

    gl.useProgram(currentProgram.program);
    gl.enable(WebGL.DEPTH_TEST);

    rttFramebuffer = gl.createFramebuffer();
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, rttFramebuffer);

    rttTexture = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, rttTexture);
    gl.texParameteri(
      WebGL.TEXTURE_2D,
      WebGL.TEXTURE_MAG_FILTER,
      WebGL.LINEAR,
    );
    gl.texParameteri(
      WebGL.TEXTURE_2D,
      WebGL.TEXTURE_MIN_FILTER,
      WebGL.LINEAR_MIPMAP_NEAREST,
    );
    gl.generateMipmap(WebGL.TEXTURE_2D);

    gl.texImage2D(
      WebGL.TEXTURE_2D,
      0,
      WebGL.RGBA,
      rttWidth,
      rttHeight,
      0,
      WebGL.RGBA,
      WebGL.UNSIGNED_BYTE,
      null,
    );

    renderbuffer = gl.createRenderbuffer();
    gl.bindRenderbuffer(WebGL.RENDERBUFFER, renderbuffer);
    gl.renderbufferStorage(WebGL.RENDERBUFFER, WebGL.DEPTH_COMPONENT16, rttWidth, rttHeight);

    gl.framebufferTexture2D(
      WebGL.FRAMEBUFFER,
      WebGL.COLOR_ATTACHMENT0,
      WebGL.TEXTURE_2D,
      rttTexture,
      0,
    );
    gl.framebufferRenderbuffer(
      WebGL.FRAMEBUFFER,
      WebGL.DEPTH_ATTACHMENT,
      WebGL.RENDERBUFFER,
      renderbuffer,
    );

    gl.bindTexture(WebGL.TEXTURE_2D, null);
    gl.bindRenderbuffer(WebGL.RENDERBUFFER, null);
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);
  }

  late Framebuffer rttFramebuffer;
  late Texture rttTexture;
  late Renderbuffer renderbuffer;
  static const rttWidth = 512;
  static const rttHeight = 512;

  int? get aVertexPosition => currentProgram.attributes['aVertexPosition'];
  int? get aVertexNormal => currentProgram.attributes['aVertexNormal'];
  int? get aTextureCoord => currentProgram.attributes['aTextureCoord'];

  UniformLocation? get uShowSpecularHighlights => currentProgram.uniforms['uShowSpecularHighlights'];
  UniformLocation? get uMaterialShininess => currentProgram.uniforms['uMaterialShininess'];

  UniformLocation? get uPMatrix => currentProgram.uniforms['uPMatrix'];
  UniformLocation? get uMVMatrix => currentProgram.uniforms['uMVMatrix'];
  UniformLocation? get uNMatrix => currentProgram.uniforms['uNMatrix'];
  UniformLocation? get uSampler => currentProgram.uniforms['uSampler'];
  UniformLocation? get uUseTextures => currentProgram.uniforms['uUseTextures'];
  UniformLocation? get uUseLighting => currentProgram.uniforms['uUseLighting'];
  UniformLocation? get uAmbientColor => currentProgram.uniforms['uAmbientColor'];
  UniformLocation? get uPointLightingLocation => currentProgram.uniforms['uPointLightingLocation'];
  UniformLocation? get uPointLightingSpecularColor => currentProgram.uniforms['uPointLightingSpecularColor'];
  UniformLocation? get uPointLightingDiffuseColor => currentProgram.uniforms['uPointLightingDiffuseColor'];

  UniformLocation? get uAmbientLightingColor => currentProgram.uniforms['uAmbientLightingColor'];
  UniformLocation? get uMaterialAmbientColor => currentProgram.uniforms['uMaterialAmbientColor'];
  UniformLocation? get uMaterialDiffuseColor => currentProgram.uniforms['uMaterialDiffuseColor'];
  UniformLocation? get uMaterialSpecularColor => currentProgram.uniforms['uMaterialSpecularColor'];
  UniformLocation? get uMaterialEmissiveColor => currentProgram.uniforms['uMaterialEmissiveColor'];

  @override
  void drawScene(int viewWidth, int viewHeight, double aspect) {
    if (!isLoaded) return;

    // First: render lesson 13 to the render buffer!
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, rttFramebuffer);
    lesson13.drawScene(rttWidth, rttHeight, 1.66);

    // What ever was the output of that, copy it to our texture
    gl.bindTexture(WebGL.TEXTURE_2D, rttTexture);
    gl.generateMipmap(WebGL.TEXTURE_2D);
    gl.bindTexture(WebGL.TEXTURE_2D, null); // reset to default

    // Back to normal framebuffer rendering
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, null);

    // And use our current program.
    gl.useProgram(currentProgram.program);

    // Setup the viewport, pulling information from the element.
    gl.viewport(0, 0, viewWidth, viewHeight);

    // Clear!
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    mvPushMatrix();

    mvMatrix
      ..translate([0.0, -0.4, -2.2])
      ..rotateY(radians(laptopAngle))
      ..rotateX(radians(-90.0));

    /*
     * Draw the laptop first with the following parameters
     * -TODO(jtmcdole): better description :)
     */
    gl.uniform1i(uShowSpecularHighlights, 1);
    gl.uniform3f(uPointLightingLocation, -1.0, 2.0, -1.0);

    gl.uniform3f(uAmbientLightingColor, 0.2, 0.2, 0.2);
    gl.uniform3f(uPointLightingDiffuseColor, 0.8, 0.8, 0.8);
    gl.uniform3f(uPointLightingSpecularColor, 0.8, 0.8, 0.8);

    // The laptop body is quite shiny and has no texture.
    // It reflects lots of specular light
    gl.uniform3f(uMaterialAmbientColor, 1.0, 1.0, 1.0);
    gl.uniform3f(uMaterialDiffuseColor, 1.0, 1.0, 1.0);
    gl.uniform3f(uMaterialSpecularColor, 1.5, 1.5, 1.5);
    gl.uniform1f(uMaterialShininess, 5.0);
    gl.uniform3f(uMaterialEmissiveColor, 0.0, 0.0, 0.0);
    gl.uniform1i(uUseTextures, 0);

    laptop?.draw(vertex: aVertexPosition, normal: aVertexNormal, coord: aTextureCoord, setUniforms: setMatrixUniforms);

    /*
     * Now draw the laptop screen with different lighting parameters.
     */
    gl.uniform3f(uMaterialAmbientColor, 0.0, 0.0, 0.0);
    gl.uniform3f(uMaterialDiffuseColor, 0.0, 0.0, 0.0);
    gl.uniform3f(uMaterialSpecularColor, 0.5, 0.5, 0.5);
    gl.uniform1f(uMaterialShininess, 20.0);
    gl.uniform3f(uMaterialEmissiveColor, 1.5, 1.5, 1.5);
    gl.uniform1i(uUseTextures, 1);

    // Now re-use the rttTexture for the screen - bam!
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, rttTexture);
    gl.uniform1i(uSampler, 0);
    laptopScreen?.draw(
        vertex: aVertexPosition, normal: aVertexNormal, coord: aTextureCoord, setUniforms: setMatrixUniforms);

    mvPopMatrix();
  }

  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
    final normalMatrix = mvMatrix.toInverseMat3();
    normalMatrix!.transposeSelf();
    gl.uniformMatrix3fv(uNMatrix, false, normalMatrix.buf);
  }

  @override
  void animate(double now) {
    if (lastTime != 0) {
      final elapsed = now - lastTime;
      laptopAngle -= 0.005 * elapsed;
    }
    lastTime = now;
    lesson13.animate(now);
  }

  @override
  void handleKeys() {
    if (isActive(KeyCode.A)) {
      laptopAngle -= 1.0;
    }
    if (isActive(KeyCode.D)) {
      laptopAngle += 1.0;
    }
    lesson13.handleKeys();
  }
}
