// ignore_for_file: unnecessary_this
// Trimmed down matrix code - its best you use a well known library
// instead of this code.
part of learn_gl;

/// Thrown if you attempt to normalize a zero length vector.
class ZeroLengthVectorException implements Exception {
  ZeroLengthVectorException();
}

/// Thrown if you attempt to invert a singular matrix.  (A
/// singular matrix has no inverse.)
class SingularMatrixException implements Exception {
  SingularMatrixException();
}

/// 3 dimensional vector.
class Vector3 {
  Float32List buf;

  Vector3(double x, double y, double z) : buf = Float32List(3) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  Vector3.fromList(List<double> list) : buf = Float32List.fromList(list);

  double get x => buf[0];
  double get y => buf[1];
  double get z => buf[2];
  set x(double v) => buf[0] = v;
  set y(double v) => buf[1] = v;
  set z(double v) => buf[2] = v;

  double magnitude() => sqrt(x * x + y * y + z * z);

  Vector3 normalize() {
    final len = magnitude();
    if (len == 0.0) {
      throw ZeroLengthVectorException();
    }
    return Vector3(x / len, y / len, z / len);
  }

  Vector3 operator -() {
    return Vector3(-x, -y, -z);
  }

  Vector3 operator -(Vector3 other) {
    return Vector3(x - other.x, y - other.y, z - other.z);
  }

  Vector3 cross(Vector3 other) {
    final xResult = y * other.z - z * other.y;
    final yResult = z * other.x - x * other.z;
    final zResult = x * other.y - y * other.x;
    return Vector3(xResult, yResult, zResult);
  }

  Vector3 scale(double by) {
    x *= by;
    y *= by;
    z *= by;
    return this;
  }

  @override
  String toString() {
    return 'Vector3($x,$y,$z)';
  }
}

const double degrees2radians = pi / 180.0;

/// Convert [degrees] to radians.
double radians(double degrees) {
  return degrees * degrees2radians;
}

/// A 4x4 transformation matrix (for use with webgl)
///
/// We label the elements of the matrix as follows:
///
///     c+ 1 2 3 4 + buff offset + Happy mRowCol
///     r+_________|_____________|________________
///     1| 1 0 0 0 |  0  4  8 12 | m00 m01 m02 m03
///     2| 0 1 0 0 |  1  5  9 13 | m10 m11 m12 m13
///     3| 0 0 1 0 |  2  6 10 14 | m20 m21 m22 m23
///     4| 0 0 0 1 |  3  7 11 15 | m30 m31 m32 m33
///
/// These are stored in a 16 element [Float32List], in column major
/// order, so they are ordered like this:
///
/// [ m00,m10,m20,m30, m01,m11,m21,m31, m02,m12,m22,m32, m03,m13,m23,m33 ]
///   0   1   2   3    4   5   6   7    8   9   10  11   12  13  14  15
///
/// We use column major order because that is what WebGL APIs expect.
///
class Matrix4 {
  Float32List buf;

  /// Constructs a  Matrix4 with all entries initialized
  /// to zero.
  Matrix4() : buf = Float32List(16);

  /// Make a copy of another matrix.
  Matrix4.fromMatrix(Matrix4 other) : buf = Float32List.fromList(other.buf);

  Matrix4.fromBuffer(this.buf);

  /// returns the index into [buf] for a given
  /// row and column.
  static int rc(int row, int col) => row + col * 4;

  double get m00 => buf[rc(0, 0)];
  double get m01 => buf[rc(0, 1)];
  double get m02 => buf[rc(0, 2)];
  double get m03 => buf[rc(0, 3)];
  double get m10 => buf[rc(1, 0)];
  double get m11 => buf[rc(1, 1)];
  double get m12 => buf[rc(1, 2)];
  double get m13 => buf[rc(1, 3)];
  double get m20 => buf[rc(2, 0)];
  double get m21 => buf[rc(2, 1)];
  double get m22 => buf[rc(2, 2)];
  double get m23 => buf[rc(2, 3)];
  double get m30 => buf[rc(3, 0)];
  double get m31 => buf[rc(3, 1)];
  double get m32 => buf[rc(3, 2)];
  double get m33 => buf[rc(3, 3)];

