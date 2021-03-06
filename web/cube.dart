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

class Cube implements Renderable {
  late Buffer positionBuffer, normalBuffer, textureCoordBuffer, indexBuffer;

  Cube() {
    positionBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, positionBuffer);
    final vertices = [
      // Front face
      -1.0, -1.0, 1.0,
      1.0, -1.0, 1.0,
      1.0, 1.0, 1.0,
      -1.0, 1.0, 1.0,

      // Back face
      -1.0, -1.0, -1.0,
      -1.0, 1.0, -1.0,
      1.0, 1.0, -1.0,
      1.0, -1.0, -1.0,

      // Top face
      -1.0, 1.0, -1.0,
      -1.0, 1.0, 1.0,
      1.0, 1.0, 1.0,
      1.0, 1.0, -1.0,

      // Bottom face
      -1.0, -1.0, -1.0,
      1.0, -1.0, -1.0,
      1.0, -1.0, 1.0,
      -1.0, -1.0, 1.0,

      // Right face
      1.0, -1.0, -1.0,
      1.0, 1.0, -1.0,
      1.0, 1.0, 1.0,
      1.0, -1.0, 1.0,

      // Left face
      -1.0, -1.0, -1.0,
      -1.0, -1.0, 1.0,
      -1.0, 1.0, 1.0,
      -1.0, 1.0, -1.0
    ];
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      Float32List.fromList(vertices),
      WebGL.STATIC_DRAW,
    );

    normalBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, normalBuffer);
    final vertexNormals = [
      // Front face
      0.0, 0.0, 1.0,
      0.0, 0.0, 1.0,
      0.0, 0.0, 1.0,
      0.0, 0.0, 1.0,

      // Back face
      0.0, 0.0, -1.0,
      0.0, 0.0, -1.0,
      0.0, 0.0, -1.0,
      0.0, 0.0, -1.0,

      // Top face
      0.0, 1.0, 0.0,
      0.0, 1.0, 0.0,
      0.0, 1.0, 0.0,
      0.0, 1.0, 0.0,

      // Bottom face
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0,

      // Right face
      1.0, 0.0, 0.0,
      1.0, 0.0, 0.0,
      1.0, 0.0, 0.0,
      1.0, 0.0, 0.0,

      // Left face
      -1.0, 0.0, 0.0,
      -1.0, 0.0, 0.0,
      -1.0, 0.0, 0.0,
      -1.0, 0.0, 0.0,
    ];
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      Float32List.fromList(vertexNormals),
      WebGL.STATIC_DRAW,
    );

    textureCoordBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, textureCoordBuffer);
    final textureCoords = [
      // Front face
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,

      // Back face
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
      0.0, 0.0,

      // Top face
      0.0, 1.0,
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,

      // Bottom face
      1.0, 1.0,
      0.0, 1.0,
      0.0, 0.0,
      1.0, 0.0,

      // Right face
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
      0.0, 0.0,

      // Left face
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
    ];
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      Float32List.fromList(textureCoords),
      WebGL.STATIC_DRAW,
    );

    indexBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(
        WebGL.ELEMENT_ARRAY_BUFFER,
        Uint16List.fromList([
          0, 1, 2, 0, 2, 3, // Front face
          4, 5, 6, 4, 6, 7, // Back face
          8, 9, 10, 8, 10, 11, // Top face
          12, 13, 14, 12, 14, 15, // Bottom face
          16, 17, 18, 16, 18, 19, // Right face
          20, 21, 22, 20, 22, 23 // Left face
        ]),
        WebGL.STATIC_DRAW);
  }

  @override
  void draw({int? vertex, int? normal, int? coord, int? color, Function()? setUniforms}) {
    if (vertex != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, positionBuffer);
      gl.vertexAttribPointer(vertex, 3, WebGL.FLOAT, false, 0, 0);
    }

    if (normal != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, normalBuffer);
      gl.vertexAttribPointer(normal, 3, WebGL.FLOAT, false, 0, 0);
    }

    if (coord != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, textureCoordBuffer);
      gl.vertexAttribPointer(coord, 2, WebGL.FLOAT, false, 0, 0);
    }

    if (color != null) {
      gl.bindBuffer(WebGL.ARRAY_BUFFER, this.color.colorBuffer);
      gl.vertexAttribPointer(color, 4, WebGL.FLOAT, false, 0, 0);
    }

    if (setUniforms != null) setUniforms();
    gl.bindBuffer(WebGL.ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(WebGL.TRIANGLES, 36, WebGL.UNSIGNED_SHORT, 0);
  }

  late CubeColor color;
  void addColor(CubeColor color) {
    this.color = color;
  }
}

/// Holds a color [late Buffer] for our cube's element array
class CubeColor {
  late Buffer colorBuffer;

  CubeColor() {
    colorBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, colorBuffer);

    /// HARD CODED :'(
    final colors = <List<double>>[
      [1.0, 0.0, 0.0, 1.0], // Front face
      [1.0, 1.0, 0.0, 1.0], // Back face
      [0.0, 1.0, 0.0, 1.0], // Top face
      [1.0, 0.5, 0.5, 1.0], // Bottom face
      [1.0, 0.0, 1.0, 1.0], // Right face
      [0.0, 0.0, 1.0, 1.0] // Left face
    ];
    final unpackedColors = <double>[];
    for (var i in colors) {
      for (var j = 0; j < 4; j++) {
        unpackedColors.addAll(i);
      }
    }
    gl.bufferData(
      WebGL.ARRAY_BUFFER,
      Float32List.fromList(unpackedColors),
      WebGL.STATIC_DRAW,
    );
  }
}
