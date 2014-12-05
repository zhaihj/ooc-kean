//
// Copyright (c) 2011-2014 Simon Mika <simon@mika.se>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

use ooc-math
use ooc-collections

import structs/LinkedList
import OpenGLES3Map, OpenGLES3/Lines

OverlayDrawer: class {
	linesShader: OpenGLES3MapLines
	pointsShader: OpenGLES3MapPoints
	init: func {
		this linesShader = OpenGLES3MapLines new()
		this pointsShader = OpenGLES3MapPoints new()
		pointsShader color = FloatPoint3D new(1.0f, 1.0f, 1.0f)
		pointsShader pointSize = 5.0f
	}
	__destroy__: func {
		this linesShader dispose()
		this pointsShader dispose()
	}
	drawLines: func (pointList: VectorList<FloatPoint2D>, transform: FloatTransform2D) {
		positions := pointList pointer as Float*
		this linesShader color = FloatPoint3D new(0.0f, 0.0f, 0.0f)
		this linesShader transform = transform
		this linesShader use()
		Lines draw(positions, pointList count, 2, 3.5f)
		this linesShader color = FloatPoint3D new(1.0f, 1.0f, 1.0f)
		this linesShader use()
		Lines draw(positions, pointList count, 2, 1.5f)
	}
	drawBox: func (box: IntBox2D, transform: FloatTransform2D) {
		positions: Float[10]
		positions[0] = box leftTop x as Float
		positions[1] = box leftTop y as Float
		positions[2] = box rightTop x as Float
		positions[3] = box rightTop y as Float
		positions[4] = box rightBottom x as Float
		positions[5] = box rightBottom y as Float
		positions[6] = box leftBottom x as Float
		positions[7] = box leftBottom y as Float
		positions[8] = box leftTop x as Float
		positions[9] = box leftTop y as Float
		this linesShader color = FloatPoint3D new(1.0f, 1.0f, 1.0f)
		this linesShader transform = transform
		this linesShader use()
		Lines draw(positions[0]&, 5, 2, 1.5f)
	}
	drawPoints: func (pointList: VectorList<FloatPoint2D>, transform: FloatTransform2D) {
		positions := pointList pointer
		this pointsShader use()
		this pointsShader transform = transform
		Points draw(positions, pointList count, 2)
	}
}