  set m00(double m) {
    buf[rc(0, 0)] = m;
  }

  set m01(double m) {
    buf[rc(0, 1)] = m;
  }

  set m02(double m) {
    buf[rc(0, 2)] = m;
  }

  set m03(double m) {
    buf[rc(0, 3)] = m;
  }

  set m10(double m) {
    buf[rc(1, 0)] = m;
  }

  set m11(double m) {
    buf[rc(1, 1)] = m;
  }

  set m12(double m) {
    buf[rc(1, 2)] = m;
  }

  set m13(double m) {
    buf[rc(1, 3)] = m;
  }

  set m20(double m) {
    buf[rc(2, 0)] = m;
  }

  set m21(double m) {
    buf[rc(2, 1)] = m;
  }

  set m22(double m) {
    buf[rc(2, 2)] = m;
  }

  set m23(double m) {
    buf[rc(2, 3)] = m;
  }

  set m30(double m) {
    buf[rc(3, 0)] = m;
  }

  set m31(double m) {
    buf[rc(3, 1)] = m;
  }

  set m32(double m) {
    buf[rc(3, 2)] = m;
  }

  set m33(double m) {
    buf[rc(3, 3)] = m;
  }

  @override
  String toString() {
    final rows = <String>[];
    for (var row = 0; row < 4; row++) {
      final items = <String>[];
      for (var col = 0; col < 4; col++) {
        var v = buf[rc(row, col)];
        if (v.abs() < 1e-16) {
          v = 0.0;
        }
        String display;
        try {
          display = v.toStringAsPrecision(4);
        } catch (e) {
          // TODO - remove this once toStringAsPrecision is implemented in vm
          display = v.toString();
        }
        items.add(display);
      }
      rows.add("| ${items.join(", ")} |");
    }
    return "Matrix4:\n${rows.join('\n')}";
  }

  /// Cosntructs a  Matrix4 that represents the identity transformation
  /// (all the diagonal entries are 1, and everything else is zero).
  void identity() {
    for (var i = 0; i < 16; i++) {
      buf[i] = 0.0;
    }
    m00 = 1.0;
    m11 = 1.0;
    m22 = 1.0;
    m33 = 1.0;
  }

  /// Constructs a  Matrix4 that represents a rotation around an axis.
  ///
  /// [radians] to rotate
  /// [axis] direction of axis of rotation (must not be zero length)
  static Matrix4 rotation(double radians, Vector3 axis) {
    axis = axis.normalize();

    final x = axis.x;
    final y = axis.y;
    final z = axis.z;
    final s = sin(radians);
    final c = cos(radians);
    final t = 1 - c;

    final m = Matrix4();
    m.m00 = x * x * t + c;
    m.m10 = x * y * t + z * s;
    m.m20 = x * z * t - y * s;

    m.m01 = x * y * t - z * s;
    m.m11 = y * y * t + c;
    m.m21 = y * z * t + x * s;

    m.m02 = x * z * t + y * s;
    m.m12 = y * z * t - x * s;
    m.m22 = z * z * t + c;

    m.m33 = 1.0;
    return m;
  }

  /// Rotate this [radians] around X
  Matrix4 rotateX(double radians) {
    final c = cos(radians);
    final s = sin(radians);
    final t1 = buf[4] * c + buf[8] * s;
    final t2 = buf[5] * c + buf[9] * s;
    final t3 = buf[6] * c + buf[10] * s;
    final t4 = buf[7] * c + buf[11] * s;
    final t5 = buf[4] * -s + buf[8] * c;
    final t6 = buf[5] * -s + buf[9] * c;
    final t7 = buf[6] * -s + buf[10] * c;
    final t8 = buf[7] * -s + buf[11] * c;
    buf[4] = t1;
    buf[5] = t2;
    buf[6] = t3;
    buf[7] = t4;
    buf[8] = t5;
    buf[9] = t6;
    buf[10] = t7;
    buf[11] = t8;
    return this;
  }

