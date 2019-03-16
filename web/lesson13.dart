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

/**
 * Handle custom shaders, animation, etc for Lesson 12 - Point Lighting.
 * In this lesson, we spin a sphere and a cube around a central axis with at its core is a
 * point of directional lighting.
 *
 * In the original lesson, the moon and box are tidal locked (always showing the same face),
 * lets play around with that.
 */
class Lesson13 extends Lesson {
  Cube cube;
  Sphere moon;

  GlProgram perVertexProgram;
  GlProgram perFragmentProgram;

  GlProgram currentProgram;

  Texture moonTexture, cubeTexture;
  bool get isLoaded => moonTexture != null && cubeTexture != null;

  Lesson13() {
    moon = new Sphere(lats: 30, lons: 30, radius: 1);
    cube = new Cube();

    var attributes = ['aVertexPosition', 'aVertexNormal', 'aTextureCoord'];
    var uniforms = [
      'uPMatrix',
      'uMVMatrix',
      'uNMatrix',
      'uSampler',
      'uUseTextures',
      'uUseLighting',
      'uAmbientColor',
      'uPointLightingLocation',
      'uPointLightingColor'
    ];

    perVertexProgram = new GlProgram(
        '''
        precision mediump float;
    
        varying vec2 vTextureCoord;
        varying vec3 vLightWeighting;
    
        uniform bool uUseTextures;
    
        uniform sampler2D uSampler;
    
        void main(void) {
            vec4 fragmentColor;
            if (uUseTextures) {
                fragmentColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
            } else {
                fragmentColor = vec4(1.0, 1.0, 1.0, 1.0);
            }
            gl_FragColor = vec4(fragmentColor.rgb * vLightWeighting, fragmentColor.a);
        }
      ''',
        '''
        attribute vec3 aVertexPosition;
        attribute vec3 aVertexNormal;
        attribute vec2 aTextureCoord;
    
        uniform mat4 uMVMatrix;
        uniform mat4 uPMatrix;
        uniform mat3 uNMatrix;
    
        uniform vec3 uAmbientColor;
    
        uniform vec3 uPointLightingLocation;
        uniform vec3 uPointLightingColor;
    
        uniform bool uUseLighting;
    
        varying vec2 vTextureCoord;
        varying vec3 vLightWeighting;
    
        void main(void) {
            vec4 mvPosition = uMVMatrix * vec4(aVertexPosition, 1.0);
            gl_Position = uPMatrix * mvPosition;
            vTextureCoord = aTextureCoord;
    
            if (!uUseLighting) {
                vLightWeighting = vec3(1.0, 1.0, 1.0);
            } else {
                vec3 lightDirection = normalize(uPointLightingLocation - mvPosition.xyz);
    
                vec3 transformedNormal = uNMatrix * aVertexNormal;
                float directionalLightWeighting = max(dot(transformedNormal, lightDirection), 0.0);
                vLightWeighting = uAmbientColor + uPointLightingColor * directionalLightWeighting;
            }
        }
      ''',
        attributes,
        uniforms);

    currentProgram = perFragmentProgram = new GlProgram(
        '''
          precision mediump float;
      
          varying vec2 vTextureCoord;
          varying vec3 vTransformedNormal;
          varying vec4 vPosition;
      
          uniform bool uUseLighting;
          uniform bool uUseTextures;
      
          uniform vec3 uAmbientColor;
      
          uniform vec3 uPointLightingLocation;
          uniform vec3 uPointLightingColor;
      
          uniform sampler2D uSampler;
      
      
          void main(void) {
              vec3 lightWeighting;
              if (!uUseLighting) {
                  lightWeighting = vec3(1.0, 1.0, 1.0);
              } else {
                  vec3 lightDirection = normalize(uPointLightingLocation - vPosition.xyz);
      
                  float directionalLightWeighting = max(dot(normalize(vTransformedNormal), lightDirection), 0.0);
                  lightWeighting = uAmbientColor + uPointLightingColor * directionalLightWeighting;
              }
      
              vec4 fragmentColor;
              if (uUseTextures) {
                  fragmentColor = texture2D(uSampler, vec2(vTextureCoord.s, vTextureCoord.t));
              } else {
                  fragmentColor = vec4(1.0, 1.0, 1.0, 1.0);
              }
              gl_FragColor = vec4(fragmentColor.rgb * lightWeighting, fragmentColor.a);
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
        uniforms);

    // Handle textures
    loadTexture("moon.bmp", handleMipMapTexture).then((t) => moonTexture = t);
    loadTexture("crate.gif", handleMipMapTexture).then((t) => cubeTexture = t);

    gl.enable(WebGL.DEPTH_TEST);
  }

  get aVertexPosition => currentProgram.attributes["aVertexPosition"];
  get aVertexNormal => currentProgram.attributes["aVertexNormal"];
  get aTextureCoord => currentProgram.attributes["aTextureCoord"];

  get uPMatrix => currentProgram.uniforms["uPMatrix"];
  get uMVMatrix => currentProgram.uniforms["uMVMatrix"];
  get uNMatrix => currentProgram.uniforms["uNMatrix"];
  get uSampler => currentProgram.uniforms["uSampler"];
  get uUseTextures => currentProgram.uniforms["uUseTextures"];
  get uUseLighting => currentProgram.uniforms["uUseLighting"];
  get uAmbientColor => currentProgram.uniforms["uAmbientColor"];
  get uPointLightingLocation =>
      currentProgram.uniforms["uPointLightingLocation"];
  get uPointLightingColor => currentProgram.uniforms["uPointLightingColor"];

  void drawScene(num viewWidth, num viewHeight, num aspect) {
    if (!isLoaded) return;

    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    gl.viewport(0, 0, viewWidth, viewHeight);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    bool perFragmentLighting = _perFragment.checked;
    if (perFragmentLighting) {
      currentProgram = perFragmentProgram;
    } else {
      currentProgram = perVertexProgram;
    }
    gl.useProgram(currentProgram.program);

    // One: setup lighting information
    bool lighting = _lighting.checked;
    gl.uniform1i(uUseLighting, lighting ? 1 : 0);
    if (lighting) {
      gl.uniform3f(uAmbientColor, double.parse(_aR.value),
          double.parse(_aG.value), double.parse(_aB.value));

      gl.uniform3f(uPointLightingLocation, double.parse(_lpX.value),
          double.parse(_lpY.value), double.parse(_lpZ.value));

      gl.uniform3f(uPointLightingColor, double.parse(_pR.value),
          double.parse(_pG.value), double.parse(_pB.value));
    }
    gl.uniform1i(uUseTextures, _textures.checked ? 1 : 0);

    mvPushMatrix();

    // Setup the scene -5.0 away and pitch up by 30 degrees
    mvMatrix
      ..translate([0.0, 0.0, -5.0])
      ..rotateX(radians(tilt));

    mvPushMatrix();
    // Rotate and move away from the scene
    mvMatrix
      ..rotateY(radians(moonAngle))
      ..translate([2.0, 0.0, 0.0]);
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, moonTexture);
    gl.uniform1i(uSampler, 0);
    moon.draw(
        vertex: aVertexPosition,
        normal: aVertexNormal,
        coord: aTextureCoord,
        setUniforms: setMatrixUniforms);
    mvPopMatrix();

    mvMatrix
      ..rotateY(radians(cubeAngle))
      ..translate([1.25, 0.0, 0.0]);
    gl.activeTexture(WebGL.TEXTURE0);
    gl.bindTexture(WebGL.TEXTURE_2D, cubeTexture);
    gl.uniform1i(uSampler, 0);
    cube.draw(
        vertex: aVertexPosition,
        normal: aVertexNormal,
        coord: aTextureCoord,
        setUniforms: setMatrixUniforms);
    mvPopMatrix();
  }

  double moonAngle = 180.0;
  double cubeAngle = 0.0;
  double tilt = 30.0;

  void setMatrixUniforms() {
    gl.uniformMatrix4fv(uPMatrix, false, pMatrix.buf);
    gl.uniformMatrix4fv(uMVMatrix, false, mvMatrix.buf);
    var normalMatrix = mvMatrix.toInverseMat3();
    normalMatrix.transposeSelf();
    gl.uniformMatrix3fv(uNMatrix, false, normalMatrix.buf);
  }

  void animate(num now) {
    if (lastTime != 0) {
      var elapsed = now - lastTime;
      moonAngle += 0.05 * elapsed;
      cubeAngle += 0.05 * elapsed;
    }
    lastTime = now;
  }

  void handleKeys() {
    handleDirection(
        up: () => tilt -= 1.0,
        down: () => tilt += 1.0,
        left: () {
          moonAngle -= 1.0;
          cubeAngle -= 1.0;
        },
        right: () {
          moonAngle += 1.0;
          cubeAngle += 1.0;
        });
  }

  InputElement _perFragment;
  InputElement _textures;

  // Lighting enabled / Ambient color
  InputElement _lighting, _aR, _aG, _aB;

  // Light position
  InputElement _lpX, _lpY, _lpZ;

  // Point color
  InputElement _pR, _pG, _pB;

  void initHtml(DivElement hook) {
    hook.setInnerHtml(
        """
    <input type="checkbox" id="lighting" checked /> Use lighting<br/>
    <input type="checkbox" id="per-fragment" checked /> Per-fragment lighting<br/>
    <input type="checkbox" id="textures" checked /> Use textures<br/>
    <br/>

    <h2>Point light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Location:</b>
            <td>X: <input type="text" id="lightPositionX" value="0.0" />
            <td>Y: <input type="text" id="lightPositionY" value="0.0" />
            <td>Z: <input type="text" id="lightPositionZ" value="-5.0" />
        </tr>
        <tr>
            <td><b>Colour:</b>
            <td>R: <input type="text" id="pointR" value="0.8" />
            <td>G: <input type="text" id="pointG" value="0.8" />
            <td>B: <input type="text" id="pointB" value="0.8" />
        </tr>
    </table>

    <h2>Ambient light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Colour:</b>
            <td>R: <input type="text" id="ambientR" value="0.2" />
            <td>G: <input type="text" id="ambientG" value="0.2" />
            <td>B: <input type="text" id="ambientB" value="0.2" />
        </tr>
    </table>


    <br/>

    Moon texture courtesy of <a href="http://maps.jpl.nasa.gov/">the Jet Propulsion Laboratory</a>.
    """,
        treeSanitizer: new NullTreeSanitizer());

    // Re-look up our dom elements
    _lighting = querySelector("#lighting");
    _aR = querySelector("#ambientR");
    _aG = querySelector("#ambientG");
    _aB = querySelector("#ambientB");

    _pR = querySelector("#pointR");
    _pG = querySelector("#pointG");
    _pB = querySelector("#pointB");

    _lpX = querySelector("#lightPositionX");
    _lpY = querySelector("#lightPositionY");
    _lpZ = querySelector("#lightPositionZ");

    _perFragment = querySelector("#per-fragment");
    _textures = querySelector("#textures");
  }
}
