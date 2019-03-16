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

class Pyramid implements Renderable {
  Buffer positionBuffer, normalBuffer, textureCoordBuffer;
  Buffer colorBuffer;

  Pyramid() {
    positionBuffer = gl.createBuffer();
    normalBuffer = gl.createBuffer();
    textureCoordBuffer = gl.createBuffer();

    gl.bindBuffer(WebGL.ARRAY_BUFFER, positionBuffer);
    var vertices = [
      // Front face
      0.0, 1.0, 0.0,
      -1.0, -1.0, 1.0,
      1.0, -1.0, 1.0,

      // Right face
      0.0, 1.0, 0.0,
      1.0, -1.0, 1.0,
      1.0, -1.0, -1.0,

      // Back face
      0.0, 1.0, 0.0,
      1.0, -1.0, -1.0,
      -1.0, -1.0, -1.0,

      // Left face
      0.0, 1.0, 0.0,
      -1.0, -1.0, -1.0,
      -1.0, -1.0, 1.0,

      //  NOTE: Missing the bottom triangles :)
      -1.0, -1.0, -1.0,
      1.0, -1.0, -1.0,
      1.0, -1.0, 1.0,
      -1.0, -1.0, -1.0,
      1.0, -1.0, 1.0,
      -1.0, -1.0, 1.0,
    ];
    gl.bufferData(
        WebGL.ARRAY_BUFFER, new Float32List.fromList(vertices), WebGL.STATIC_DRAW);

    normalBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, normalBuffer);
    var vertexNormals = [
      // Front face
      0.0, 0.4472135901451111, 0.8944271802902222,
      0.0, 0.4472135901451111, 0.8944271802902222,
      0.0, 0.4472135901451111, 0.8944271802902222,

      // Right face
      0.8944271802902222, 0.4472135901451111, 0.0,
      0.8944271802902222, 0.4472135901451111, 0.0,
      0.8944271802902222, 0.4472135901451111, 0.0,

      // Back face
      0.0, 0.4472135901451111, -0.8944271802902222,
      0.0, 0.4472135901451111, -0.8944271802902222,
      0.0, 0.4472135901451111, -0.8944271802902222,

      // Left face
      -0.8944271802902222, 0.4472135901451111, 0.0,
      -0.8944271802902222, 0.4472135901451111, 0.0,
      -0.8944271802902222, 0.4472135901451111, 0.0,

      // Bottom face - non-triangle strip
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0,
      0.0, -1.0, 0.0
    ];
    gl.bufferData(
        WebGL.ARRAY_BUFFER, new Float32List.fromList(vertexNormals), WebGL.STATIC_DRAW);

    // TODO: Come up with a better way to store color buffer vs texture buffer :)
    colorBuffer = gl.createBuffer();
    gl.bindBuffer(WebGL.ARRAY_BUFFER, colorBuffer);
    var colors = [
      // Front face
      1.0, 0.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
      0.0, 0.0, 1.0, 1.0,

      // Right face
      1.0, 0.0, 0.0, 1.0,
      0.0, 0.0, 1.0, 1.0,
      0.0, 1.0, 0.0, 1.0,

      // Back face
      1.0, 0.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
      0.0, 0.0, 1.0, 1.0,

      // Left face
      1.0, 0.0, 0.0, 1.0,
      0.0, 0.0, 1.0, 1.0,
      0.0, 1.0, 0.0, 1.0,

      // Bottom face
      0.0, 1.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0,
      0.0, 1.0, 0.0, 1.0
    ];
    gl.bufferData(WebGL.ARRAY_BUFFER, new Float32List.fromList(colors), WebGL.STATIC_DRAW);

    // Normal discovery from a list triangles
    //    for (int i = 0; i < vertices.length; i += 9 ) {
    //      Vector3 p0 = new Vector3(vertices[i], vertices[i+1], vertices[i+2]),
    //          p1 = new Vector3(vertices[i+3], vertices[i+4], vertices[i+5]),
    //          p2 = new Vector3(vertices[i+6], vertices[i+7], vertices[i+8]);
    //
    //      Vector3 v0 = p1 - p0, v1 = p2 - p0;
    //      Vector3 normal = v0.cross(v1).normalize();
    //      print("normal = $normal");
    //    }
  }

  void draw({int vertex, int normal, int coord, int color, setUniforms()}) {
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
      gl.bindBuffer(WebGL.ARRAY_BUFFER, colorBuffer);
      gl.vertexAttribPointer(color, 4, WebGL.FLOAT, false, 0, 0);
    }

    if (setUniforms != null) setUniforms();
    gl.drawArrays(WebGL.TRIANGLES, 0, 18);
  }
}