  /// Rotate this matrix [radians] around Y
  Matrix4 rotateY(double radians) {
    final c = cos(radians);
    final s = sin(radians);
    final t1 = buf[0] * c + buf[8] * -s;
    final t2 = buf[1] * c + buf[9] * -s;
    final t3 = buf[2] * c + buf[10] * -s;
    final t4 = buf[3] * c + buf[11] * -s;
    final t5 = buf[0] * s + buf[8] * c;
    final t6 = buf[1] * s + buf[9] * c;
    final t7 = buf[2] * s + buf[10] * c;
    final t8 = buf[3] * s + buf[11] * c;
    buf[0] = t1;
    buf[1] = t2;
    buf[2] = t3;
    buf[3] = t4;
    buf[8] = t5;
    buf[9] = t6;
    buf[10] = t7;
    buf[11] = t8;
    return this;
  }

  /// Rotate this matrix [radians] around Z
  Matrix4 rotateZ(double radians) {
    final c = cos(radians);
    final s = sin(radians);
    final t1 = buf[0] * c + buf[4] * s;
    final t2 = buf[1] * c + buf[5] * s;
    final t3 = buf[2] * c + buf[6] * s;
    final t4 = buf[3] * c + buf[7] * s;
    final t5 = buf[0] * -s + buf[4] * c;
    final t6 = buf[1] * -s + buf[5] * c;
    final t7 = buf[2] * -s + buf[6] * c;
    final t8 = buf[3] * -s + buf[7] * c;
    buf[0] = t1;
    buf[1] = t2;
    buf[2] = t3;
    buf[3] = t4;
    buf[4] = t5;
    buf[5] = t6;
    buf[6] = t7;
    buf[7] = t8;
    return this;
  }

  /// Translates a matrix by the given vector
  ///
  /// [v] vector representing which direction to move and how much to move
  Matrix4 translate(List<double> v) {
    final tx = v[0];
    final ty = v[1];
    final tz = v[2];
    final tw = v.length == 4 ? v[3] : 1.0;

    buf[12] = buf[0] * tx + buf[4] * ty + buf[8] * tz + buf[12] * tw;
    buf[13] = buf[1] * tx + buf[5] * ty + buf[9] * tz + buf[13] * tw;
    buf[14] = buf[2] * tx + buf[6] * ty + buf[10] * tz + buf[14] * tw;
    buf[15] = buf[3] * tx + buf[7] * ty + buf[11] * tz + buf[15] * tw;
    return this;
  }

