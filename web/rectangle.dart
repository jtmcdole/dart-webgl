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

class Rectangle implements Renderable {
  Buffer positionBuffer,
    normalBuffer,
    textureCoordBuffer,
    colorBuffer,
    indexBuffer;

  static const List<num> WHITE_COLOR = const [
    1.0, 1.0, 1.0, 1.0, // bottom left
    1.0, 1.0, 1.0, 1.0, // bottom right
    1.0, 1.0, 1.0, 1.0, // top right
    1.0, 1.0, 1.0, 1.0, // top left
  ];

  Rectangle(num width, num height, {num left: 0.0, num bottom: 0.0,
    Float32List vertexColors}) {
    positionBuffer = gl.createBuffer();
    normalBuffer = gl.createBuffer();
    textureCoordBuffer = gl.createBuffer();
    colorBuffer = gl.createBuffer();

    gl.bindBuffer(ARRAY_BUFFER, positionBuffer);
    var vertices = [
      left,  bottom,  0.0,  // bottom left
      left + width,  bottom,  0.0, // bottom right
      left + width,  bottom + height,  0.0, // top right
      left,  bottom + height,  0.0, // top left
    ];
    gl.bufferDataTyped(ARRAY_BUFFER, new Float32List.fromList(vertices), STATIC_DRAW);

    gl.bindBuffer(ARRAY_BUFFER, normalBuffer);
    var vertexNormals = [
      // Front face
      0.0,  0.0,  1.0,
      0.0,  0.0,  1.0,
      0.0,  0.0,  1.0,
      0.0,  0.0,  1.0,
    ];
    gl.bufferDataTyped(ARRAY_BUFFER, new Float32List.fromList(vertexNormals), STATIC_DRAW);

    gl.bindBuffer(ARRAY_BUFFER, textureCoordBuffer);
    var coords = [
      // Front face
      0.0, 0.0,
      1.0, 0.0,
      1.0, 1.0,
      0.0, 1.0,
    ];
    gl.bufferDataTyped(ARRAY_BUFFER, new Float32List.fromList(coords), STATIC_DRAW);

    // TODO: Come up with a better way to store color buffer vs texture buffer :)
    gl.bindBuffer(ARRAY_BUFFER, colorBuffer);
    var colors = WHITE_COLOR;
    if (vertexColors != null) {
      colors = new List<double>();
      if (vertexColors.length == 4) {
        colors.addAll(vertexColors);
        colors.addAll(vertexColors);
        colors.addAll(vertexColors);
        colors.addAll(vertexColors);
      } else if (vertexColors.length == 8) {
        colors.addAll(vertexColors.sublist(0, 4));
        colors.addAll(vertexColors.sublist(0, 4));
        colors.addAll(vertexColors.sublist(4, 8));
        colors.addAll(vertexColors.sublist(4, 8));
      }
    }
//    var colors = [
//      // Front face
//      1.0, 0.0, 0.0, 1.0, // bottom left
//      0.0, 1.0, 0.0, 1.0, // bottom right
//      0.0, 0.0, 1.0, 1.0, // top right
//      1.0, 1.0, 1.0, 1.0, // top left
//    ];
    gl.bufferDataTyped(ARRAY_BUFFER, new Float32List.fromList(colors), STATIC_DRAW);

    indexBuffer = gl.createBuffer();
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferDataTyped(ELEMENT_ARRAY_BUFFER, new Uint16List.fromList([
         0, 1, 2,      0, 2, 3,    // Front face
        ]), STATIC_DRAW);

  }

  void draw({int vertex, int normal, int coord, int color, setUniforms()}) {
    if (vertex != null) {
      gl.bindBuffer(ARRAY_BUFFER, positionBuffer);
      gl.vertexAttribPointer(vertex, 3, FLOAT, false, 0, 0);
    }

    if (normal != null) {
      gl.bindBuffer(ARRAY_BUFFER, normalBuffer);
      gl.vertexAttribPointer(normal, 3, FLOAT, false, 0, 0);
    }

    if (coord != null) {
      gl.bindBuffer(ARRAY_BUFFER, textureCoordBuffer);
      gl.vertexAttribPointer(coord, 2, FLOAT, false, 0, 0);
    }

    if (color != null) {
      gl.bindBuffer(ARRAY_BUFFER, colorBuffer);
      gl.vertexAttribPointer(color, 4, FLOAT, false, 0, 0);
    }

    if (setUniforms != null) setUniforms();
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.drawElements(TRIANGLES, 6, UNSIGNED_SHORT, 0);
  }
}
