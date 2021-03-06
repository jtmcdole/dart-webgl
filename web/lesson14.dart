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

class Lesson14 extends Lesson {
  late GlProgram currentProgram;
  Texture? earthTexture, galvanizedTexture, moonTexture;
  late JsonObject? teapot;

  int texturesLoaded = 0;
  bool get isLoaded => teapot != null && texturesLoaded == 3;

  double teapotAngle = 180;
  double tilt = 23.4;

  Lesson14() {
    JsonObject.fromUrl('Teapot.json').then((JsonObject obj) {
      print('Teapot: $obj');
      teapot = obj;
    });

    final attributes = ['aVertexPosition', 'aVertexNormal', 'aTextureCoord'];
    final uniforms = [
      'uPMatrix',
      'uMVMatrix',
      'uNMatrix',
      'uSampler',
      'uUseTextures',
      'uUseLighting',
      'uAmbientColor',
      'uPointLightingLocation',
      'uPointLightingSpecularColor',
      'uPointLightingDiffuseColor',
      'uMaterialShininess',
      'uShowSpecularHighlights'
    ];

    currentProgram = GlProgram(
      '''
          precision mediump float;
          
          varying vec2 vTextureCoord;
          varying vec3 vTransformedNormal;
          varying vec4 vPosition;
          
          uniform float uMaterialShininess;
          
          uniform bool uShowSpecularHighlights;
          uniform bool uUseLighting;
          uniform bool uUseTextures;
          
          uniform vec3 uAmbientColor;
          
          uniform vec3 uPointLightingLocation;
          uniform vec3 uPointLightingSpecularColor;
          uniform vec3 uPointLightingDiffuseColor;
          
          uniform sampler2D uSampler;
          
          
          void main(void) {
              vec3 lightWeighting;
              if (!uUseLighting) {
                  lightWeighting = vec3(1.0, 1.0, 1.0);
              } else {
                  vec3 lightDirection = normalize(uPointLightingLocation - vPosition.xyz);
                  vec3 normal = normalize(vTransformedNormal);
          
                  float specularLightWeighting = 0.0;
                  if (uShowSpecularHighlights) {
                      vec3 eyeDirection = normalize(-vPosition.xyz);
                      vec3 reflectionDirection = reflect(-lightDirection, normal);
          
                      specularLightWeighting = pow(max(dot(reflectionDirection, eyeDirection), 0.0), uMaterialShininess);
                  }
          
                  float diffuseLightWeighting = max(dot(normal, lightDirection), 0.0);
                  lightWeighting = uAmbientColor
                      + uPointLightingSpecularColor * specularLightWeighting
                      + uPointLightingDiffuseColor * diffuseLightWeighting;
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
      uniforms,
    );

    gl.useProgram(currentProgram.program);

    // Handle textures
    loadTexture('earth.jpg', handleMipMapTexture).then((t) {
      earthTexture = t;
      texturesLoaded++;
    });
    loadTexture('moon.bmp', handleMipMapTexture).then((t) {
      moonTexture = t;
      texturesLoaded++;
    });
    loadTexture('galvanizedTexture.jpg', handleMipMapTexture).then((t) {
      galvanizedTexture = t;
      texturesLoaded++;
    });

    gl.enable(WebGL.DEPTH_TEST);
  }

  void handleTexture(Texture texture, ImageElement image) {
    gl.pixelStorei(WebGL.UNPACK_FLIP_Y_WEBGL, 1);
    gl.bindTexture(WebGL.TEXTURE_2D, texture);
    gl.texImage2D(
      WebGL.TEXTURE_2D,
      0,
      WebGL.RGBA,
      WebGL.RGBA,
      WebGL.UNSIGNED_BYTE,
      image,
    );
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
    gl.bindTexture(WebGL.TEXTURE_2D, null);
    texturesLoaded++;
    print('loaded ${image.src}');
  }

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

  @override
  void drawScene(int viewWidth, int viewHeight, double aspect) {
    if (!isLoaded) return;
    // Setup the viewport, pulling information from the element.
    gl.viewport(0, 0, viewWidth, viewHeight);

    // Clear!
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    gl.enable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.BLEND);

    pMatrix = Matrix4.perspective(45.0, aspect, 0.1, 100.0);

    final specularHighlights = _specular.checked!;
    gl.uniform1i(uShowSpecularHighlights, specularHighlights ? 1 : 0);
    final lighting = _lighting.checked!;
    gl.uniform1i(uUseLighting, lighting ? 1 : 0);
    if (lighting) {
      gl.uniform3f(uAmbientColor, double.parse(_aR.value!), double.parse(_aG.value!), double.parse(_aB.value!));

      gl.uniform3f(
          uPointLightingLocation, double.parse(_lpX.value!), double.parse(_lpY.value!), double.parse(_lpZ.value!));

      gl.uniform3f(
          uPointLightingSpecularColor, double.parse(_sR.value!), double.parse(_sG.value!), double.parse(_sB.value!));

      gl.uniform3f(
          uPointLightingDiffuseColor, double.parse(_dR.value!), double.parse(_dG.value!), double.parse(_dB.value!));
    }

    final texture = _texture.value;
    gl.uniform1i(uUseTextures, texture != 'none' ? 1 : 0);

    mvPushMatrix();

    mvMatrix
      ..translate([0.0, 0.0, -40.0])
      ..rotate(radians(tilt), [1, 0, -1])
      ..rotateY(radians(teapotAngle));

    gl.activeTexture(WebGL.TEXTURE0);
    if (texture == 'earth') {
      gl.bindTexture(WebGL.TEXTURE_2D, earthTexture);
    } else if (texture == 'galvanized') {
      gl.bindTexture(WebGL.TEXTURE_2D, galvanizedTexture);
    } else if (texture == 'moon') {
      gl.bindTexture(WebGL.TEXTURE_2D, moonTexture);
    }
    gl.uniform1i(uSampler, 0);

    gl.uniform1f(uMaterialShininess, double.parse(_shininess.value!));

    teapot?.draw(vertex: aVertexPosition, normal: aVertexNormal, coord: aTextureCoord, setUniforms: setMatrixUniforms);
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
      teapotAngle += 0.05 * elapsed;
    }
    lastTime = now;
  }

  @override
  void handleKeys() {
    handleDirection(
        up: () => tilt -= 1.0,
        down: () => tilt += 1.0,
        left: () => teapotAngle -= 1.0,
        right: () => teapotAngle += 1.0);
  }

  // Lighting enabled / Ambient color
  late InputElement _lighting, _aR, _aG, _aB;

  // Light position
  late InputElement _lpX, _lpY, _lpZ;

  // Difuse color
  late InputElement _dR, _dG, _dB;

  // Specular color
  late InputElement _specular;
  late InputElement _sR, _sG, _sB;

  late InputElement _shininess;
  late SelectElement _texture;

  @override
  void initHtml(DivElement hook) {
    hook.setInnerHtml(
      '''
    <input type="checkbox" id="specular" checked /> Show specular highlight<br/>
    <input type="checkbox" id="lighting" checked /> Use lighting<br/>

    Texture:
    <select id="texture">
        <option value="none">None</option>
        <option value="earth">Earth</option>
        <option selected value="galvanized">Galvanized</option>
        <option value="moon">Moon</option>
    </select>

    <h2>Material:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Shininess:</b>
            <td><input type="text" id="shininess" value="32.0" />
        </tr>
    </table>

    <h2>Point light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Location:</b>
            <td>X: <input type="text" id="lightPositionX" value="-10.0" />
            <td>Y: <input type="text" id="lightPositionY" value="4.0" />
            <td>Z: <input type="text" id="lightPositionZ" value="-20.0" />
        </tr>
        <tr>
            <td><b>Specular colour:</b>
            <td>R: <input type="text" id="specularR" value="5.0" />
            <td>G: <input type="text" id="specularG" value="5.0" />
            <td>B: <input type="text" id="specularB" value="5.0" />
        </tr>
        <tr>
            <td><b>Diffuse colour:</b>
            <td>R: <input type="text" id="diffuseR" value="0.8" />
            <td>G: <input type="text" id="diffuseG" value="0.8" />
            <td>B: <input type="text" id="diffuseB" value="0.8" />
        </tr>
    </table>

    <h2>Ambient light:</h2>

    <table style="border: 0; padding: 10px;">
        <tr>
            <td><b>Colour:</b>
            <td>R: <input type="text" id="ambientR" value="0.4" />
            <td>G: <input type="text" id="ambientG" value="0.4" />
            <td>B: <input type="text" id="ambientB" value="0.4" />
        </tr>
    </table>

    Earth texture courtesy of <a href="http://www.esa.int/esaEO/SEMGSY2IU7E_index_0.html">the European Space Agency/Envisat</a>.<br/>
    Galvanized texture courtesy of <a href="http://www.arroway-textures.com/">Arroway Textures</a>.<br/>
    Moon texture courtesy of <a href="http://maps.jpl.nasa.gov/">the Jet Propulsion Laboratory</a>.
    ''',
      treeSanitizer: NullTreeSanitizer(),
    );

    // Re-look up our dom elements
    _lighting = querySelector('#lighting') as InputElement;
    _aR = querySelector('#ambientR') as InputElement;
    _aG = querySelector('#ambientG') as InputElement;
    _aB = querySelector('#ambientB') as InputElement;

    _lpX = querySelector('#lightPositionX') as InputElement;
    _lpY = querySelector('#lightPositionY') as InputElement;
    _lpZ = querySelector('#lightPositionZ') as InputElement;

    _dR = querySelector('#diffuseR') as InputElement;
    _dG = querySelector('#diffuseG') as InputElement;
    _dB = querySelector('#diffuseB') as InputElement;

    _specular = querySelector('#specular') as InputElement;
    _sR = querySelector('#specularR') as InputElement;
    _sG = querySelector('#specularG') as InputElement;
    _sB = querySelector('#specularB') as InputElement;

    _shininess = querySelector('#shininess') as InputElement;
    _texture = querySelector('#texture') as SelectElement;
  }
}