  /// returns the transpose of this matrix
  Matrix4 transpose() {
    final m = Matrix4();
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        m.buf[rc(col, row)] = this.buf[rc(row, col)];
      }
    }
    return m;
  }

  /// Returns result of multiplication of this matrix
  /// by another matrix.
  ///
  /// In this equation:
  ///
  /// C = A * B
  ///
  /// C is the result of multiplying A * B.
  /// A is this matrix
  /// B is another matrix
  ///
  Matrix4 operator *(Matrix4 matrixB) {
    final matrixC = Matrix4();
    final bufA = this.buf;
    final bufB = matrixB.buf;
    final bufC = matrixC.buf;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 4; col++) {
        for (var i = 0; i < 4; i++) {
          bufC[rc(row, col)] += bufA[rc(row, i)] * bufB[rc(i, col)];
        }
      }
    }
    return matrixC;
  }

  /// Makse a 4x4 matrix perspective projection matrix given a field of view and
  /// aspect ratio.
  ///
  /// [fovyDegrees] field of view (in degrees) of the y-axis
  /// [aspectRatio] width to height aspect ratio.
  /// [zNear] distance to the near clipping plane.
  /// [zFar] distance to the far clipping plane.
  ///
  static Matrix4 perspective(double fovyDegrees, double aspectRatio, double zNear, double zFar) {
    final height = tan(radians(fovyDegrees) * 0.5) * zNear.toDouble();
    final width = height * aspectRatio.toDouble();
    return frustum(-width, width, -height, height, zNear, zFar);
  }

  static Matrix4 frustum(left, right, bottom, top, near, far) {
    final dest = Matrix4();
    left = left.toDouble();
    right = right.toDouble();
    bottom = bottom.toDouble();
    top = top.toDouble();
    near = near.toDouble();
    far = far.toDouble();
    final two_near = 2.0 * near;
    final double right_minus_left = right - left;
    final double top_minus_bottom = top - bottom;
    final double far_minus_near = far - near;
    dest.m00 = two_near / right_minus_left;
    dest.m11 = two_near / top_minus_bottom;
    dest.m02 = (right + left) / right_minus_left;
    dest.m12 = (top + bottom) / top_minus_bottom;
    dest.m22 = -(far + near) / far_minus_near;
    dest.m32 = -1.0;
    dest.m23 = -(two_near * far) / far_minus_near;
    return dest;
  }

  /// Generates a orthogonal projection matrix with the given bounds
  ///
  /// @param {mat4} out mat4 frustum matrix will be written into
  /// @param {number} left Left bound of the frustum
  /// @param {number} right Right bound of the frustum
  /// @param {number} bottom Bottom bound of the frustum
  /// @param {number} top Top bound of the frustum
  /// @param {number} near Near bound of the frustum
  /// @param {number} far Far bound of the frustum
  /// @returns {mat4} out
  ///
  static Matrix4 ortho(left, right, bottom, top, near, far) {
    final out = Float32List(16);
    final lr = 1 / (left - right), bt = 1 / (bottom - top), nf = 1 / (near - far);
    out[0] = -2 * lr;
    out[1] = 0.0;
    out[2] = 0.0;
    out[3] = 0.0;
    out[4] = 0.0;
    out[5] = -2 * bt;
    out[6] = 0.0;
    out[7] = 0.0;
    out[8] = 0.0;
    out[9] = 0.0;
    out[10] = 2 * nf;
    out[11] = 0.0;
    out[12] = (left + right) * lr;
    out[13] = (top + bottom) * bt;
    out[14] = (far + near) * nf;
    out[15] = 1.0;
    return Matrix4.fromBuffer(out);
  }

  /// Returns the inverse of this matrix.
  Matrix4 inverse() {
    final a0 = m00 * m11 - m10 * m01;
    final a1 = m00 * m21 - m20 * m01;
    final a2 = m00 * m31 - m30 * m01;
    final a3 = m10 * m21 - m20 * m11;
    final a4 = m10 * m31 - m30 * m11;
    final a5 = m20 * m31 - m30 * m21;

    final b0 = m02 * m13 - m12 * m03;
    final b1 = m02 * m23 - m22 * m03;
    final b2 = m02 * m33 - m32 * m03;
    final b3 = m12 * m23 - m22 * m13;
    final b4 = m12 * m33 - m32 * m13;
    final b5 = m22 * m33 - m32 * m23;

    // compute determinant
    final det = a0 * b5 - a1 * b4 + a2 * b3 + a3 * b2 - a4 * b1 + a5 * b0;
    if (det == 0) {
      throw SingularMatrixException();
    }

    final m = Matrix4();
    m.m00 = (m11 * b5 - m21 * b4 + m31 * b3) / det;
    m.m10 = (-m10 * b5 + m20 * b4 - m30 * b3) / det;
    m.m20 = (m13 * a5 - m23 * a4 + m33 * a3) / det;
    m.m30 = (-m12 * a5 + m22 * a4 - m32 * a3) / det;

    m.m01 = (-m01 * b5 + m21 * b2 - m31 * b1) / det;
    m.m11 = (m00 * b5 - m20 * b2 + m30 * b1) / det;
    m.m21 = (-m03 * a5 + m23 * a2 - m33 * a1) / det;
    m.m31 = (m02 * a5 - m22 * a2 + m32 * a1) / det;

    m.m02 = (m01 * b4 - m11 * b2 + m31 * b0) / det;
    m.m12 = (-m00 * b4 + m10 * b2 - m30 * b0) / det;
    m.m22 = (m03 * a4 - m13 * a2 + m33 * a0) / det;
    m.m32 = (-m02 * a4 + m12 * a2 - m32 * a0) / det;

    m.m03 = (-m01 * b3 + m11 * b1 - m21 * b0) / det;
    m.m13 = (m00 * b3 - m10 * b1 + m20 * b0) / det;
    m.m23 = (-m03 * a3 + m13 * a1 - m23 * a0) / det;
    m.m33 = (m02 * a3 - m12 * a1 + m22 * a0) / det;

    return m;
  }

  /// mat4.toInverseMat3
  /// Calculates the inverse of the upper 3x3 elements of a mat4 and copies the
  /// result into a [Matrix3]. The resulting matrix is useful for calculating
  /// transformed normals.
  ///
  /// Returns:
  /// A  [Matrix3]
  ///
  Matrix3? toInverseMat3() {
    // Cache the matrix values (makes for huge speed increases!)
    final a00 = m00, a01 = m10, a02 = m20;
    final a10 = m01, a11 = m11, a12 = m21;
    final a20 = m02, a21 = m12, a22 = m22;

    final b01 = a22 * a11 - a12 * a21;
    final b11 = -a22 * a10 + a12 * a20;
    final b21 = a21 * a10 - a11 * a20;

    final d = a00 * b01 + a01 * b11 + a02 * b21;
    if (d == 0) {
      return null;
    }
    final id = 1 / d;

    final dest = Matrix3();

    dest.m00 = b01 * id;
    dest.m10 = (-a22 * a01 + a02 * a21) * id;
    dest.m20 = (a12 * a01 - a02 * a11) * id;
    dest.m01 = b11 * id;
    dest.m11 = (a22 * a00 - a02 * a20) * id;
    dest.m21 = (-a12 * a00 + a02 * a10) * id;
    dest.m02 = b21 * id;
    dest.m12 = (-a21 * a00 + a01 * a20) * id;
    dest.m22 = (a11 * a00 - a01 * a10) * id;

    return dest;
  }

  static const double GLMAT_EPSILON = 0.000001;
  Matrix4 rotate(double rad, List<double> axis) {
    // ignore: omit_local_variable_types
    double x = axis[0], y = axis[1], z = axis[2];
    var len = sqrt(x * x + y * y + z * z);
    if (len.abs() < GLMAT_EPSILON) throw 'length of normal vector <~ $GLMAT_EPSILON';
    if (len != 1) {
      len = 1 / len;
      x *= len;
      y *= len;
      z *= len;
    }
    final c = cos(rad);
    final s = sin(rad);
    final C = 1.0 - c;
    final m11 = x * x * C + c;
    final m12 = x * y * C - z * s;
    final m13 = x * z * C + y * s;
    final m21 = y * x * C + z * s;
    final m22 = y * y * C + c;
    final m23 = y * z * C - x * s;
    final m31 = z * x * C - y * s;
    final m32 = z * y * C + x * s;
    final m33 = z * z * C + c;
    final t1 = buf[0] * m11 + buf[4] * m21 + buf[8] * m31;
    final t2 = buf[1] * m11 + buf[5] * m21 + buf[9] * m31;
    final t3 = buf[2] * m11 + buf[6] * m21 + buf[10] * m31;
    final t4 = buf[3] * m11 + buf[7] * m21 + buf[11] * m31;
    final t5 = buf[0] * m12 + buf[4] * m22 + buf[8] * m32;
    final t6 = buf[1] * m12 + buf[5] * m22 + buf[9] * m32;
    final t7 = buf[2] * m12 + buf[6] * m22 + buf[10] * m32;
    final t8 = buf[3] * m12 + buf[7] * m22 + buf[11] * m32;
    final t9 = buf[0] * m13 + buf[4] * m23 + buf[8] * m33;
    final t10 = buf[1] * m13 + buf[5] * m23 + buf[9] * m33;
    final t11 = buf[2] * m13 + buf[6] * m23 + buf[10] * m33;
    final t12 = buf[3] * m13 + buf[7] * m23 + buf[11] * m33;
    buf[0] = t1;
    buf[1] = t2;
    buf[2] = t3;
    buf[3] = t4;
    buf[4] = t5;
    buf[5] = t6;
    buf[6] = t7;
    buf[7] = t8;
    buf[8] = t9;
    buf[9] = t10;
    buf[10] = t11;
    buf[11] = t12;
    return this;
  }
}

/// A 3x3 transformation matrix (for use with webgl)
///
/// We label the elements of the matrix as follows:
///
///     c+ 1 2 3 + buff off + Happy mRowCol
///     r+_______|__________|_______________
///     1| 1 0 0 |  0  3  6 | m00 m01 m02
///     2| 0 1 0 |  1  4  7 | m10 m11 m12
///     3| 0 0 1 |  2  5  8 | m20 m21 m22
///
/// These are stored in a 16 element [Float32List], in column major
/// order, so they are ordered like this:
///
/// [ m00,m10,m20, m01,m11,m21, m02,m12,m22]
///   0   1   2    3   4   5    6   7   8
///
/// We use column major order because that is what WebGL APIs expect.
///
class Matrix3 {
  Float32List buf;

  Matrix3() : buf = Float32List(9);
  Matrix3.fromMatrix(Matrix3 other) : buf = Float32List.fromList(other.buf);

  /// returns the index into [buf] for a given
  /// row and column.
  static int rc(int row, int col) => row + col * 3;

  double get m00 => buf[rc(0, 0)];
  double get m01 => buf[rc(0, 1)];
  double get m02 => buf[rc(0, 2)];
  double get m10 => buf[rc(1, 0)];
  double get m11 => buf[rc(1, 1)];
  double get m12 => buf[rc(1, 2)];
  double get m20 => buf[rc(2, 0)];
  double get m21 => buf[rc(2, 1)];
  double get m22 => buf[rc(2, 2)];

  set m00(double m) {
    buf[rc(0, 0)] = m;
  }

  set m01(double m) {
    buf[rc(0, 1)] = m;
  }

  set m02(double m) {
    buf[rc(0, 2)] = m;
  }

  set m10(double m) {
    buf[rc(1, 0)] = m;
  }

  set m11(double m) {
    buf[rc(1, 1)] = m;
  }

  set m12(double m) {
    buf[rc(1, 2)] = m;
  }

  set m20(double m) {
    buf[rc(2, 0)] = m;
  }

  set m21(double m) {
    buf[rc(2, 1)] = m;
  }

  set m22(double m) {
    buf[rc(2, 2)] = m;
  }

  @override
  String toString() {
    final rows = <String>[];
    for (var row = 0; row < 3; row++) {
      final items = <String>[];
      for (var col = 0; col < 3; col++) {
        var v = buf[rc(row, col)];
        if (v.abs() < 1e-16) {
          v = 0.0;
        }
        String display;
        try {
          display = v.toStringAsPrecision(4);
        } catch (e) {
          // TODO - remove this once toStringAsPrecision is implemented in vm
          display = v.toString();
        }
        items.add(display);
      }
      rows.add("| ${items.join(", ")} |");
    }
    return "Matrix3:\n${rows.join('\n')}";
  }

  /// Transposes a [Matrix3] (flips the values over the diagonal)
  Matrix3 transpose() {
    final dest = Matrix3();
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        dest.buf[rc(col, row)] = this.buf[rc(row, col)];
      }
    }
    return dest;
  }

  /// Transpose ourselves
  ///     m00 m01 m02    m00 m10 m20
  ///     m10 m11 m12 => m01 m11 m21
  ///     m20 m21 m22    m02 m12 m22
  void transposeSelf() {
    final a01 = m01, a02 = m02, a12 = m12;
    m01 = m10;
    m02 = m20;
    m10 = a01;
    m12 = m21;
    m20 = a02;
    m21 = a12;
  }
}
